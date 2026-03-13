#!/bin/bash
# =============================================================
# Lab 4 (Part 3) - Setup Node.js Backend
# Run this ON the Backend EC2 instance via SSH:
#   ssh -i MyLabKey.pem ubuntu@<BACKEND_IP> 'bash -s' < 04_setup_backend.sh <DATABASE_IP>
#
# Usage: ./04_setup_backend.sh <DATABASE_PUBLIC_IP>
# =============================================================

set -e

DATABASE_IP="${1:?Usage: $0 <DATABASE_PUBLIC_IP>}"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y unzip netcat-openbsd
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf makecache
  sudo dnf install -y unzip nmap-ncat
fi

echo "=== Installing nvm and Node.js ==="
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
\. "$NVM_DIR/nvm.sh"
nvm install 24
node -v
npm -v

echo "=== Setting environment variables ==="
cat >> ~/.bashrc << EOF

# Lab 4 Backend environment variables
export PORT=3001
export DB_HOST=$DATABASE_IP
export DB_USER=user
export DB_PASSWORD='Password2026\$\$'
export DB_NAME=mydatabase
EOF

# Apply immediately for this session
export PORT=3001
export DB_HOST="$DATABASE_IP"
export DB_USER=user
export DB_PASSWORD='Password2026$$'
export DB_NAME=mydatabase

echo "=== Verifying DB connectivity on port 3306 ==="
if command -v nc &>/dev/null; then
  nc -z -w5 "$DATABASE_IP" 3306 && echo "DB port 3306 is reachable!" || echo "WARNING: Cannot reach DB on port 3306. Check Security Group Inbound Rules."
else
  echo "nc not available - skipping port check"
fi

echo "=== Downloading backend code ==="
wget -q https://mtbinds.github.io/CLOUD-COMPUTING-AIVANCITY/practice/00/foundational/server.zip \
  -O /tmp/server.zip
unzip -q /tmp/server.zip -d ~/

echo "=== Patching app.js to use mysql2/promise ==="
sed -i "s/require('promise-mysql')/require('mysql2\/promise')/" ~/server/app.js
grep "mysql" ~/server/app.js

echo "=== Installing dependencies ==="
cd ~/server
npm install
npm install mysql2

echo ""
echo "=== Done! Backend ready. ==="
echo "Start server  : cd ~/server && npm start"
echo "Test root     : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001"
echo "Test messages : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3001/messages"
echo "(Port 3001 must be open in your EC2 Security Group Inbound Rules)"
