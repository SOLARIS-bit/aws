#!/bin/bash
# =============================================================
# MASTER DEPLOY SCRIPT
# Ties everything together after AWS CLI is configured.
# Usage: ./deploy_all.sh
# =============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================"
echo "  AWS Cloud Computing Lab - Full Deployment"
echo "================================================================"

# ---- Step 0: Verify AWS CLI is configured ----
echo ""
echo "[0/6] Checking AWS CLI configuration..."
aws sts get-caller-identity || {
  echo "ERROR: AWS CLI not configured. Run: aws configure"
  exit 1
}

# ---- Step 1: Create all EC2 instances ----
echo ""
echo "[1/6] Creating EC2 instances..."
bash "$SCRIPT_DIR/01_create_ec2.sh"
source ~/.lab_ips

if [[ "$KEY_FILE" != /* ]]; then
  if [[ -f "$SCRIPT_DIR/$KEY_FILE" ]]; then
    KEY_FILE="$SCRIPT_DIR/$KEY_FILE"
  elif [[ -f "$HOME/Downloads/$KEY_FILE" ]]; then
    KEY_FILE="$HOME/Downloads/$KEY_FILE"
  fi
fi

if [[ ! -f "$KEY_FILE" ]]; then
  echo "ERROR: SSH key file not found: $KEY_FILE"
  echo "Download labsuser.pem from AWS Academy and place it in $SCRIPT_DIR or ~/Downloads"
  exit 1
fi

chmod 400 "$KEY_FILE" 2>/dev/null || true

# ---- Step 2: Wait for SSH to be ready ----
echo ""
echo "[2/6] Waiting 30s for SSH to become available..."
sleep 30

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

# ---- Step 3: Configure WebServer ----
echo ""
echo "[3/6] Configuring WebServer (nginx + website)..."
ssh $SSH_OPTS -i "$KEY_FILE" "${SSH_USER}@${WEBSERVER_IP}" \
  'bash -s' < "$SCRIPT_DIR/02_setup_webserver.sh"
echo "WebServer ready: http://$WEBSERVER_IP/website"

# ---- Step 4: Configure Database ----
echo ""
echo "[4/6] Configuring Database (MySQL)..."
ssh $SSH_OPTS -i "$KEY_FILE" "${SSH_USER}@${DATABASE_IP}" \
  'bash -s' < "$SCRIPT_DIR/03_setup_database.sh"
echo "Database ready at: $DATABASE_IP:3306"

# ---- Step 5: Configure Backend ----
echo ""
echo "[5/6] Configuring Backend (Node.js)..."
ssh $SSH_OPTS -i "$KEY_FILE" "${SSH_USER}@${BACKEND_IP}" \
  "bash -s $DATABASE_IP" < "$SCRIPT_DIR/04_setup_backend.sh"
# Start the backend
ssh $SSH_OPTS -i "$KEY_FILE" "${SSH_USER}@${BACKEND_IP}" \
  'export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"; cd ~/server && npm start &'
echo "Backend ready: http://$BACKEND_IP:3001/messages"

# ---- Step 6: Configure Wordpress ----
echo ""
echo "[6/6] Configuring Wordpress (Docker)..."
ssh $SSH_OPTS -i "$KEY_FILE" "${SSH_USER}@${WORDPRESS_IP}" \
  'bash -s' < "$SCRIPT_DIR/05_setup_wordpress.sh"
echo "Wordpress ready: http://$WORDPRESS_IP"

# ---- Summary ----
echo ""
echo "================================================================"
echo "  DEPLOYMENT COMPLETE"
echo "================================================================"
echo ""
echo "  WebServer  : http://$WEBSERVER_IP/website"
echo "  Test page  : http://$WEBSERVER_IP/test.html"
echo "  Backend    : http://$BACKEND_IP:3001"
echo "  Messages   : http://$BACKEND_IP:3001/messages"
echo "  Wordpress  : http://$WORDPRESS_IP"
echo ""
echo "  SSH Commands:"
echo "  ssh -i ${KEY_FILE} ${SSH_USER}@$WEBSERVER_IP"
echo "  ssh -i ${KEY_FILE} ${SSH_USER}@$DATABASE_IP"
echo "  ssh -i ${KEY_FILE} ${SSH_USER}@$BACKEND_IP"
echo "  ssh -i ${KEY_FILE} ${SSH_USER}@$WORDPRESS_IP"
echo "================================================================"
