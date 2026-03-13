#!/bin/bash
# =============================================================
# Lab 5 - Deploy Dockerised Wordpress + MySQL
# Run this ON the Wordpress EC2 instance via SSH:
#   ssh -i MyLabKey.pem ubuntu@<WORDPRESS_IP> 'bash -s' < 05_setup_wordpress.sh
# =============================================================

set -e

echo "=== Installing Docker Engine ==="
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl git gnupg lsb-release

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf makecache
  sudo dnf install -y docker git
  sudo dnf install -y docker-compose-plugin 2>/dev/null || true
else
  echo "Unsupported package manager"
  exit 1
fi

echo "=== Verifying Docker ==="
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker --no-pager

if ! docker compose version >/dev/null 2>&1; then
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  case "$(uname -m)" in
    x86_64) COMPOSE_ARCH="x86_64" ;;
    aarch64|arm64) COMPOSE_ARCH="aarch64" ;;
    *)
      echo "Unsupported architecture for Docker Compose"
      exit 1
      ;;
  esac
  curl -fsSL "https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-linux-${COMPOSE_ARCH}" \
    -o /tmp/docker-compose
  chmod +x /tmp/docker-compose
  sudo mv /tmp/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
fi

sudo docker run --rm hello-world

echo "=== Cloning awesome-compose and deploying Wordpress ==="
rm -rf ~/awesome-compose
git clone https://github.com/docker/awesome-compose.git ~/awesome-compose
cd ~/awesome-compose/wordpress-mysql
sudo docker compose up -d

echo "=== Waiting for containers to be healthy ==="
sleep 15
sudo docker compose ps

echo ""
echo "=== Done! ==="
echo "Wordpress : http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "(Port 80 must be open in your EC2 Security Group Inbound Rules)"
