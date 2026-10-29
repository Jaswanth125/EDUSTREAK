# Quick DigitalOcean Deployment Guide

## 🚀 Quick Start (5 Minutes)

### 1. Create Droplet
- Go to: https://cloud.digitalocean.com/droplets/new
- Choose: Ubuntu 22.04, $12/month plan (2GB RAM)
- Region: Closest to you
- Create droplet

### 2. Connect to Server
```bash
ssh root@YOUR_SERVER_IP
```

### 3. Run Deployment Script
```bash
# Upload deploy.sh to server first, then:
chmod +x deploy.sh
./deploy.sh
```

### 4. Configure Environment
```bash
cd /opt/edustreak-backend
nano .env
```

Add:
```env
GROQ_API_KEY=your_key_here
PORT=8000
HOST=0.0.0.0
```

### 5. Upload Files
From your local machine:
```powershell
# Upload backend files
scp -r D:\EDUSTREAK\EDUSTREAK\edustreak\Study_Assistant\files\* root@YOUR_SERVER_IP:/opt/edustreak-backend/

# Upload Firebase key
scp path\to\serviceAccountKey.json root@YOUR_SERVER_IP:/opt/edustreak-backend/
```

### 6. Start Server
```bash
systemctl restart edustreak-backend
systemctl status edustreak-backend
```

### 7. Test
Open in browser: `http://YOUR_SERVER_IP:8000/docs`

### 8. Update Flutter App
Edit `lib/services/study_assistant_service.dart`:
```dart
const String _defaultStudyAssistantUrl =
    String.fromEnvironment('STUDY_ASSISTANT_URL', defaultValue: 'http://YOUR_SERVER_IP:8000');
```

Rebuild app: `flutter run -d e757c3d3`

## ✅ Done! Server runs 24/7 until you delete the droplet.

## 💰 Cost: ~$12/month (16+ months free with $200 credit!)

