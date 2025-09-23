#!/bin/bash

# Alternative: Setup cron job for periodic updates (simpler than webhook)
# Checks every 5 minutes for new images

set -e

echo "📅 Setting up cron job for auto-updates..."

# Create cron job
CRON_JOB="*/5 * * * * /opt/clap/update-production.sh >> /var/log/clap-auto-update.log 2>&1"

# Add to root crontab
(crontab -l 2>/dev/null | grep -v "update-production.sh"; echo "$CRON_JOB") | crontab -

echo "✅ Cron job created!"
echo "📊 Current crontab:"
crontab -l

echo ""
echo "📌 The system will now check for updates every 5 minutes"
echo "📝 Logs: /var/log/clap-auto-update.log"
echo ""
echo "To disable: crontab -e and remove the line"