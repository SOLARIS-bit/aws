#!/bin/bash
# =============================================================
# Lab 1 & AWS CLI - Create EC2 Instances remotely
# Run AFTER: aws configure
# =============================================================
set -e

REGION="${AWS_REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
KEY_NAME="${KEY_NAME:-vockey}"
KEY_FILE="${KEY_FILE:-labsuser.pem}"
SSH_USER="${SSH_USER:-ec2-user}"
INSTANCE_PROFILE_NAME="${INSTANCE_PROFILE_NAME:-LabInstanceProfile}"

echo "=== Step 1: Resolve default VPC, subnet, and AMI ==="
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" \
  --output text)

AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters \
    "Name=name,Values=al2023-ami-2023.*-x86_64" \
    "Name=architecture,Values=x86_64" \
    "Name=state,Values=available" \
  --query "sort_by(Images, &CreationDate)[-1].ImageId" \
  --output text)

echo "Using existing Academy key pair: $KEY_NAME"
echo "Using SSH key file: $KEY_FILE"
echo "Using IAM instance profile: $INSTANCE_PROFILE_NAME"
echo "Using default VPC: $DEFAULT_VPC_ID"
echo "Using AMI: $AMI_ID"

echo ""
echo "=== Step 2: Get default subnet (prefer us-east-1a, skip 1e) ==="
SUBNET_ID=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" "Name=default-for-az,Values=true" \
  --query "Subnets[?AvailabilityZone!='us-east-1e'] | [0].SubnetId" \
  --output text)
echo "Using subnet: $SUBNET_ID"

echo ""
echo "=== Step 3: Create security group ==="
SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "lab-sg" \
  --description "Lab security group" \
  --vpc-id "$DEFAULT_VPC_ID" \
  --query 'GroupId' \
  --output text 2>/dev/null || \
  aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" "Name=group-name,Values=lab-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text)
echo "Security group: $SG_ID"

# Open needed ports: 22 (SSH), 80 (HTTP), 3001 (Backend), 3306 (MySQL)
for PORT in 22 80 3001 3306; do
  aws ec2 authorize-security-group-ingress \
    --region "$REGION" \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 2>/dev/null && echo "Opened port $PORT" || echo "Port $PORT already open"
done

echo ""
echo "=== Step 4: Launch instances ==="

launch_instance() {
  local NAME=$1
  local INSTANCE_ID
  INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --iam-instance-profile "Name=$INSTANCE_PROFILE_NAME" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SG_ID" \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" \
    --query "Instances[0].InstanceId" \
    --output text)
  echo "$NAME instance ID: $INSTANCE_ID" >&2
  printf '%s' "$INSTANCE_ID"
}

WEBSERVER_ID=$(launch_instance "WebServer")
DATABASE_ID=$(launch_instance "Database")
BACKEND_ID=$(launch_instance "Backend")
WORDPRESS_ID=$(launch_instance "Wordpress")

echo ""
echo "=== Step 5: Wait for instances to be running ==="
aws ec2 wait instance-running \
  --region "$REGION" \
  --instance-ids "$WEBSERVER_ID" "$DATABASE_ID" "$BACKEND_ID" "$WORDPRESS_ID"
echo "All instances are running!"

echo ""
echo "=== Step 6: Get public IP addresses ==="
get_ip() {
  aws ec2 describe-instances \
    --region "$REGION" \
    --instance-ids "$1" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text
}

WEBSERVER_IP=$(get_ip "$WEBSERVER_ID")
DATABASE_IP=$(get_ip "$DATABASE_ID")
BACKEND_IP=$(get_ip "$BACKEND_ID")
WORDPRESS_IP=$(get_ip "$WORDPRESS_ID")

echo "WebServer  IP : $WEBSERVER_IP"
echo "Database   IP : $DATABASE_IP"
echo "Backend    IP : $BACKEND_IP"
echo "Wordpress  IP : $WORDPRESS_IP"

# Save IPs for use in other scripts
cat > ~/.lab_ips << EOF
WEBSERVER_IP=$WEBSERVER_IP
DATABASE_IP=$DATABASE_IP
BACKEND_IP=$BACKEND_IP
WORDPRESS_IP=$WORDPRESS_IP
KEY_NAME=$KEY_NAME
KEY_FILE=$KEY_FILE
SSH_USER=$SSH_USER
SG_ID=$SG_ID
EOF

echo ""
echo "=== IPs saved to ~/.lab_ips ==="
echo "Connect to WebServer : ssh -i ${KEY_FILE} ${SSH_USER}@${WEBSERVER_IP}"
echo "Connect to Database  : ssh -i ${KEY_FILE} ${SSH_USER}@${DATABASE_IP}"
echo "Connect to Backend   : ssh -i ${KEY_FILE} ${SSH_USER}@${BACKEND_IP}"
echo "Connect to Wordpress : ssh -i ${KEY_FILE} ${SSH_USER}@${WORDPRESS_IP}"
