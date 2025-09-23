#!/bin/bash

# Setup script for webhook server on production
# This creates a simple webhook listener using webhook package

set -e

echo "🔧 Installing webhook package..."
apt-get update
apt-get install -y webhook

echo "📝 Creating webhook configuration..."
cat > /etc/webhook/hooks.json << 'EOF'
[
  {
    "id": "clap-deploy",
    "execute-command": "/opt/clap/auto-update-webhook.sh",
    "command-working-directory": "/opt/clap",
    "response-message": "Deployment triggered",
    "trigger-rule": {
      "match": {
        "type": "payload-hmac-sha256",
        "secret": "WEBHOOK_SECRET_HERE",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature-256"
        }
      }
    }
  }
]
EOF

echo "🔐 Please set your webhook secret in /etc/webhook/hooks.json"
echo "   Replace 'WEBHOOK_SECRET_HERE' with a secure secret"

echo "📋 Creating systemd service..."
cat > /etc/systemd/system/clap-webhook.service << 'EOF'
[Unit]
Description=CLAP Deployment Webhook
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/webhook -hooks /etc/webhook/hooks.json -verbose -port 9000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Enabling and starting webhook service..."
systemctl daemon-reload
systemctl enable clap-webhook
systemctl start clap-webhook

echo "✅ Webhook server setup complete!"
echo ""
echo "📌 Next steps:"
echo "1. Set a secure webhook secret in /etc/webhook/hooks.json"
echo "2. Reload webhook: systemctl restart clap-webhook"
echo "3. Open port 9000 in firewall (if needed)"
echo "4. Add webhook in GitHub: https://github.com/KruemmelS/clap/settings/hooks"
echo "   - Payload URL: http://YOUR_SERVER_IP:9000/hooks/clap-deploy"
echo "   - Content type: application/json"
echo "   - Secret: (same as in hooks.json)"
echo "   - Events: Just the push event"