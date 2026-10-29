# Deploy EduStreak Backend to DigitalOcean

This guide will help you deploy the Study Assistant backend server to DigitalOcean and keep it running 24/7.

## Prerequisites

- DigitalOcean account with $200 credit
- Your Groq API key
- Firebase service account JSON file (for authentication)

## Step 1: Create DigitalOcean Droplet

1. **Go to DigitalOcean Dashboard**: https://cloud.digitalocean.com/
2. **Create a Droplet**:
   - **Image**: Ubuntu 22.04 LTS (or latest)
   - **Plan**: 
     - **Basic Plan**: $6/month (1GB RAM, 1 vCPU) - Good for testing
     - **Basic Plan**: $12/month (2GB RAM, 1 vCPU) - Recommended for production
     - **Basic Plan**: $18/month (2GB RAM, 2 vCPU) - Better performance
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys (recommended) or password
   - **Hostname**: `edustreak-backend` (or your choice)

3. **Click "Create Droplet"**

## Step 2: Connect to Your Server

After the droplet is created, you'll get an IP address (e.g., `157.230.123.45`).

**On Windows (PowerShell):**
```powershell
ssh root@YOUR_SERVER_IP
```

**On Mac/Linux:**
```bash
ssh root@YOUR_SERVER_IP
```

Replace `YOUR_SERVER_IP` with your actual droplet IP.

## Step 3: Initial Server Setup

Once connected, run these commands:

```bash
# Update system
apt update && apt upgrade -y

# Install Python 3.10+ and pip
apt install -y python3 python3-pip python3-venv git

# Install nginx (for reverse proxy - optional but recommended)
apt install -y nginx

# Create app directory
mkdir -p /opt/edustreak-backend
cd /opt/edustreak-backend
```

## Step 4: Upload Your Backend Code

### Option A: Using Git (Recommended)

If your code is in a Git repository:

```bash
cd /opt/edustreak-backend
git clone YOUR_REPO_URL .
```

### Option B: Using SCP (from your local machine)

**On Windows (PowerShell):**
```powershell
# Navigate to your backend directory
cd D:\EDUSTREAK\EDUSTREAK\edustreak\Study_Assistant\files

# Upload files
scp -r * root@YOUR_SERVER_IP:/opt/edustreak-backend/
```

**On Mac/Linux:**
```bash
cd /path/to/Study_Assistant/files
scp -r * root@YOUR_SERVER_IP:/opt/edustreak-backend/
```

## Step 5: Set Up Python Environment

```bash
cd /opt/edustreak-backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

## Step 6: Configure Environment Variables

```bash
# Create .env file
nano .env
```

Add the following content (replace with your actual values):

```env
GROQ_API_KEY=your_groq_api_key_here
PORT=8000
HOST=0.0.0.0
FIREBASE_SERVICE_ACCOUNT_PATH=/opt/edustreak-backend/serviceAccountKey.json
```

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

## Step 7: Upload Firebase Service Account Key

**On your local machine (PowerShell):**
```powershell
scp path/to/serviceAccountKey.json root@YOUR_SERVER_IP:/opt/edustreak-backend/
```

## Step 8: Create Systemd Service (Keeps Server Running)

Create a systemd service file:

```bash
nano /etc/systemd/system/edustreak-backend.service
```

Add this content:

```ini
[Unit]
Description=EduStreak Backend API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/edustreak-backend
Environment="PATH=/opt/edustreak-backend/venv/bin"
ExecStart=/opt/edustreak-backend/venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Save and exit**: Press `Ctrl+X`, then `Y`, then `Enter`

Enable and start the service:

```bash
# Reload systemd
systemctl daemon-reload

# Enable service (starts on boot)
systemctl enable edustreak-backend

# Start the service
systemctl start edustreak-backend

# Check status
systemctl status edustreak-backend
```

## Step 9: Configure Firewall

```bash
# Allow SSH
ufw allow 22/tcp

# Allow HTTP (for nginx)
ufw allow 80/tcp

# Allow HTTPS (for nginx with SSL)
ufw allow 443/tcp

# Allow backend port (if not using nginx)
ufw allow 8000/tcp

# Enable firewall
ufw enable
```

## Step 10: Set Up Nginx Reverse Proxy (Recommended)

This allows you to use port 80/443 instead of 8000, and add SSL later.

```bash
nano /etc/nginx/sites-available/edustreak-backend
```

Add this content:

```nginx
server {
    listen 80;
    server_name YOUR_SERVER_IP;  # Replace with your domain if you have one

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Save and exit**, then:

```bash
# Create symbolic link
ln -s /etc/nginx/sites-available/edustreak-backend /etc/nginx/sites-enabled/

# Remove default site
rm /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Restart nginx
systemctl restart nginx
```

## Step 11: Test Your Server

```bash
# Check if service is running
systemctl status edustreak-backend

# Check logs
journalctl -u edustreak-backend -f

# Test API (in another terminal or from your browser)
curl http://YOUR_SERVER_IP:8000/docs
# Or if using nginx:
curl http://YOUR_SERVER_IP/docs
```

## Step 12: Update Flutter App

Update your Flutter app to use the cloud server:

1. **Open**: `lib/services/study_assistant_service.dart`

2. **Change the URL**:
```dart
const String _defaultStudyAssistantUrl =
    String.fromEnvironment('STUDY_ASSISTANT_URL', defaultValue: 'http://YOUR_SERVER_IP:8000');
```

Replace `YOUR_SERVER_IP` with your actual DigitalOcean droplet IP.

3. **Rebuild and deploy**:
```bash
flutter run -d e757c3d3
```

## Step 13: Set Up SSL (Optional but Recommended)

For production, use Let's Encrypt for free SSL:

```bash
# Install certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
```

## Useful Commands

### Check Server Status
```bash
systemctl status edustreak-backend
```

### View Logs
```bash
# Real-time logs
journalctl -u edustreak-backend -f

# Last 100 lines
journalctl -u edustreak-backend -n 100
```

### Restart Server
```bash
systemctl restart edustreak-backend
```

### Stop Server
```bash
systemctl stop edustreak-backend
```

### Start Server
```bash
systemctl start edustreak-backend
```

### Update Code
```bash
cd /opt/edustreak-backend
# Pull latest code or upload new files
systemctl restart edustreak-backend
```

## Cost Estimate

- **Droplet**: $6-18/month (depending on plan)
- **Total**: ~$6-18/month (well within your $200 credit = ~11-33 months free!)

## Security Tips

1. **Change SSH port** (optional):
   ```bash
   nano /etc/ssh/sshd_config
   # Change Port 22 to Port 2222 (or another port)
   systemctl restart sshd
   ```

2. **Disable root login** (create a new user):
   ```bash
   adduser edustreak
   usermod -aG sudo edustreak
   # Then use this user instead of root
   ```

3. **Set up fail2ban** (protect against brute force):
   ```bash
   apt install -y fail2ban
   systemctl enable fail2ban
   systemctl start fail2ban
   ```

## Troubleshooting

### Server not starting?
```bash
# Check logs
journalctl -u edustreak-backend -n 50

# Check if port is in use
netstat -tulpn | grep 8000
```

### Can't connect from Flutter app?
- Check firewall: `ufw status`
- Check if service is running: `systemctl status edustreak-backend`
- Test from server: `curl http://localhost:8000/docs`
- Test from your computer: `curl http://YOUR_SERVER_IP:8000/docs`

### Service keeps restarting?
- Check logs for errors: `journalctl -u edustreak-backend -f`
- Verify .env file exists and has correct values
- Check file permissions: `ls -la /opt/edustreak-backend`

## Next Steps

1. ✅ Server is running 24/7
2. ✅ Accessible from all IPs (0.0.0.0)
3. ✅ Auto-restarts on failure
4. ✅ Starts on server boot
5. ✅ Update Flutter app with server IP
6. ✅ Test from your phone

Your backend is now live and will run until you shut down the droplet!

