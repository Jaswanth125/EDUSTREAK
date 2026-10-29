# Study Assistant Setup Instructions

## Quick Start

### 1. Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd study_assistant_backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # Linux/Mac:
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Create `.env` file:**
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   PORT=8000
   HOST=0.0.0.0
   ```

5. **Set up Firebase (choose one):**

   **Option A - Service Account (Recommended):**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file securely
   - Add to `.env`:
     ```env
     FIREBASE_SERVICE_ACCOUNT_PATH=path/to/serviceAccountKey.json
     ```

   **Option B - Default Credentials:**
   - If using Firebase CLI or Google Cloud, default credentials will be used
   - No additional setup needed

6. **Start the server:**
   ```bash
   python start_server.py
   ```

### 2. Flutter App Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Update backend URL (if needed):**
   - Open `lib/services/study_assistant_service.dart`
   - For Android emulator, change `baseUrl` to `http://10.0.2.2:8000`
   - For production, use your server URL

3. **Run the app:**
   ```bash
   flutter run
   ```

### 3. Test the Integration

1. Login as a **student** in the Flutter app
2. Go to Student Dashboard
3. Tap "Study Assistant"
4. Select a unit, topic, and subtopic
5. View generated content and try the chat feature

## Required API Keys

You need to provide:
1. **Groq API Key** - Get from https://console.groq.com/
   - Add to `.env` as `GROQ_API_KEY`

2. **Firebase Service Account Key** (for backend authentication)
   - Download from Firebase Console
   - Add path to `.env` as `FIREBASE_SERVICE_ACCOUNT_PATH`

## Troubleshooting

### Backend won't start
- Check Python version (3.8+)
- Verify all dependencies installed
- Check `.env` file exists and has `GROQ_API_KEY`

### Authentication errors
- Verify Firebase Admin SDK is configured
- Check service account key path is correct
- Ensure user has "student" role in Firestore

### Content not generating
- Verify `GROQ_API_KEY` is valid
- Check backend logs for errors
- Ensure PDF files are uploaded for the unit

### Flutter can't connect
- Verify backend is running on correct port
- For Android emulator, use `10.0.2.2:8000` instead of `localhost`
- Check network permissions in AndroidManifest.xml

## File Structure

```
EDUSTREAK/
├── study_assistant_backend/      # FastAPI backend
│   ├── main.py                   # Main API server
│   ├── requirements.txt          # Python dependencies
│   ├── start_server.py           # Startup script
│   └── .env                      # Environment variables (create this)
├── study_assistant (2)/
│   └── study_assistant (1)/      # Original Python study assistant
│       ├── app.py
│       ├── db_utils.py
│       ├── content_utils.py
│       └── rag_utils.py
└── lib/
    ├── services/
    │   └── study_assistant_service.dart
    └── screens/
        └── student/
            └── study_assistant_screen.dart
```

## Next Steps

1. Get your Groq API key from https://console.groq.com/
2. Set up Firebase service account
3. Start the backend server
4. Test in the Flutter app

For detailed information, see `INTEGRATION_GUIDE.md`.

