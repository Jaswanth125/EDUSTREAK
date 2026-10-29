# Study Assistant Integration Guide

This guide explains how to set up and use the Study Assistant feature integrated with your Flutter application.

## Overview

The Study Assistant is a RAG-powered learning tool that:
- Generates flashcards, mnemonics, and explanations for study topics
- Provides an interactive chat interface for asking questions
- Is only accessible to students with valid Firebase authentication

## Architecture

- **Backend**: FastAPI server (`study_assistant_backend/`)
- **Frontend**: Flutter screen (`lib/screens/student/study_assistant_screen.dart`)
- **Service**: Flutter service for API calls (`lib/services/study_assistant_service.dart`)

## Setup Instructions

### 1. Backend Setup

#### Prerequisites
- Python 3.8 or higher
- Groq API key (for LLM functionality)
- Firebase Admin SDK credentials (for authentication)

#### Steps

1. **Navigate to the backend directory:**
   ```bash
   cd study_assistant_backend
   ```

2. **Create a virtual environment (recommended):**
   ```bash
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On Linux/Mac:
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables:**
   Create a `.env` file in the `study_assistant_backend` directory:
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   PORT=8000
   HOST=0.0.0.0
   # Optional: For Firebase Admin SDK
   FIREBASE_SERVICE_ACCOUNT_PATH=path/to/serviceAccountKey.json
   ```

5. **Set up Firebase Admin SDK:**
   
   **Option A: Using Service Account (Recommended for Production)**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Generate a new private key
   - Save it as `serviceAccountKey.json` in a secure location
   - Set `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env` to the path of this file

   **Option B: Using Default Credentials (For Development)**
   - If running on Google Cloud or with Firebase CLI authenticated, it will use default credentials
   - No additional setup needed

6. **Start the server:**
   ```bash
   # On Windows:
   python start_server.py
   # Or use the batch file:
   start_server.bat
   
   # On Linux/Mac:
   python3 start_server.py
   # Or use the shell script:
   chmod +x start_server.sh
   ./start_server.sh
   ```

   The server will start on `http://localhost:8000` by default.

### 2. Flutter App Setup

#### Update Backend URL

1. **For local development:**
   - Open `lib/services/study_assistant_service.dart`
   - The `baseUrl` is already set to `http://localhost:8000`
   - For Android emulator, use `http://10.0.2.2:8000`
   - For iOS simulator, use `http://localhost:8000`

2. **For production:**
   - Update the `baseUrl` in `study_assistant_service.dart` to your production server URL
   - Example: `static const String baseUrl = 'https://api.yourdomain.com';`

#### Install Dependencies

The `http` package has been added to `pubspec.yaml`. Run:
```bash
flutter pub get
```

### 3. Testing the Integration

1. **Start the backend server** (see Backend Setup above)

2. **Run your Flutter app:**
   ```bash
   flutter run
   ```

3. **Login as a student** in the Flutter app

4. **Navigate to Study Assistant:**
   - Go to Student Dashboard
   - Tap on "Study Assistant" card

5. **Test the features:**
   - Select a unit
   - Select a topic and subtopic
   - View generated flashcards, mnemonics, and explanations
   - Try the chat feature

## API Endpoints

All endpoints require Firebase authentication token in the Authorization header:
```
Authorization: Bearer <firebase_id_token>
```

### Available Endpoints:

- `GET /api/units` - Get list of available units
- `GET /api/units/{unit}/topics` - Get topics for a unit
- `GET /api/units/{unit}/files` - Get files for a unit
- `GET /api/units/{unit}/subtopics/{subtopic}` - Get subtopic details
- `POST /api/content` - Get or generate content (flashcards, mnemonics, explanation)
- `GET /api/content/status` - Check content generation status
- `POST /api/chat` - Send chat message

## Security Features

1. **Student-only Access**: The backend verifies that the user has the "student" role
2. **Firebase Authentication**: All requests require valid Firebase ID tokens
3. **Error Handling**: Comprehensive error handling with appropriate HTTP status codes

## Troubleshooting

### Backend Issues

**Problem**: Import errors for study assistant modules
- **Solution**: Make sure the `study_assistant (2)/study_assistant (1)` folder exists and contains the Python files

**Problem**: Firebase authentication not working
- **Solution**: 
  - Verify Firebase Admin SDK is properly initialized
  - Check that service account key path is correct
  - Ensure Firebase project is properly configured

**Problem**: Groq API errors
- **Solution**: 
  - Verify `GROQ_API_KEY` is set in `.env`
  - Check that the API key is valid and has sufficient credits

### Flutter App Issues

**Problem**: Cannot connect to backend
- **Solution**: 
  - Verify backend server is running
  - Check the `baseUrl` in `study_assistant_service.dart`
  - For Android emulator, use `http://10.0.2.2:8000` instead of `localhost`
  - Check network permissions in AndroidManifest.xml

**Problem**: Authentication errors
- **Solution**: 
  - Ensure user is logged in
  - Verify user has "student" role
  - Check Firebase authentication is working

**Problem**: Content not generating
- **Solution**: 
  - Check backend logs for errors
  - Verify Groq API key is valid
  - Ensure PDF files are uploaded for the unit

## Production Deployment

### Backend Deployment

1. **Use a production server** (e.g., AWS, Google Cloud, Heroku)
2. **Set environment variables** on the server
3. **Use HTTPS** for secure communication
4. **Update CORS settings** to only allow your Flutter app's domain
5. **Set up process management** (e.g., systemd, PM2, supervisor)

### Flutter App Deployment

1. **Update `baseUrl`** to production server URL
2. **Test thoroughly** before release
3. **Monitor error logs** for any issues

## Required API Keys

You will need:
1. **Groq API Key**: Get it from https://console.groq.com/
2. **Firebase Service Account Key**: From Firebase Console (for backend authentication)

## Support

For issues or questions:
1. Check the backend logs for error messages
2. Verify all environment variables are set correctly
3. Ensure all dependencies are installed
4. Check that the study assistant Python files are in the correct location

