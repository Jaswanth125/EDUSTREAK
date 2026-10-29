# Study Assistant RAG Backend (FastAPI + Groq)

This project is the Retrieval-Augmented Generation (RAG) backend that powers the Study Assistant tab inside the Flutter EduStreak app. The Flutter UI now handles all interactions, so the separate Streamlit frontend has been removed.

## Features

- **Secure Document Ingestion**: Upload PDF, TXT, and DOCX files.
- **Local Embeddings & Vector Store**: Uses `sentence-transformers` for local embedding generation and `ChromaDB` for persistent vector storage.
- **LLM-Powered Answering**: Integrates with Groq's Llama 3 70b model for generating answers based on retrieved context.
- **Real-time Interaction**: A chat interface to ask questions and get scored answers instantly.
- **Monitoring**: A simple dashboard on the frontend to monitor system status.

## Architecture

- **FastAPI Backend**:
  - File uploads and text extraction.
  - Document chunking.
  - Embedding generation.
  - Vector storage in ChromaDB.
  - Query processing and retrieval.
  - LLM interaction via Groq API.
- **Flutter Frontend**:
  - Calls this backend through `StudyAssistantService`.
  - Renders upload, summary, quiz, Q&A, and chat workflows directly inside the EduStreak student dashboard.
- **Services**: Modular components for embedding, vector store management, and Groq API communication.

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-name>
```

### 2. Create a Virtual Environment and Install Dependencies

It is highly recommended to use a virtual environment to manage dependencies.

```bash
python -m venv venv
source venv/bin/activate  # On Windows, use `venv\Scripts\activate`
```

Install the required packages using `pip`:

```bash
pip install -r requirements.txt
```

### 3. Set Up Environment Variables

Create a `.env` file in the root directory and add your Groq API key:

**On Windows (PowerShell):**
```powershell
New-Item -Path .env -ItemType File
Add-Content -Path .env -Value 'GROQ_API_KEY="your-groq-api-key"'
```

**On Linux/Mac:**
```bash
echo 'GROQ_API_KEY="your-groq-api-key"' > .env
```

Or manually create a `.env` file in the root directory with the following content:

```
GROQ_API_KEY="your-groq-api-key"
```

Replace `"your-groq-api-key"` with your actual API key. You can get a free API key from the [Groq Console](https://console.groq.com/keys).

## Running the System

Only the backend server must run manually—the Flutter app serves as the frontend.

### Start the Backend Server

The backend server runs on `http://localhost:8000`.

```bash
uvicorn backend.main:app --reload --port 8000
```

The server automatically creates a `./vectorstore` directory for the ChromaDB database.

### Connect Flutter to the Backend

Run the Flutter app with the backend URL (defaults to `http://localhost:8000`). Override it with:

```bash
flutter run -d chrome --dart-define=STUDY_ASSISTANT_URL=http://<your-ip>:8000
```

## How to Use (from Flutter)

1.  Start the FastAPI backend using the command above.
2.  Launch the EduStreak Flutter app.
3.  Open the “Assistant” tab in the student dashboard.
4.  Upload PDFs/TXT/DOCX and use the Summary, Quiz, Q&A, or Chat panels—the Flutter UI will call this backend for every action.