#!/bin/bash
# =============================================================
# Lab 2 & 4 (Part 1) - Setup Nginx + Deploy static website
# Run this ON the WebServer EC2 instance via SSH:
#   ssh -i MyLabKey.pem ubuntu@<WEBSERVER_IP> 'bash -s' < 02_setup_webserver.sh
# =============================================================

set -e

if command -v apt-get >/dev/null 2>&1; then
  INSTALL_CMD="sudo apt-get install -y"
  UPDATE_CMD="sudo apt-get update -y"
elif command -v dnf >/dev/null 2>&1; then
  INSTALL_CMD="sudo dnf install -y"
  UPDATE_CMD="sudo dnf makecache"
else
  echo "Unsupported package manager"
  exit 1
fi

if [[ -d /var/www/html ]]; then
  WEB_ROOT="/var/www/html"
else
  WEB_ROOT="/usr/share/nginx/html"
fi

echo "=== Installing Nginx ==="
$UPDATE_CMD
$INSTALL_CMD nginx unzip wget

echo "=== Verifying Nginx ==="
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx --no-pager

echo "=== Creating test page ==="
echo '<html><h1>Hello from EC2 Instance</h1></html>' | sudo tee "$WEB_ROOT/test.html"

echo "=== Downloading website ==="
wget -q https://mtbinds.github.io/CLOUD-COMPUTING-AIVANCITY/practice/00/foundational/website.zip \
  -O /tmp/website.zip

echo "=== Unzipping and deploying website ==="
unzip -q /tmp/website.zip -d /tmp/
sudo cp -r /tmp/website "$WEB_ROOT/"

echo ""
echo "=== Done! ==="
echo "Test page    : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/test.html"
echo "Website      : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/website"
