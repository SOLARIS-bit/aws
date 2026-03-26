#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REPO_BACKEND="fullstack-backend"
REPO_FRONTEND="fullstack-frontend"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

for repo in "$REPO_BACKEND" "$REPO_FRONTEND"; do
  aws ecr describe-repositories --region "$REGION" --repository-names "$repo" >/dev/null 2>&1 \
    || aws ecr create-repository --region "$REGION" --repository-name "$repo" >/dev/null
done

docker build -t "$REPO_BACKEND:latest" ./backend
docker build -t "$REPO_FRONTEND:latest" ./frontend

docker tag "$REPO_BACKEND:latest" "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_BACKEND:latest"
docker tag "$REPO_FRONTEND:latest" "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_FRONTEND:latest"

docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_BACKEND:latest"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_FRONTEND:latest"

echo "Pushed images to ECR in $REGION"
