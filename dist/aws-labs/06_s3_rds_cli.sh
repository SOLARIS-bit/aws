#!/bin/bash
# =============================================================
# AWS CLI - S3 & RDS operations
# Run AFTER: aws configure
# =============================================================

REGION="${AWS_REGION:-us-east-1}"
BUCKET_NAME="my-lab-bucket-$(date +%s)"  # unique name

echo "=============================="
echo "       S3 OPERATIONS"
echo "=============================="

echo ""
echo "--- Listing existing S3 buckets ---"
aws s3 ls

echo ""
echo "--- Creating bucket: $BUCKET_NAME ---"
aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"

echo ""
echo "--- Creating a test file and uploading it ---"
echo "Hello from AWS Lab $(date)" > /tmp/test-file.txt
aws s3 cp /tmp/test-file.txt "s3://$BUCKET_NAME/"

echo ""
echo "--- Listing bucket contents ---"
aws s3 ls "s3://$BUCKET_NAME/"

echo ""
echo "--- Deleting the file ---"
aws s3 rm "s3://$BUCKET_NAME/test-file.txt"

echo ""
echo "--- Deleting the bucket ---"
aws s3 rb "s3://$BUCKET_NAME"

echo ""
echo "=============================="
echo "       RDS OPERATIONS"
echo "=============================="

echo ""
echo "--- Creating RDS subnet group (needs at least 2 AZs) ---"

# Get two subnets in different AZs from the default VPC
SUBNET1=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=default-for-az,Values=true" \
  --query "Subnets[0].SubnetId" \
  --output text)

SUBNET2=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=default-for-az,Values=true" \
  --query "Subnets[1].SubnetId" \
  --output text)

echo "Subnet 1: $SUBNET1"
echo "Subnet 2: $SUBNET2"

aws rds create-db-subnet-group \
  --region "$REGION" \
  --db-subnet-group-name my-rds-subnetgrp \
  --db-subnet-group-description "RDS subnet group for lab" \
  --subnet-ids "$SUBNET1" "$SUBNET2" 2>/dev/null || \
  echo "Subnet group already exists, continuing..."

echo ""
echo "--- Creating RDS MySQL instance (takes ~5 mins) ---"
aws rds create-db-instance \
  --region "$REGION" \
  --db-instance-identifier mydb01 \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0 \
  --allocated-storage 20 \
  --db-name appdb \
  --master-username adminuser \
  --master-user-password 'ChangeMe_StrongPassword_123!' \
  --db-subnet-group-name my-rds-subnetgrp \
  --publicly-accessible

echo ""
echo "--- Waiting for RDS to be available (this can take several minutes) ---"
aws rds wait db-instance-available \
  --region "$REGION" \
  --db-instance-identifier mydb01

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier mydb01 \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)

echo ""
echo "=== RDS is ready! ==="
echo "Endpoint : $RDS_ENDPOINT"
echo "Port     : 3306"
echo "User     : adminuser"
echo "DB       : appdb"
echo ""
echo "Connect with:"
echo "  mysql -h $RDS_ENDPOINT -P 3306 -u adminuser -p'ChangeMe_StrongPassword_123!' appdb"
