#!/bin/bash
# BE8 CloudFormation deploy/destroy script
# Run with Git Bash, WSL, or AWS CloudShell
#
# Usage:
#   ./deploy.sh plan     -- create a change set and show what will change
#   ./deploy.sh deploy   -- review the change set, then confirm to execute
#   ./deploy.sh destroy  -- delete the stack and all its resources

set -e

STACK_NAME="mh-be8-async-events"
TEMPLATE_FILE="template.yaml"
REGION="ap-south-1"
PROFILE="mh-dev"
ADMIN_EMAIL="mehedi.hasan@craftsmensoftware.com"
CHANGE_SET_NAME="${STACK_NAME}-changeset"

AWS="aws --profile $PROFILE --region $REGION"

# Check whether the stack already exists
stack_exists() {
  $AWS cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].StackStatus" \
    --output text 2>/dev/null
}

plan() {
  echo "Creating change set: $CHANGE_SET_NAME"

  # Determine change set type: CREATE for new stacks, UPDATE for existing
  STATUS=$(stack_exists || true)
  if [ -z "$STATUS" ] || [ "$STATUS" = "REVIEW_IN_PROGRESS" ]; then
    CHANGE_SET_TYPE="CREATE"
  else
    CHANGE_SET_TYPE="UPDATE"
  fi

  # Delete any existing change set with the same name
  $AWS cloudformation delete-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME" 2>/dev/null || true

  $AWS cloudformation create-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME" \
    --change-set-type "$CHANGE_SET_TYPE" \
    --template-body "file://$TEMPLATE_FILE" \
    --parameters \
      ParameterKey=AdminEmail,ParameterValue="$ADMIN_EMAIL" \
    --capabilities CAPABILITY_NAMED_IAM

  echo "Waiting for change set to be ready..."
  $AWS cloudformation wait change-set-create-complete \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME"

  echo ""
  echo "Changes that will be applied:"
  echo "────────────────────────────────────────────────────────────"
  $AWS cloudformation describe-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME" \
    --query "Changes[].{Action:ResourceChange.Action, Resource:ResourceChange.LogicalResourceId, Type:ResourceChange.ResourceType, Replace:ResourceChange.Replacement}" \
    --output table
  echo "────────────────────────────────────────────────────────────"
  echo ""
  echo "Run './deploy.sh deploy' to apply these changes."
}

deploy() {
  # Check if a change set exists and is ready
  CHANGE_SET_STATUS=$($AWS cloudformation describe-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME" \
    --query "Status" \
    --output text 2>/dev/null || true)

  if [ "$CHANGE_SET_STATUS" != "CREATE_COMPLETE" ]; then
    echo "No ready change set found. Running plan first..."
    echo ""
    plan
    echo ""
  fi

  echo "Review the changes above."
  read -p "Apply changes to stack '$STACK_NAME'? (yes/no): " CONFIRM

  if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled. Change set preserved — run './deploy.sh deploy' again to apply."
    exit 0
  fi

  echo "Executing change set..."
  $AWS cloudformation execute-change-set \
    --stack-name "$STACK_NAME" \
    --change-set-name "$CHANGE_SET_NAME"

  echo "Waiting for stack operation to complete..."
  STATUS=$(stack_exists || true)
  if [[ "$STATUS" == *"CREATE"* ]]; then
    $AWS cloudformation wait stack-create-complete \
      --stack-name "$STACK_NAME"
  else
    $AWS cloudformation wait stack-update-complete \
      --stack-name "$STACK_NAME"
  fi

  echo ""
  echo "Stack outputs:"
  $AWS cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs" \
    --output table

  echo ""
  echo "IMPORTANT: Check your email and confirm both SNS subscriptions before testing."
}

destroy() {
  echo "This will permanently delete stack '$STACK_NAME' and all its resources."
  read -p "Type the stack name to confirm: " CONFIRM

  if [ "$CONFIRM" != "$STACK_NAME" ]; then
    echo "Cancelled."
    exit 0
  fi

  echo "Deleting stack..."
  $AWS cloudformation delete-stack \
    --stack-name "$STACK_NAME"

  echo "Waiting for deletion to complete..."
  $AWS cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME"

  echo "Stack deleted."
}

case "$1" in
  plan)    plan ;;
  deploy)  deploy ;;
  destroy) destroy ;;
  *)
    echo "Usage: ./deploy.sh [plan|deploy|destroy]"
    exit 1
    ;;
esac
