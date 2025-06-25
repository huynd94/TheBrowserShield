#!/bin/bash

# Monitoring script for Anti-Detect Browser Manager
# Usage: ./scripts/monitor.sh

APP_NAME="anti-detect-browser"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

echo "🖥️  Anti-Detect Browser Manager - System Monitor"
echo "================================================"
echo ""

# Service status
echo "📊 Service Status:"
if systemctl is-active --quiet $APP_NAME.service; then
    echo "✅ Service is RUNNING"
else
    echo "❌ Service is STOPPED"
fi

echo ""
systemctl status $APP_NAME.service --no-pager -l | head -20

echo ""
echo "🌐 Application Health:"
if curl -s http://localhost:5000/health > /dev/null; then
    echo "✅ Application is responding"
    echo "🔗 URL: http://$SERVER_IP:5000"
else
    echo "❌ Application is not responding"
fi

echo ""
echo "💾 System Resources:"
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "Disk Usage:"
df -h | grep -E "(Filesystem|/$|/home)"

echo ""
echo "🔍 Application Process:"
ps aux | grep node | grep -v grep

echo ""
echo "📊 Network Connections:"
netstat -tlnp | grep :5000

echo ""
echo "📝 Recent Logs (last 10 lines):"
journalctl -u $APP_NAME.service -n 10 --no-pager

echo ""
echo "📈 Application Statistics:"
if curl -s http://localhost:5000/api/profiles/system/stats > /dev/null; then
    curl -s http://localhost:5000/api/profiles/system/stats | python3 -m json.tool 2>/dev/null || echo "Could not parse statistics"
else
    echo "Could not fetch application statistics"
fi

echo ""
echo "🔄 Service Management Commands:"
echo "  Start:   sudo systemctl start $APP_NAME.service"
echo "  Stop:    sudo systemctl stop $APP_NAME.service"
echo "  Restart: sudo systemctl restart $APP_NAME.service"
echo "  Status:  sudo systemctl status $APP_NAME.service"
echo "  Logs:    sudo journalctl -u $APP_NAME.service -f"