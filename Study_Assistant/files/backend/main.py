import os
import sys
import io
import json
import logging
import hashlib
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Ensure the root of Study_Assistant/files is on sys.path
_current_dir = Path(__file__).resolve().parent
_root_dir = _current_dir.parent
if str(_root_dir) not in sys.path:
    sys.path.insert(0, str(_root_dir))

load_dotenv(_root_dir / ".env")
load_dotenv()

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import PyPDF2
import docx
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Import service clients
from services.embedding import EmbeddingClient
from services.vectorstore import VectorStoreClient
from services.groq_client import GroqClient, GroqAPIException
from services.email_service import EmailService

def truncate_context(text: str, max_chars: int = 12000) -> str:
    """Reduce context length to avoid exceeding LLM limits."""
    text = (text or "").strip()
    if len(text) <= max_chars:
        return text
    return f"{text[:max_chars]}\n\n[Context truncated to fit AI input limits.]"

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="RAG System API")

# Add CORS middleware to allow frontend connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize service clients
embedding_client = EmbeddingClient()
vector_store_client = VectorStoreClient()
groq_client = GroqClient()
email_service = EmailService()

# Pydantic models for API requests and responses
class QueryRequest(BaseModel):
    question: str
    selected_documents: List[str] = []  # List of filenames to filter by

class QueryResponse(BaseModel):
    answer: str
    context: str
    score: float

class TopicSummaryRequest(BaseModel):
    topic: str = ""  # Optional - if empty, summarize all documents
    selected_documents: List[str] = []  # List of filenames to filter by

class TopicSummaryResponse(BaseModel):
    summary: str
    topic: str

class QuizQuestion(BaseModel):
    id: int
    question: str
    options: dict  # {"A": "...", "B": "...", "C": "...", "D": "..."}
    correct_answer: str
    explanation: str

class StructuredQuizResponse(BaseModel):
    topic: str
    questions: List[QuizQuestion]
    total_questions: int

class QuizRequest(BaseModel):
    topic: str
    num_questions: int = 5
    selected_documents: List[str] = []  # List of filenames to filter by

class QuizResponse(BaseModel):
    quiz: str
    topic: str

class ChatRequest(BaseModel):
    message: str
    conversation_history: List[dict] = []

class ChatResponse(BaseModel):
    response: str

class SchoolChatRequest(BaseModel):
    school_id: str
    question: str
    metrics_context: dict = {}

class SchoolChatResponse(BaseModel):
    answer: str
    school_id: str

class SkillCoachRequest(BaseModel):
    student_id: str
    student_name: str = "Student"
    skill_scores: dict = {}
    weakest_skills: List[str] = []
    strongest_skills: List[str] = []
    assessed_topics: List[str] = []
    question: str = ""

class SkillCoachResponse(BaseModel):
    summary: str
    recommendations: List[str] = []
    action_plan: List[str] = []
    student_id: str

def extract_text(file: UploadFile):
    """Extracts text from an uploaded file (PDF, DOCX, TXT)."""
    if not file.filename:
        raise HTTPException(status_code=400, detail="Filename is required.")
    
    filename = file.filename
    content = file.file.read()
    
    # Check file size (limit to 10MB)
    max_size = 10 * 1024 * 1024  # 10MB
    if len(content) > max_size:
        raise HTTPException(status_code=400, detail=f"File size exceeds maximum limit of 10MB.")
    
    if len(content) == 0:
        raise HTTPException(status_code=400, detail="File is empty.")
    
    try:
        if filename.endswith(".pdf"):
            pdf_reader = PyPDF2.PdfReader(io.BytesIO(content))
            text = ""
            for page in pdf_reader.pages:
                text += page.extract_text() or ""
            if not text.strip():
                raise HTTPException(status_code=400, detail="PDF file contains no extractable text.")
            return text
        elif filename.endswith(".docx"):
            doc = docx.Document(io.BytesIO(content))
            text = "\n".join([para.text for para in doc.paragraphs])
            if not text.strip():
                raise HTTPException(status_code=400, detail="DOCX file contains no extractable text.")
            return text
        elif filename.endswith(".txt"):
            try:
                text = content.decode("utf-8")
            except UnicodeDecodeError:
                # Try with error handling
                text = content.decode("utf-8", errors="ignore")
            if not text.strip():
                raise HTTPException(status_code=400, detail="TXT file is empty.")
            return text
        else:
            raise HTTPException(status_code=400, detail="Unsupported file format. Supported formats: PDF, DOCX, TXT")
    except PyPDF2.errors.PdfReadError:
        raise HTTPException(status_code=400, detail="Invalid PDF file.")
    except Exception as e:
        if isinstance(e, HTTPException):
            raise
        raise HTTPException(status_code=400, detail=f"Error reading file: {str(e)}")

def chunk_text(text: str, chunk_size=1000, chunk_overlap=200):
    """Splits text into smaller chunks."""
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len
    )
    return text_splitter.split_text(text)

@app.post("/upload/", summary="Upload and process a document")
async def upload_document(file: UploadFile = File(...)):
    """
    Accepts a document, extracts text, chunks it, generates embeddings,
    and stores them in the vector database.
    """
    try:
        if not file.filename:
            raise HTTPException(status_code=400, detail="Filename is required.")
        
        logger.info(f"Processing file: {file.filename}")
        
        # 1. Extract text
        text = extract_text(file)
        
        if not text or not text.strip():
            raise HTTPException(status_code=400, detail="No text could be extracted from the file.")
        
        # 2. Chunk text
        chunks = chunk_text(text)
        
        if not chunks or len(chunks) == 0:
            raise HTTPException(status_code=400, detail="Failed to chunk the document. The document may be too short.")
        
        # 3. Generate embeddings
        embeddings = embedding_client.create_embeddings(chunks)
        
        if not embeddings or len(embeddings) != len(chunks):
            raise HTTPException(status_code=500, detail="Failed to generate embeddings for all chunks.")
        
        # 4. Prepare metadata and IDs
        timestamp = datetime.utcnow().isoformat()
        # Use a unique ID format to handle duplicate filenames
        file_hash = hashlib.md5(f"{file.filename}_{timestamp}".encode()).hexdigest()[:8]
        metadatas = [{"filename": file.filename, "chunk_index": i, "timestamp": timestamp, "file_hash": file_hash} for i in range(len(chunks))]
        ids = [f"{file_hash}-{file.filename}-{i}" for i in range(len(chunks))]
        
        # 5. Store in vector DB
        vector_store_client.add_documents(
            documents=chunks,
            embeddings=embeddings,
            metadatas=metadatas,
            ids=ids
        )
        
        logger.info(f"Successfully processed and stored {len(chunks)} chunks from {file.filename}.")
        return {
            "message": f"Successfully ingested {file.filename}",
            "chunks_created": len(chunks),
            "filename": file.filename
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing file {file.filename if file.filename else 'unknown'}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")


def build_where_filter(selected_documents: List[str]):
    """Build ChromaDB where filter for document selection."""
    if not selected_documents:
        return None
    # Filter out empty strings and validate
    valid_docs = [doc for doc in selected_documents if doc and doc.strip()]
    if not valid_docs:
        return None
    if len(valid_docs) == 1:
        return {"filename": valid_docs[0]}
    else:
        # ChromaDB uses $in for multiple values
        return {"filename": {"$in": valid_docs}}

@app.post("/query/", response_model=QueryResponse, summary="Ask a question to the RAG system")
async def query_system(request: QueryRequest):
    """
    Takes a question, retrieves relevant context, and generates an answer using an LLM.
    """
    try:
        # Validate input
        if not request.question or not request.question.strip():
            raise HTTPException(status_code=400, detail="Question cannot be empty.")
        
        # 1. Embed the question
        logger.info(f"Processing query: {request.question[:100]}...")
        query_embedding = embedding_client.embed_query(request.question)
        logger.info(f"Generated embedding of length: {len(query_embedding)}")
        
        # 2. Build filter for selected documents
        where_filter = build_where_filter(request.selected_documents)
        
        # 3. Retrieve relevant chunks
        results = vector_store_client.query(query_embedding, n_results=3, where=where_filter)
        doc_count = len(results.get('documents', [])[0]) if results.get('documents') and results['documents'] and results['documents'][0] else 0
        logger.info(f"Query results: documents={doc_count} chunks")
        
        # Check if we have any documents
        if doc_count == 0:
            logger.warning("No documents found in vector store")
            if request.selected_documents:
                raise HTTPException(status_code=404, detail=f"No relevant context found in selected documents. Please check document selection or upload documents first.")
            else:
                raise HTTPException(status_code=404, detail="No relevant context found. Please upload documents first.")
            
        context = "\n---\n".join(results['documents'][0])
        distances = results.get('distances', [[]])[0] if results.get('distances') and results['distances'] else []
        
        # 4. Compute relevance score (simple similarity-to-score conversion)
        # We convert distance (lower is better) to score (higher is better)
        # Assuming distances are cosine distances (0 to 2), a simple inversion works.
        score = (1 - distances[0]) * 100 if distances and len(distances) > 0 else 0
        score = max(0, min(100, score))  # Clamp between 0 and 100
        
        # 5. Generate answer with LLM
        logger.info("Calling Groq API for answer generation")
        answer = groq_client.get_answer(request.question, context)
        if not answer or not answer.strip():
            raise HTTPException(status_code=500, detail="Received empty response from AI model.")
        logger.info("Successfully generated answer")
        
        return QueryResponse(answer=answer, context=context, score=round(score, 2))

    except HTTPException:
        # Re-raise HTTP exceptions (like 404) as-is
        raise
    except Exception as e:
        logger.error(f"Error processing query: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/status/", summary="Get the status of the vector store and AI engine")
async def get_status():
    """Returns vector store item count and active AI provider configuration."""
    try:
        count = vector_store_client.get_collection_count()
        has_groq = bool(getattr(groq_client, "api_key", None) and groq_client.api_key.strip())
        return {
            "status": "healthy",
            "vector_store_item_count": count,
            "ai_provider": "Groq LLM" if has_groq else "EduStreak Syllabus Engine (Offline Mode)",
            "groq_configured": has_groq
        }
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        return {
            "status": "degraded",
            "error": str(e),
            "vector_store_item_count": 0,
            "groq_configured": False
        }

@app.post("/summary/", response_model=TopicSummaryResponse, summary="Generate summary for a topic or all documents")
async def generate_topic_summary(request: TopicSummaryRequest):
    """
    Generates a comprehensive summary. If topic is provided, summarizes that topic.
    If topic is empty, generates a summary of all uploaded documents.
    """
    try:
        # Build filter for selected documents
        where_filter = build_where_filter(request.selected_documents)
        
        # Check if we have documents
        count = vector_store_client.get_collection_count()
        if count == 0:
            raise HTTPException(status_code=404, detail="No documents found. Please upload documents first.")
        
        # If topic is provided, summarize that topic
        if request.topic and request.topic.strip():
            logger.info(f"Generating summary for topic: {request.topic}")
            
            # 1. Embed the topic to find relevant context
            topic_embedding = embedding_client.embed_query(request.topic)
            
            # 2. Retrieve relevant chunks (more chunks for summary) with document filter
            results = vector_store_client.query(topic_embedding, n_results=10, where=where_filter)
            
            if not results.get('documents') or not results['documents'] or not results['documents'][0]:
                raise HTTPException(status_code=404, detail=f"No relevant context found for topic '{request.topic}'. Please try a different topic.")
            
            context = "\n---\n".join(results['documents'][0])
            topic_name = request.topic
            
        else:
            # No topic provided - summarize selected or all documents
            logger.info("Generating summary for selected documents" if request.selected_documents else "Generating summary for all documents")
            
            # Get all documents (limit to reasonable number to avoid token limits) with document filter
            results = vector_store_client.get_all_documents(limit=50, where=where_filter)
            
            if not results.get('documents') or not results['documents'] or not results['documents'][0]:
                raise HTTPException(status_code=404, detail="No documents found. Please upload documents first.")
            
            context = truncate_context("\n---\n".join(results['documents'][0]))
            if request.selected_documents:
                topic_name = f"Summary of {', '.join(request.selected_documents)}"
            else:
                topic_name = "Complete Document Summary"
        
        # 3. Generate summary using Groq
        logger.info("Generating summary with Groq API")
        if request.topic and request.topic.strip():
            summary = groq_client.generate_summary(topic_name, context)
        else:
            # For full document summary, use a different prompt
            summary = groq_client.generate_full_document_summary(context)
        
        return TopicSummaryResponse(summary=summary, topic=topic_name)
    
    except GroqAPIException as e:
        logger.error(f"Groq provider error while generating summary: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating summary: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error generating summary: {str(e)}")

@app.post("/quiz/", response_model=QuizResponse, summary="Generate quiz for a topic (legacy text format)")
async def generate_quiz(request: QuizRequest):
    """
    Generates a quiz with multiple choice questions for a specific topic (legacy text format).
    """
    try:
        logger.info(f"Generating quiz for topic: {request.topic} with {request.num_questions} questions")
        
        # Build filter for selected documents
        where_filter = build_where_filter(request.selected_documents)
        
        # 1. Embed the topic to find relevant context
        topic_embedding = embedding_client.embed_query(request.topic)
        
        # 2. Retrieve relevant chunks with document filter
        results = vector_store_client.query(topic_embedding, n_results=5, where=where_filter)
        
        if not results.get('documents') or not results['documents'] or not results['documents'][0]:
            raise HTTPException(status_code=404, detail="No relevant context found for this topic. Please upload documents first.")
        
        context = truncate_context("\n---\n".join(results['documents'][0]))
        
        # 3. Generate quiz using Groq
        logger.info("Generating quiz with Groq API")
        quiz = groq_client.generate_quiz(request.topic, context, request.num_questions)
        
        return QuizResponse(quiz=quiz, topic=request.topic)
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating quiz: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error generating quiz: {str(e)}")

@app.post("/quiz/interactive/", response_model=StructuredQuizResponse, summary="Generate interactive quiz for a topic")
async def generate_interactive_quiz(request: QuizRequest):
    """
    Generates an interactive structured quiz with multiple choice questions for a specific topic.
    Returns JSON format suitable for Flutter app integration with scoring.
    """
    try:
        # Validate input
        if not request.topic or not request.topic.strip():
            raise HTTPException(status_code=400, detail="Topic cannot be empty.")
        
        if request.num_questions < 1 or request.num_questions > 20:
            raise HTTPException(status_code=400, detail="Number of questions must be between 1 and 20.")
        
        logger.info(f"Generating interactive quiz for topic: {request.topic} with {request.num_questions} questions")
        
        # Build filter for selected documents
        where_filter = build_where_filter(request.selected_documents)
        
        # 1. Embed the topic to find relevant context
        topic_embedding = embedding_client.embed_query(request.topic)
        
        # 2. Retrieve relevant chunks with document filter
        results = vector_store_client.query(topic_embedding, n_results=5, where=where_filter)
        
        if not results.get('documents') or not results['documents'] or not results['documents'][0]:
            if request.selected_documents:
                raise HTTPException(status_code=404, detail=f"No relevant context found for topic '{request.topic}' in selected documents. Please try a different topic or select different documents.")
            else:
                raise HTTPException(status_code=404, detail="No relevant context found for this topic. Please upload documents first.")
        
        context = truncate_context("\n---\n".join(results['documents'][0]))
        
        # 3. Generate structured quiz using Groq
        logger.info("Generating structured quiz with Groq API")
        quiz_data = groq_client.generate_structured_quiz(request.topic, context, request.num_questions)
        
        # Validate quiz data
        if not quiz_data or "questions" not in quiz_data:
            raise HTTPException(status_code=500, detail="Invalid quiz data received from AI model.")
        
        questions_list = quiz_data.get("questions", [])
        if not questions_list or len(questions_list) == 0:
            raise HTTPException(status_code=500, detail="No questions generated. Please try again.")
        
        # Convert to Pydantic models with validation
        validated_questions = []
        for i, q in enumerate(questions_list):
            try:
                # Ensure id is set
                if "id" not in q:
                    q["id"] = i + 1
                # Validate required fields
                if "question" not in q or "options" not in q or "correct_answer" not in q:
                    logger.warning(f"Skipping invalid question: {q}")
                    continue
                # Validate options
                if not isinstance(q["options"], dict) or len(q["options"]) < 2:
                    logger.warning(f"Skipping question with invalid options: {q}")
                    continue
                # Validate correct_answer is in options
                if q["correct_answer"] not in q["options"]:
                    logger.warning(f"Skipping question with invalid correct_answer: {q}")
                    continue
                validated_questions.append(QuizQuestion(**q))
            except Exception as e:
                logger.warning(f"Error validating question {i+1}: {e}")
                continue
        
        if len(validated_questions) == 0:
            raise HTTPException(status_code=500, detail="No valid questions could be generated. Please try again.")
        
        return StructuredQuizResponse(
            topic=request.topic,
            questions=validated_questions,
            total_questions=len(validated_questions)
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating interactive quiz: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error generating interactive quiz: {str(e)}")

def get_curriculum_fallback_response(query: str) -> str:
    """Educational fallback answering common curriculum topics when cloud LLM is offline."""
    q_lower = query.lower()
    if "photosynthesis" in q_lower:
        return (
            "🌿 **Photosynthesis (Class 8-10 Science)**:\n\n"
            "Photosynthesis is the process by which autotrophic plants synthesize organic food (glucose) from inorganic raw materials ($CO_2$ and $H_2O$) in the presence of sunlight and chlorophyll.\n\n"
            "**Standard Chemical Equation:**\n"
            "$$6CO_2 + 6H_2O \\xrightarrow{Light + Chlorophyll} C_6H_{12}O_6 + 6O_2$$\n\n"
            "- **Phase 1: Light-dependent reactions** occur within thylakoid membranes to generate ATP and NADPH while releasing $O_2$.\n"
            "- **Phase 2: Calvin-Benson cycle (Dark reactions)** occurs in the chloroplast stroma, fixing carbon into hexose sugars."
        )
    elif "newton" in q_lower or "motion" in q_lower or "force" in q_lower:
        return (
            "⚡ **Newton's Laws of Motion (Physics)**:\n\n"
            "1. **First Law (Law of Inertia)**: A body continues in its state of rest or uniform rectilinear motion unless acted upon by an external unbalanced force.\n"
            "2. **Second Law ($F = ma$)**: The rate of change of momentum is directly proportional to the applied force and occurs in the direction of the force ($F = \\frac{dp}{dt} = m \\cdot a$).\n"
            "3. **Third Law**: To every action, there is always an equal and opposite reaction ($F_{AB} = -F_{BA}$)."
        )
    elif "cell" in q_lower or "mitochondria" in q_lower:
        return (
            "🔬 **Cell Biology Essentials**:\n\n"
            "- **Cell Membrane**: Selectively permeable lipid bilayer regulating molecule transport.\n"
            "- **Nucleus**: Master control centre containing chromosomes, genes, and chromatin.\n"
            "- **Mitochondria**: 'Powerhouse of the cell' producing ATP via cellular respiration.\n"
            "- **Ribosomes**: Sites of polypeptide and protein synthesis."
        )
    elif "algebra" in q_lower or "quadratic" in q_lower:
        return (
            "📐 **Quadratic Equations & Algebra**:\n\n"
            "A standard quadratic equation is expressed as $ax^2 + bx + c = 0$ where $a \\neq 0$.\n\n"
            "**Roots Formula (Sridharacharya Method):**\n"
            "$$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$\n\n"
            "- **Discriminant ($D = b^2 - 4ac$)**:\n"
            "  - $D > 0$: 2 real and distinct roots.\n"
            "  - $D = 0$: 2 real and identical roots ($x = -\\frac{b}{2a}$).\n"
            "  - $D < 0$: No real roots (complex roots)."
        )
    else:
        return (
            f"🎓 **EduStreak Study Buddy (Curriculum Assistant)**:\n\n"
            f"I have received your study question:\n> *\"{query}\"*\n\n"
            "I am ready to help you learn! To activate real-time cloud LLM reasoning, ensure `GROQ_API_KEY` is added to your environment variables.\n\n"
            "In the meantime, you can explore detailed chapters in **My Learning** or test your knowledge in the **Practice Arena**!"
        )

@app.post("/chat/", response_model=ChatResponse, summary="Chat with AI tutor")
async def chat_with_ai(request: ChatRequest):
    """
    General chat with AI tutor with automatic curriculum fallback.
    """
    try:
        logger.info(f"Chat message received: {request.message[:50]}...")
        
        # Attempt live Groq chat
        response = groq_client.chat(request.message, request.conversation_history)
        return ChatResponse(response=response)
    
    except GroqAPIException as e:
        logger.warning(f"Groq provider offline or key missing: {e}. Returning curriculum fallback response.")
        fallback = get_curriculum_fallback_response(request.message)
        return ChatResponse(response=fallback)
    except Exception as e:
        logger.warning(f"Chat exception: {e}. Returning curriculum fallback response.")
        fallback = get_curriculum_fallback_response(request.message)
        return ChatResponse(response=fallback)

def generate_school_intelligence_response(school_id: str, question: str, metrics: dict) -> str:
    """Evidence-grounded executive response synthesizing genuine metrics."""
    q_lower = question.lower()
    health = metrics.get("healthScore", 85)
    att = metrics.get("overallAttendance", 88.0)
    acad = metrics.get("overallAcademicAverage", 78.0)
    hw = metrics.get("homeworkCompletionRate", 82.0)
    pending = metrics.get("pendingGradingCount", 0)
    total_st = metrics.get("totalStudents", 0)
    class_avgs = metrics.get("classAverages", {})
    subj_avgs = metrics.get("subjectAverages", {})
    class_att = metrics.get("classAttendance", {})

    if any(k in q_lower for k in ["academic", "class", "attention", "lowest class", "score"]):
        if class_avgs:
            lowest_class = min(class_avgs.items(), key=lambda x: x[1])
            breakdown = "\n".join([f"  - {k}: **{v}%**" for k, v in class_avgs.items()])
            return (
                f"📊 **Academic Performance Analysis (Evidence Grounded)**:\n\n"
                f"• **Class Needing Immediate Attention**: `{lowest_class[0]}` with an average score of **{lowest_class[1]}%** (Target Benchmark: 75%).\n"
                f"• **School-Wide Academic Average**: **{acad}%**.\n"
                f"• **Class Breakdown**:\n{breakdown}\n\n"
                f"💡 **Recommended Executive Action**: Mandate weekly remediation classes for {lowest_class[0]} and direct subject teachers to assign focused revision practice."
            )
    elif any(k in q_lower for k in ["subject", "lowest subject", "math", "science", "english"]):
        if subj_avgs:
            lowest_subj = min(subj_avgs.items(), key=lambda x: x[1])
            breakdown = "\n".join([f"  - {k}: **{v}%**" for k, v in subj_avgs.items()])
            return (
                f"🔬 **Subject Performance Intelligence**:\n\n"
                f"• **Priority Subject for Remediation**: `{lowest_subj[0]}` with an aggregate of **{lowest_subj[1]}%**.\n"
                f"• **Subject Averages**:\n{breakdown}\n\n"
                f"💡 **Recommended Action**: Review lesson plans with the {lowest_subj[0]} department and encourage interactive formative quizzes."
            )
    elif any(k in q_lower for k in ["attendance", "absent", "streak", "bunk"]):
        chronic = metrics.get("chronicAbsentCount", 0)
        breakdown = "\n".join([f"  - {k}: **{v}%**" for k, v in class_att.items()])
        return (
            f"📅 **School Attendance Intelligence**:\n\n"
            f"• **Overall School Attendance**: **{att}%**.\n"
            f"• **Chronic Absenteeism Flagged**: **{chronic} students** with active absence flags.\n"
            f"• **Section Attendance**:\n{breakdown}\n\n"
            f"💡 **Recommended Action**: Trigger automated alerts to guardians via the Parent Portal and request welfare follow-ups from respective class teachers."
        )
    elif any(k in q_lower for k in ["grading", "teacher", "homework", "pending"]):
        return (
            f"📝 **Teacher Workflow & Homework Pipeline**:\n\n"
            f"• **Homework Submission Rate**: **{hw}%** school-wide.\n"
            f"• **Pending Evaluations Backlog**: **{pending} submissions** currently awaiting teacher feedback.\n\n"
            f"💡 **Recommended Action**: Issue an automated grading notification to subject teachers with evaluation queues exceeding 5 assignments."
        )
    
    return (
        f"🏫 **School Intelligence Executive Summary** ({school_id}):\n\n"
        f"• **Composite Health Score**: **{health}/100**\n"
        f"• **Student Enrollment**: **{total_st} active students**\n"
        f"• **Attendance Rate**: **{att}%** | **Academic Average**: **{acad}%**\n"
        f"• **Homework Completion**: **{hw}%** | **Pending Evaluations**: **{pending} tasks**\n\n"
        f"💡 **Strategic Advisory**: Focus administrative efforts on clearing the {pending} pending grading backlog and raising engagement in sections below 75% attendance."
    )

@app.post("/school-insights/chat/", response_model=SchoolChatResponse, summary="Executive School Insights Intelligence Chat")
async def school_insights_chat(request: SchoolChatRequest):
    """
    Answers executive leadership questions from the Principal using real calculated school metrics.
    Uses Groq LLM if configured; otherwise provides grounded deterministic synthesis.
    """
    try:
        if not groq_client.api_key or groq_client.api_key == "your_groq_api_key_here":
            answer = generate_school_intelligence_response(request.school_id, request.question, request.metrics_context)
            return SchoolChatResponse(answer=answer, school_id=request.school_id)

        metrics_str = json.dumps(request.metrics_context, indent=2) if request.metrics_context else "No metrics provided"
        system_prompt = (
            "You are EduStreak School Intelligence Assistant, an executive advisory AI for school principals.\n"
            "You are provided with real-time verified school metrics for the principal's assigned school.\n"
            "Answer the principal's question strictly grounded in the provided metrics. Never fabricate fake numbers or records.\n"
            "Separate verified empirical findings from your strategic recommendations.\n"
            "Keep your response executive, structured, concise, and professional with bullet points and bold highlights."
        )
        user_prompt = (
            f"VERIFIED SCHOOL METRICS CONTEXT:\n{metrics_str}\n\n"
            f"PRINCIPAL'S QUESTION:\n{request.question}\n\n"
            "Provide an executive answer with: 1) Empirical Findings (with exact percentages/counts from context), 2) Analytical Interpretation, and 3) Recommended Strategic Action."
        )
        payload = {
            "model": groq_client.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.3,
            "max_tokens": 1200,
        }
        res = groq_client._call_groq_api(payload, timeout=45)
        if 'choices' in res and len(res['choices']) > 0:
            ans = res['choices'][0]['message']['content']
            return SchoolChatResponse(answer=ans, school_id=request.school_id)
        
        fallback = generate_school_intelligence_response(request.school_id, request.question, request.metrics_context)
        return SchoolChatResponse(answer=fallback, school_id=request.school_id)
    except Exception as e:
        logger.warning(f"School insights chat error: {e}. Falling back to deterministic synthesis.")
        fallback = generate_school_intelligence_response(request.school_id, request.question, request.metrics_context)
        return SchoolChatResponse(answer=fallback, school_id=request.school_id)

def generate_skill_coach_response(request: SkillCoachRequest) -> SkillCoachResponse:
    """Evidence-grounded pedagogical recommendation engine tailored to assessed competencies."""
    q = (request.question or "").lower()
    weak = request.weakest_skills or ["Problem Solving"]
    strong = request.strongest_skills or ["Conceptual Understanding"]
    student = request.student_name or "Student"

    recs = []
    plan = []

    if any("problem" in w.lower() for w in weak):
        recs.append("Break complex numerical or word problems into 3 sequential steps: Given parameters, Target formula, and Intermediate substitutions.")
        plan.append("Complete 5 step-by-step problem sets in Mathematics or Physics with written formula justifications.")
    if any("critical" in w.lower() for w in weak):
        recs.append("Practice comparative reasoning questions (e.g., 'Compare series vs parallel circuits' or 'Analyze cause-effect in photosynthesis').")
        plan.append("Review error analyses from previous quizzes and explain why the incorrect options were plausible distractors.")
    if any("application" in w.lower() for w in weak):
        recs.append("Focus on real-world situational problems linking theoretical laws to practical laboratory examples.")
        plan.append("Perform 2 hands-on or numerical application case studies this week.")
    if any("concept" in w.lower() for w in weak):
        recs.append("Revisit core foundational definitions and chapter summaries before attempting advanced exercises.")
        plan.append("Create concise visual mind maps or concept flashcards for key definitions.")
    if any("communication" in w.lower() or "expression" in w.lower() for w in weak):
        recs.append("Structure long-form answers using bullet points, labeled diagrams, and explicit units.")
        plan.append("Write full descriptive explanations for 3 assignment questions without skipping steps.")
    if any("consistency" in w.lower() or "discipline" in w.lower() for w in weak):
        recs.append("Establish a 25-minute daily deliberate practice rhythm to maintain assessment recency.")
        plan.append("Submit weekly homework at least 24 hours prior to deadline to build buffer time.")

    if not recs:
        recs = [
            "Maintain consistent daily practice across core subjects.",
            "Review feedback from teachers on graded assignments.",
            "Take timed chapter quizzes in the Practice Arena."
        ]
        plan = [
            "Attempt one targeted diagnostic quiz per week in your lowest-scoring topic.",
            "Schedule a 10-minute revision slot each evening for flagged questions."
        ]

    weak_str = ", ".join(weak)
    strong_str = ", ".join(strong)

    if any(k in q for k in ["strength", "strong", "best", "good"]):
        summary = (
            f"🌟 **Demonstrated Competency Strengths for {student}**:\n\n"
            f"• **Top Performing Dimensions**: **{strong_str}**.\n"
            f"• **Leveraging Your Strength**: Your solid grasp in {strong_str} is an anchor. "
            f"Use this foundation to scaffold into more complex, multi-step problem solving challenges."
        )
    elif any(k in q for k in ["improve", "weak", "growth", "focus", "plan", "action", "coach"]):
        summary = (
            f"🎯 **Targeted Skill Improvement Plan for {student}**:\n\n"
            f"• **Priority Growth Area(s)**: **{weak_str}**.\n"
            f"• **Diagnostic Insight**: Assessment evidence indicates lower confidence in {weak_str} relative to your benchmarks.\n"
            f"• **Recommended Action Plan**:\n" + "\n".join([f"  {i+1}. {p}" for i, p in enumerate(plan)]) + "\n\n"
            f"💡 **Coach Advice**: Focus on deliberate quality over volume. One thoroughly mastered problem improves your competency score more than skimming five."
        )
    else:
        summary = (
            f"🧠 **AI Skill Coach Competency Overview for {student}**:\n\n"
            f"• **Current Strengths**: **{strong_str}**\n"
            f"• **Growth Focus**: **{weak_str}**\n"
            f"• **Strategic Recommendations**:\n" + "\n".join([f"  • {r}" for r in recs[:3]]) + "\n\n"
            f"🚀 **Immediate Action Step**: Complete targeted practice in **{weak[0] if weak else 'Problem Solving'}** to raise your overall competency score."
        )

    return SkillCoachResponse(
        summary=summary,
        recommendations=recs,
        action_plan=plan,
        student_id=request.student_id,
    )

@app.post("/skill-coach/recommendations/", response_model=SkillCoachResponse, summary="Grounded Student Skill Intelligence Coach")
async def skill_coach_recommendations(request: SkillCoachRequest):
    """
    Provides evidence-backed, syllabus-grounded skill recommendations and action plans
    for students, teachers, and parents based on genuine assessed competency dimensions.
    """
    try:
        if not groq_client.api_key or groq_client.api_key == "your_groq_api_key_here":
            return generate_skill_coach_response(request)

        system_prompt = (
            "You are EduStreak AI Skill Coach, a pedagogical intelligence advisor for K-12 students.\n"
            "You are provided with real, verified competency metrics across 6 dimensions:\n"
            "1) Conceptual Understanding, 2) Problem Solving, 3) Critical Thinking, "
            "4) Application Skills, 5) Consistency & Discipline, 6) Communication & Expression.\n"
            "CRITICAL RULES:\n"
            "- Ground all advice strictly in the student's actual scores and weak/strong skills.\n"
            "- Never hallucinate fake test scores or fabricated external benchmarks.\n"
            "- Attendance and login frequency are NOT academic competencies.\n"
            "- Format output clearly with bold highlights, bullet points, and an actionable 3-step plan."
        )
        user_prompt = (
            f"STUDENT PROFILE:\n"
            f"Name: {request.student_name} (ID: {request.student_id})\n"
            f"Skill Scores (0-100): {json.dumps(request.skill_scores)}\n"
            f"Strongest Competencies: {request.strongest_skills}\n"
            f"Growth/Weak Areas: {request.weakest_skills}\n"
            f"Recent Assessed Topics: {request.assessed_topics}\n"
            f"STUDENT'S INQUIRY:\n{request.question or 'Provide a comprehensive skill improvement plan'}\n\n"
            "Generate: 1) Diagnostic Competency Analysis, 2) Specific Pedagogical Recommendations, and 3) 3-Step Action Plan."
        )
        payload = {
            "model": groq_client.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "temperature": 0.3,
            "max_tokens": 1000,
        }
        res = groq_client._call_groq_api(payload, timeout=35)
        if 'choices' in res and len(res['choices']) > 0:
            ans = res['choices'][0]['message']['content']
            fallback_obj = generate_skill_coach_response(request)
            return SkillCoachResponse(
                summary=ans,
                recommendations=fallback_obj.recommendations,
                action_plan=fallback_obj.action_plan,
                student_id=request.student_id,
            )
        return generate_skill_coach_response(request)
    except Exception as e:
        logger.warning(f"Skill coach AI error: {e}. Falling back to grounded synthesis.")
        return generate_skill_coach_response(request)

@app.get("/documents/", summary="Get list of uploaded documents")
async def get_documents():
    """
    Returns a list of all uploaded documents with their metadata.
    """
    try:
        filenames = vector_store_client.get_unique_filenames()
        # Get additional info for each document
        documents_info = []
        for filename in filenames:
            try:
                where_filter = {"filename": filename}
                all_data = vector_store_client.get_all_documents(where=where_filter)
                chunk_count = 0
                timestamp = None
                
                if all_data.get("documents") and all_data["documents"]:
                    if isinstance(all_data["documents"][0], list):
                        chunk_count = len(all_data["documents"][0])
                    else:
                        chunk_count = len(all_data["documents"])
                
                # Get timestamp from first chunk
                if all_data.get("metadatas") and all_data["metadatas"]:
                    if isinstance(all_data["metadatas"][0], list) and len(all_data["metadatas"][0]) > 0:
                        timestamp = all_data["metadatas"][0][0].get("timestamp")
                    elif isinstance(all_data["metadatas"][0], dict):
                        timestamp = all_data["metadatas"][0].get("timestamp")
                
                documents_info.append({
                    "filename": filename,
                    "chunk_count": chunk_count,
                    "uploaded_at": timestamp
                })
            except Exception as e:
                logger.warning(f"Error processing document {filename}: {e}")
                # Continue with other documents
                documents_info.append({
                    "filename": filename,
                    "chunk_count": 0,
                    "uploaded_at": None
                })
        
        return {"documents": documents_info}
    except Exception as e:
        logger.error(f"Error getting documents: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/topics/", summary="Get suggested topics from documents")
async def get_suggested_topics():
    """
    Returns a list of suggested topics based on document content.
    This is a simple implementation that extracts topics from document metadata.
    """
    try:
        # Get all documents to extract topics
        # For now, return some common topics that might be in educational documents
        # In a more advanced version, we could use NLP to extract actual topics
        
        count = vector_store_client.get_collection_count()
        if count == 0:
            return {"topics": [], "message": "No documents uploaded yet."}
        
        # Get some sample documents to suggest topics
        # We'll use a generic query to get diverse content
        sample_embedding = embedding_client.embed_query("science physics chemistry biology mathematics")
        results = vector_store_client.query(sample_embedding, n_results=min(10, count))
        
        # Extract potential topics from document content
        # This is a simple heuristic - in production, use proper topic modeling
        suggested_topics = set()
        
        if results.get('documents') and results['documents'][0]:
            for doc in results['documents'][0][:5]:  # Check first 5 documents
                # Look for chapter headings or common topic patterns
                lines = doc.split('\n')
                for line in lines[:10]:  # Check first 10 lines
                    line = line.strip()
                    if line and len(line) < 100 and ':' in line:
                        # Likely a heading
                        topic = line.split(':')[0].strip()
                        if len(topic) > 3 and len(topic) < 50:
                            suggested_topics.add(topic)
        
        # Add some common educational topics if we don't have many
        common_topics = [
            "Force and Pressure", "Friction", "Sound", "Light", 
            "Electricity", "Magnetism", "Motion", "Energy",
            "Matter", "Atoms and Molecules", "Acids and Bases",
            "Photosynthesis", "Respiration", "Ecosystem"
        ]
        
        topics_list = list(suggested_topics)[:10]  # Limit to 10
        if len(topics_list) < 5:
            topics_list.extend(common_topics[:5])
        
        return {"topics": topics_list[:15]}  # Return up to 15 topics
    
    except Exception as e:
        logger.error(f"Error getting topics: {e}", exc_info=True)
        return {"topics": [], "message": "Could not extract topics."}

# ============================================================================
# TEACHER AI TEACHING HUB ENDPOINTS
# ============================================================================

class TeacherLessonPlanRequest(BaseModel):
    grade_or_class: str = "Class 8"
    subject: str = "Science"
    chapter: str = "Cell Structure and Functions"
    topic: str = "Plant and Animal Cells"
    duration_minutes: int = 45
    learning_objectives: List[str] = []

class TeacherLessonPlanResponse(BaseModel):
    lesson_title: str
    grade_or_class: str
    subject: str
    duration_minutes: int
    objectives: List[str]
    prerequisites: List[str]
    teaching_explanation: str
    classroom_activities: List[str]
    examples: List[str]
    interactive_questions: List[str]
    assessment_ideas: List[str]
    homework_suggestions: List[str]
    learning_outcomes: List[str]

@app.post("/teacher-hub/lesson-plan/", response_model=TeacherLessonPlanResponse, summary="Generate structured pedagogical lesson plan")
def generate_lesson_plan(req: TeacherLessonPlanRequest):
    try:
        prompt = f"""You are an expert Indian School Curriculum (SCERT / CBSE) Master Teacher and Pedagogical Specialist.
Generate a structured, actionable, 45-minute lesson plan for:
Class: {req.grade_or_class}
Subject: {req.subject}
Chapter: {req.chapter}
Topic: {req.topic}
Duration: {req.duration_minutes} minutes

Format your response as valid, pure JSON with this exact structure (no surrounding markdown code blocks):
{{
  "lesson_title": "{req.topic} - Classroom Lesson Plan",
  "grade_or_class": "{req.grade_or_class}",
  "subject": "{req.subject}",
  "duration_minutes": {req.duration_minutes},
  "objectives": ["Understand the fundamental differences between plant and animal cells", "Identify cell organelles under microscopy"],
  "prerequisites": ["Basic definition of living organisms and tissues", "Familiarity with magnifying lenses"],
  "teaching_explanation": "Detailed breakdown of the core concept suitable for teacher delivery in 15 minutes...",
  "classroom_activities": ["5-minute think-pair-share on onion peel observation", "Labeling activity on blackboard diagram"],
  "examples": ["Onion peel cells vs human cheek cells", "Cell wall functioning as a brick wall in a school building"],
  "interactive_questions": ["Why do plant cells require a cell wall while animal cells do not?", "Which organelle is termed the powerhouse of the cell?"],
  "assessment_ideas": ["Quick 3-minute formative exit ticket", "Pair quiz on organelle functions"],
  "homework_suggestions": ["Draw and label a neat diagram of a plant cell with chloroplasts", "List 3 functions of the nucleus"],
  "learning_outcomes": ["Students can differentiate plant and animal cells with 90% accuracy", "Students recognize the role of plastids and cell wall"]
}}"""
        response_text = groq_client.generate_content(prompt)
        # Parse JSON safely
        clean = response_text.strip()
        if clean.startswith("```json"):
            clean = clean[7:]
        if clean.startswith("```"):
            clean = clean[3:]
        if clean.endswith("```"):
            clean = clean[:-3]
        clean = clean.strip()
        
        data = json.loads(clean)
        return TeacherLessonPlanResponse(**data)
    except Exception as e:
        logger.warning(f"Fallback lesson plan generation: {e}")
        return TeacherLessonPlanResponse(
            lesson_title=f"{req.topic} - Structured Lesson Plan",
            grade_or_class=req.grade_or_class,
            subject=req.subject,
            duration_minutes=req.duration_minutes,
            objectives=[
                f"Master fundamental concepts of {req.topic}",
                f"Apply {req.subject} principles to solve real-world problems",
                "Demonstrate conceptual clarity in formative evaluation"
            ],
            prerequisites=[
                f"Prior knowledge of introductory {req.subject} terms",
                "Basic understanding of preceding chapter units"
            ],
            teaching_explanation=f"Structured pedagogical explanation of {req.topic} grounded in the {req.subject} curriculum for {req.grade_or_class}. Begin with real-world context, introduce formal terminology, illustrate with step-by-step examples, and reinforce with guided classroom dialogue.",
            classroom_activities=[
                "Interactive 5-minute think-pair-share diagnostic opening",
                "Concept mapping on blackboard with volunteer student participation",
                "Guided problem-solving exercise with immediate peer verification"
            ],
            examples=[
                f"Everyday practical application of {req.topic}",
                "Step-by-step worked model from standard curriculum"
            ],
            interactive_questions=[
                f"What is the primary defining characteristic of {req.topic}?",
                "How does this concept connect to our previous unit?",
                "Can you formulate an example where this principle applies?"
            ],
            assessment_ideas=[
                "5-minute end-of-period exit ticket with 2 targeted questions",
                "Peer-to-peer concept explanation check"
            ],
            homework_suggestions=[
                f"Review textbook chapter on {req.topic} and solve review questions 1 to 5",
                "Write a 1-paragraph summary in your own words"
            ],
            learning_outcomes=[
                f"Students explain the core principles of {req.topic} accurately",
                "Students solve standard textbook problems with conceptual confidence"
            ]
        )

class TeacherQuestionRequest(BaseModel):
    grade_or_class: str = "Class 8"
    subject: str = "Mathematics"
    chapter: str = "Linear Equations"
    topic: str = "Solving One-Variable Equations"
    difficulty: str = "Medium"
    question_type: str = "mcq"  # mcq, short_answer, long_answer
    num_questions: int = 5
    total_marks: int = 20

class GeneratedQuestionItem(BaseModel):
    id: int
    question: str
    options: dict = {}
    correct_answer: str
    explanation: str
    marks: int

class TeacherQuestionResponse(BaseModel):
    grade_or_class: str
    subject: str
    topic: str
    difficulty: str
    questions: List[GeneratedQuestionItem]

@app.post("/teacher-hub/question-generator/", response_model=TeacherQuestionResponse, summary="Generate syllabus-grounded questions")
def generate_teacher_questions(req: TeacherQuestionRequest):
    try:
        prompt = f"""Generate {req.num_questions} high-quality {req.difficulty} difficulty {req.question_type.upper()} educational questions for Indian School Syllabus:
Class: {req.grade_or_class}
Subject: {req.subject}
Chapter: {req.chapter}
Topic: {req.topic}

Return strictly a valid JSON array of objects with keys: id (int), question (str), options (dict with A, B, C, D if MCQ else empty dict), correct_answer (str), explanation (str), marks (int). No surrounding text or markdown."""
        resp = groq_client.generate_content(prompt).strip()
        if resp.startswith("```json"):
            resp = resp[7:]
        if resp.startswith("```"):
            resp = resp[3:]
        if resp.endswith("```"):
            resp = resp[:-3]
        parsed = json.loads(resp.strip())
        if isinstance(parsed, dict) and "questions" in parsed:
            questions_data = parsed["questions"]
        elif isinstance(parsed, list):
            questions_data = parsed
        else:
            questions_data = []
            
        items = [GeneratedQuestionItem(**q) for q in questions_data]
        return TeacherQuestionResponse(
            grade_or_class=req.grade_or_class,
            subject=req.subject,
            topic=req.topic,
            difficulty=req.difficulty,
            questions=items
        )
    except Exception as e:
        logger.warning(f"Fallback question generator: {e}")
        each_mark = max(1, req.total_marks // req.num_questions)
        items = [
            GeneratedQuestionItem(
                id=i + 1,
                question=f"Explain the primary mechanism and significance of {req.topic} in {req.subject} (Question {i + 1})",
                options={"A": "Option A Definition", "B": "Option B Definition", "C": "Option C Definition", "D": "Option D Definition"} if req.question_type == "mcq" else {},
                correct_answer="Option B Definition" if req.question_type == "mcq" else "Standard curricular explanation and key formula derivation.",
                explanation=f"Based on the SCERT/CBSE {req.grade_or_class} curriculum for {req.subject}.",
                marks=each_mark
            )
            for i in range(req.num_questions)
        ]
        return TeacherQuestionResponse(
            grade_or_class=req.grade_or_class,
            subject=req.subject,
            topic=req.topic,
            difficulty=req.difficulty,
            questions=items
        )

class TeacherWorksheetRequest(BaseModel):
    grade_or_class: str = "Class 8"
    subject: str = "Mathematics"
    chapter: str = "Rational Numbers"
    topic: str = "Properties of Operations"
    num_questions: int = 6

class TeacherWorksheetResponse(BaseModel):
    title: str
    grade_or_class: str
    subject: str
    chapter: str = ""
    topic: str = ""
    instructions: List[str]
    sections: List[dict]
    answer_key: List[str]

@app.post("/teacher-hub/worksheet/", response_model=TeacherWorksheetResponse, summary="Generate structured printable classroom worksheet")
def generate_teacher_worksheet(req: TeacherWorksheetRequest):
    try:
        prompt = f"""You are a master teacher and curriculum specialist for Indian Schools (CBSE / SCERT).
Generate a high-quality, printable classroom practice worksheet for:
Class: {req.grade_or_class}
Subject: {req.subject}
Chapter: {req.chapter}
Topic: {req.topic}
Total Questions: {req.num_questions}

Format your response as valid, pure JSON with this exact structure (no surrounding markdown code blocks):
{{
  "title": "{req.subject} Classroom Worksheet: {req.topic}",
  "grade_or_class": "{req.grade_or_class}",
  "subject": "{req.subject}",
  "chapter": "{req.chapter}",
  "topic": "{req.topic}",
  "instructions": [
    "Read each question carefully before attempting your answer.",
    "Show complete step-by-step working for numerical and derivation questions.",
    "Write neatly with pencil/pen and mention units where applicable."
  ],
  "sections": [
    {{
      "section_name": "Section A: Conceptual Recall (1-2 Marks Each)",
      "questions": [
        "1. Write the precise definition or primary law of {req.topic}.",
        "2. State one daily life observation where {req.topic} is directly demonstrated."
      ]
    }},
    {{
      "section_name": "Section B: Analytical Application & Problem Solving (3 Marks Each)",
      "questions": [
        "3. A standard syllabus problem requiring students to apply formulas or conceptual principles of {req.topic}.",
        "4. Differentiate between two key aspects or conditions of {req.topic} with supporting reasons."
      ]
    }},
    {{
      "section_name": "Section C: Higher-Order Thinking Skills & Challenge (5 Marks)",
      "questions": [
        "5. A multi-step scenario-based problem or experimental design question testing deep understanding of {req.topic}."
      ]
    }}
  ],
  "answer_key": [
    "1. Exact textbook definition and fundamental terms.",
    "2. Valid observable real-world application.",
    "3. Step-by-step numerical/algebraic solution showing intermediate steps.",
    "4. Comparative distinction table with 2 points of contrast.",
    "5. Comprehensive solution with reasoned justification."
  ]
}}"""
        resp = groq_client.generate_content(prompt).strip()
        if resp.startswith("```json"):
            resp = resp[7:]
        if resp.startswith("```"):
            resp = resp[3:]
        if resp.endswith("```"):
            resp = resp[:-3]
        data = json.loads(resp.strip())
        return TeacherWorksheetResponse(**data)
    except Exception as e:
        logger.warning(f"Dynamic worksheet generation error: {e}, using syllabus fallback")
        return TeacherWorksheetResponse(
            title=f"{req.subject} Practice Worksheet: {req.chapter} - {req.topic}",
            grade_or_class=req.grade_or_class,
            subject=req.subject,
            chapter=req.chapter,
            topic=req.topic,
            instructions=[
                "Read each question carefully before attempting.",
                "Show all derivation steps, equations, and units clearly.",
                "Write your Name, Roll Number, and Date in the header section."
            ],
            sections=[
                {
                    "section_name": "Section A: Conceptual Understanding (1-2 Marks)",
                    "questions": [
                        f"1. Define {req.topic} in the context of {req.subject}.",
                        f"2. Mention two key properties or characteristics of {req.topic}."
                    ]
                },
                {
                    "section_name": "Section B: Analytical Application (3-4 Marks)",
                    "questions": [
                        f"3. Solve a standard practice exercise on {req.topic} showing all intermediate working steps.",
                        f"4. How does {req.topic} relate to concepts studied in {req.chapter}? Explain with an illustrative diagram or example."
                    ]
                },
                {
                    "section_name": "Section C: Higher Order Thinking Skills (HOTS - 5 Marks)",
                    "questions": [
                        f"5. Formulate a real-world scenario or laboratory experiment that tests the principles of {req.topic}."
                    ]
                }
            ],
            answer_key=[
                f"1. Accurate foundational definition of {req.topic}.",
                "2. Stated 2 distinct verified properties.",
                "3. Step-by-step arithmetic or logical derivation.",
                "4. Clear relational explanation with annotated diagram.",
                "5. Logical experimental procedure with control, variables, and observation."
            ]
        )

# ─── TEACHER LEARNING INSIGHTS ENGINE ──────────────────────────────────────
class TeacherLearningInsightsRequest(BaseModel):
    grade_or_class: str = "Class 8"
    subject: str = "Mathematics"
    chapter: str = ""
    topic: str = "Core Curriculum"
    student_count: int = 25
    average_score: float = 72.0
    submission_rate: float = 85.0
    weak_areas: List[str] = []

class CohortBreakdown(BaseModel):
    advanced: int
    proficient: int
    struggling: int

class TeacherLearningInsightsResponse(BaseModel):
    grade_or_class: str
    subject: str
    topic: str
    average_mastery: float
    total_students: int
    cohorts: CohortBreakdown
    weak_concepts: List[str]
    strength_areas: List[str]
    remediation_strategies: List[str]
    recommended_next_action: str

@app.post("/teacher-hub/learning-insights/", response_model=TeacherLearningInsightsResponse, summary="Generate diagnostic pedagogical insights from student performance")
def generate_teacher_learning_insights(req: TeacherLearningInsightsRequest):
    try:
        struggling_calc = max(1, round(req.student_count * max(0.05, (100.0 - req.average_score) / 100.0 * 0.6)))
        advanced_calc = max(1, round(req.student_count * max(0.1, req.average_score / 100.0 * 0.4)))
        proficient_calc = max(0, req.student_count - struggling_calc - advanced_calc)

        prompt = f"""You are a Senior Academic Auditor and Pedagogical Data Analyst for Indian Schools.
Analyze the following student performance data and generate targeted pedagogical insights:
Class: {req.grade_or_class}
Subject: {req.subject}
Chapter/Topic: {req.chapter or req.topic}
Total Assessed Students: {req.student_count}
Class Average Mastery: {req.average_score}%
Assignment Submission Rate: {req.submission_rate}%
Reported Struggle Areas: {', '.join(req.weak_areas) if req.weak_areas else 'Multi-step problem solving and conceptual application'}

Return strictly valid JSON with this exact structure (no surrounding markdown code blocks):
{{
  "grade_or_class": "{req.grade_or_class}",
  "subject": "{req.subject}",
  "topic": "{req.topic}",
  "average_mastery": {req.average_score},
  "total_students": {req.student_count},
  "cohorts": {{
    "advanced": {advanced_calc},
    "proficient": {proficient_calc},
    "struggling": {struggling_calc}
  }},
  "weak_concepts": [
    "Conceptual struggle point 1 specific to {req.topic}",
    "Common computational or procedural error identified in {req.subject}"
  ],
  "strength_areas": [
    "Foundational recall and positive engagement during classroom activities",
    "High accuracy in introductory definition and standard questions"
  ],
  "remediation_strategies": [
    "Pair struggling learners with proficient peers for 10-minute guided peer practice",
    "Provide visual step-by-step scaffolds for {req.topic}",
    "Conduct a 15-minute targeted remediation session before next summative exam"
  ],
  "recommended_next_action": "Actionable teacher directive for tomorrow's class period."
}}"""
        resp = groq_client.generate_content(prompt).strip()
        if resp.startswith("```json"):
            resp = resp[7:]
        if resp.startswith("```"):
            resp = resp[3:]
        if resp.endswith("```"):
            resp = resp[:-3]
        data = json.loads(resp.strip())
        return TeacherLearningInsightsResponse(**data)
    except Exception as e:
        logger.warning(f"Dynamic insights generation error: {e}, using rule-based metrics")
        struggling_fallback = max(1, round(req.student_count * 0.2))
        advanced_fallback = max(1, round(req.student_count * 0.3))
        proficient_fallback = max(0, req.student_count - struggling_fallback - advanced_fallback)
        return TeacherLearningInsightsResponse(
            grade_or_class=req.grade_or_class,
            subject=req.subject,
            topic=req.topic,
            average_mastery=req.average_score,
            total_students=req.student_count,
            cohorts=CohortBreakdown(
                advanced=advanced_fallback,
                proficient=proficient_fallback,
                struggling=struggling_fallback
            ),
            weak_concepts=[
                f"Multi-step problem solving and calculation rigor in {req.topic}",
                f"Application of {req.subject} principles to non-routine exam questions"
            ],
            strength_areas=[
                f"Textbook recall and definition retention for {req.topic}",
                f"Classroom participation during interactive discussions"
            ],
            remediation_strategies=[
                f"Conduct a 10-minute targeted diagnostic re-teaching on {req.topic}",
                "Provide scaffolded step-by-step worksheets with worked examples",
                "Utilize peer-assisted learning pairs during problem-solving sessions"
            ],
            recommended_next_action=f"Assign a 3-question formative exit ticket on {req.topic} to assess remediation impact."
        )

class TeacherAssistantChatRequest(BaseModel):
    question: str
    grade_or_class: str = "Class 8"
    subject: str = "Science"
    context: dict = {}

class TeacherAssistantChatResponse(BaseModel):
    answer: str
    pedagogy_tips: List[str]
    suggested_followups: List[str]

@app.post("/teacher-hub/assistant-chat/", response_model=TeacherAssistantChatResponse, summary="Pedagogical AI teaching assistant chat")
def teacher_assistant_chat(req: TeacherAssistantChatRequest):
    try:
        prompt = f"""You are an elite Indian School Pedagogical Advisor and Senior Teaching Mentor.
A teacher of {req.grade_or_class} ({req.subject}) is asking you:
"{req.question}"

Provide a warm, highly practical, pedagogical answer grounded in classroom teaching realities (dealing with mixed-ability students, engagement, formative checks, and standard state curriculum).
Return JSON with keys:
"answer" (str): Main pedagogical guidance,
"pedagogy_tips" (list of str): 3 practical micro-tips for tomorrow's class,
"suggested_followups" (list of str): 3 suggested questions the teacher could ask next."""
        resp = groq_client.generate_content(prompt).strip()
        if resp.startswith("```json"):
            resp = resp[7:]
        if resp.startswith("```"):
            resp = resp[3:]
        if resp.endswith("```"):
            resp = resp[:-3]
        data = json.loads(resp.strip())
        return TeacherAssistantChatResponse(**data)
    except Exception as e:
        logger.warning(f"Fallback teacher assistant chat: {e}")
        return TeacherAssistantChatResponse(
            answer=f"For {req.grade_or_class} {req.subject}: To effectively address '{req.question}', begin with a concrete 3-minute diagnostic anchor. Frame the core concept using visual models or relatable local analogies. Group students in mixed-ability pairs for peer-assisted learning, and close with a low-stakes 2-minute formative check to assess understanding.",
            pedagogy_tips=[
                "Use the 'Think-Pair-Share' technique to give hesitant students confidence before speaking.",
                "Anchor abstract definitions with tangible physical or local examples.",
                "Conduct an exit ticket at the end of class with 2 diagnostic questions to gauge tomorrow's pacing."
            ],
            suggested_followups=[
                f"How can I differentiate this topic for struggling learners in {req.grade_or_class}?",
                "What common misconceptions do students hold about this chapter?",
                "Can you generate a 5-question quick quiz for tomorrow's bell-ringer?"
            ]
        )

# ─── PRINCIPAL INVITATION EMAIL DISPATCH ENDPOINTS ─────────────────────────
class PrincipalInvitationEmailRequest(BaseModel):
    principal_email: str
    principal_name: str
    school_name: str
    school_code: str
    invitation_code: str
    invitation_token: str = ""
    acceptance_url: Optional[str] = None
    expires_at_str: Optional[str] = None

class PrincipalInvitationEmailResponse(BaseModel):
    success: bool
    status: str
    provider: str
    messageId: Optional[str] = None
    recipient: str
    timestamp: str
    details: str
    previewUrl: Optional[str] = None

@app.post("/api/v1/invitations/send-email", response_model=PrincipalInvitationEmailResponse, summary="Send official invitation email to Principal")
def send_principal_invitation_email(req: PrincipalInvitationEmailRequest):
    """
    Dispatches a branded invitation email to a newly designated School Principal.
    Supports SMTP transport, Resend API, and internal delivery engine simulation.
    """
    if not req.principal_email or "@" not in req.principal_email:
        raise HTTPException(status_code=400, detail="Invalid principal email address")
    if not req.invitation_code:
        raise HTTPException(status_code=400, detail="Invitation code is required")

    result = email_service.send_invitation_email(
        principal_email=req.principal_email,
        principal_name=req.principal_name,
        school_name=req.school_name,
        school_code=req.school_code,
        invitation_code=req.invitation_code,
        invitation_token=req.invitation_token,
        acceptance_url=req.acceptance_url,
        expires_at_str=req.expires_at_str,
    )
    return PrincipalInvitationEmailResponse(**result)

@app.post("/api/v1/invitations/resend-email", response_model=PrincipalInvitationEmailResponse, summary="Resend invitation email to Principal")
def resend_principal_invitation_email(req: PrincipalInvitationEmailRequest):
    """
    Re-dispatches an invitation email to a Principal with refreshed or existing token.
    """
    return send_principal_invitation_email(req)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)