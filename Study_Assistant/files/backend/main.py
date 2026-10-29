import os
import io
import logging
import hashlib
from datetime import datetime

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import PyPDF2
import docx
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Import service clients
from services.embedding import EmbeddingClient
from services.vectorstore import VectorStoreClient
from services.groq_client import GroqClient, GroqAPIException
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

@app.get("/status/", summary="Get the status of the vector store")
async def get_status():
    """Returns the number of items in the vector store."""
    try:
        count = vector_store_client.get_collection_count()
        return {"vector_store_item_count": count}
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

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

@app.post("/chat/", response_model=ChatResponse, summary="Chat with AI tutor")
async def chat_with_ai(request: ChatRequest):
    """
    General chat with AI tutor (without document context).
    """
    try:
        logger.info(f"Chat message received: {request.message[:50]}...")
        
        # Use Groq chat method
        response = groq_client.chat(request.message, request.conversation_history)
        
        return ChatResponse(response=response)
    
    except GroqAPIException as e:
        logger.error(f"Groq provider error during chat: {e}")
        raise HTTPException(status_code=502, detail=str(e))
    except Exception as e:
        logger.error(f"Error in chat: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error in chat: {str(e)}")

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)