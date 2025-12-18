#!/bin/bash
set -euo pipefail

# Configuration - set these via environment variables
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
S3_BUCKET="${S3_BUCKET:-}"
BATCH_JOB_QUEUE="${BATCH_JOB_QUEUE:-snakemake-queue}"
ECR_REPO_NAME="${ECR_REPO_NAME:-snakemake-mwe}"

# Validation
if [[ -z "$AWS_ACCOUNT_ID" ]]; then
    echo "Error: AWS_ACCOUNT_ID is required"
    echo "Usage: AWS_ACCOUNT_ID=123456789012 S3_BUCKET=my-bucket $0"
    exit 1
fi

if [[ -z "$S3_BUCKET" ]]; then
    echo "Error: S3_BUCKET is required"
    echo "Usage: AWS_ACCOUNT_ID=123456789012 S3_BUCKET=my-bucket $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== AWS Batch Setup for Snakemake MWE ==="
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo "S3 Bucket: $S3_BUCKET"
echo "Job Queue: $BATCH_JOB_QUEUE"
echo ""

# 1. Create ECR repository (if it doesn't exist)
echo "Creating ECR repository..."
aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" 2>/dev/null || \
    aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION"

# Get ECR URI
ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" \
    --query 'repositories[0].repositoryUri' --output text)
echo "ECR URI: $ECR_URI"

# 2. Build and push image
echo ""
echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${ECR_URI%/*}"

echo "Building image..."
docker build -t "$ECR_REPO_NAME" "$PROJECT_ROOT"

echo "Tagging and pushing..."
docker tag "$ECR_REPO_NAME:latest" "$ECR_URI:latest"
docker push "$ECR_URI:latest"

# 3. Upload input data to S3
echo ""
echo "Uploading input data to S3..."
aws s3 sync "$PROJECT_ROOT/data/" "s3://$S3_BUCKET/snakemake-mwe/data/"

# 4. Generate config.yaml from template
echo ""
echo "Generating profiles/aws-batch/config.yaml..."
export ECR_URI AWS_REGION AWS_ACCOUNT_ID S3_BUCKET BATCH_JOB_QUEUE
envsubst < "$PROJECT_ROOT/profiles/aws-batch/config.yaml.example" > "$PROJECT_ROOT/profiles/aws-batch/config.yaml"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Run the workflow:"
echo "  snakemake --profile profiles/aws-batch"
