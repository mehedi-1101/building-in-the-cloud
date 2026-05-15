#!/bin/bash
# BE6 deploy script
# Usage:
#   bash deploy.sh plan     — preview changes (change set)
#   bash deploy.sh deploy   — create/update stack, upload HTML, output URLs
#   bash deploy.sh destroy  — delete stack and all resources
#
# Prerequisites:
#   - MFA session active: run .\mfa-auth.ps1 first
#   - AWS CLI profile: mh-dev (ap-south-1)
#   - BE8 stack running: mh-messages queue must exist
#   - Run from Git Bash (not PowerShell — bash routes to WSL there)

set -e

STACK_NAME="mh-be6-static-site"
TEMPLATE="template.yaml"
PROFILE="mh-dev"
REGION="ap-south-1"
SITE_DIR="../site"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"

plan() {
  echo "==> Creating change set for $STACK_NAME..."
  aws cloudformation create-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "preview-$(date +%s)" \
    --template-body "file://$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --change-set-type "$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null | grep -q 'COMPLETE\|FAILED' && echo UPDATE || echo CREATE)" \
    --profile "$PROFILE" \
    --region "$REGION"

  echo "==> Waiting for change set to be ready..."
  aws cloudformation wait change-set-create-complete \
    --stack-name "$STACK_NAME" \
    --change-set-name "preview-$(date +%s)" \
    --profile "$PROFILE" \
    --region "$REGION" 2>/dev/null || true

  echo "==> Changes:"
  aws cloudformation describe-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$(aws cloudformation list-change-sets \
        --stack-name "$STACK_NAME" \
        --profile "$PROFILE" \
        --region "$REGION" \
        --query 'Summaries[0].ChangeSetName' \
        --output text)" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Changes[].{Action:ResourceChange.Action,Resource:ResourceChange.LogicalResourceId,Type:ResourceChange.ResourceType}' \
    --output table
}

deploy() {
  echo "==> Deploying $STACK_NAME..."
  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE" \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile "$PROFILE" \
    --region "$REGION"

  echo ""
  echo "==> Stack outputs:"
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs' \
    --output table

  # index.html uses a relative URL (/api/messages) — no patching needed.
  # CloudFront routes /api/* to API Gateway, so the API GW URL is never in the HTML.

  BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text)

  CF_ID=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
    --output text)

  echo ""
  echo "==> Uploading index.html to s3://$BUCKET..."
  aws s3 cp "$SITE_DIR/index.html" "s3://$BUCKET/index.html" \
    --content-type "text/html" \
    --profile "$PROFILE" \
    --region "$REGION"

  echo "==> Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id "$CF_ID" \
    --paths "/*" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Invalidation.{Id:Id,Status:Status}' \
    --output table

  CF_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
    --output text)

  echo ""
  echo "✓ Done. Open: $CF_URL"
  echo "  Note: CloudFront takes 5-15 min to fully propagate on first deploy."
}

destroy() {
  echo "==> Emptying S3 bucket before stack deletion..."
  BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

  if [ -n "$BUCKET" ]; then
    aws s3 rm "s3://$BUCKET" --recursive \
      --profile "$PROFILE" \
      --region "$REGION" || true
    echo "==> Bucket emptied."
  fi

  echo "==> Deleting stack $STACK_NAME..."
  aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION"

  echo "==> Waiting for deletion..."
  aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --profile "$PROFILE" \
    --region "$REGION"

  echo "✓ Stack deleted."
}

case "$1" in
  plan)    plan ;;
  deploy)  deploy ;;
  destroy) destroy ;;
  *)
    echo "Usage: bash deploy.sh [plan|deploy|destroy]"
    exit 1
    ;;
esac
