#!/bin/bash
# Quick deployment script for DigitalOcean

echo "🚀 Deploying EduStreak Backend to DigitalOcean..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install dependencies
echo "📦 Installing Python and dependencies..."
apt install -y python3 python3-pip python3-venv git nginx

# Create app directory
echo "📁 Creating app directory..."
mkdir -p /opt/edustreak-backend
cd /opt/edustreak-backend

# Create virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python packages
echo "📦 Installing Python packages..."
pip install --upgrade pip
pip install -r requirements.txt

# Create systemd service
echo "⚙️ Creating systemd service..."
cat > /etc/systemd/system/edustreak-backend.service << EOF
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
EOF

# Enable and start service
echo "🔄 Enabling and starting service..."
systemctl daemon-reload
systemctl enable edustreak-backend
systemctl start edustreak-backend

# Configure firewall
echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp
ufw --force enable

echo "✅ Deployment complete!"
echo "📝 Next steps:"
echo "   1. Create .env file: nano /opt/edustreak-backend/.env"
echo "   2. Add your GROQ_API_KEY and other configs"
echo "   3. Upload serviceAccountKey.json"
echo "   4. Restart service: systemctl restart edustreak-backend"
echo "   5. Check status: systemctl status edustreak-backend"

