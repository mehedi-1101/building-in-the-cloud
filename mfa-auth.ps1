# MFA authentication helper for AWS CLI / Terraform
# Usage: .\mfa-auth.ps1
# Writes temporary credentials to ~/.aws/credentials under the configured profile.
# Valid for 12 hours. Run once per day before any AWS work.
#
# Setup: replace the two variables below with your own values.
# MFA_SERIAL: IAM -> Users -> your user -> Security credentials -> MFA device ARN
# PROFILE:    the AWS CLI profile name you want credentials written to

$MFA_SERIAL = "arn:aws:iam::YOUR_ACCOUNT_ID:mfa/YOUR_DEVICE_NAME"
$PROFILE    = "YOUR_PROFILE_NAME"

$code = Read-Host "Enter MFA code"

$result = aws sts get-session-token `
  --serial-number $MFA_SERIAL `
  --token-code $code | ConvertFrom-Json

if (-not $result) {
  Write-Host "ERROR: Failed to get session token. Check your MFA code." -ForegroundColor Red
  return
}

# Write credentials to ~/.aws/credentials under [mh-dev] profile
aws configure set aws_access_key_id     $result.Credentials.AccessKeyId     --profile $PROFILE
aws configure set aws_secret_access_key $result.Credentials.SecretAccessKey --profile $PROFILE
aws configure set aws_session_token     $result.Credentials.SessionToken     --profile $PROFILE
aws configure set region                ap-south-1                            --profile $PROFILE

Write-Host "MFA session active until $($result.Credentials.Expiration)" -ForegroundColor Green
Write-Host "Profile '$PROFILE' updated in ~/.aws/credentials" -ForegroundColor Green
Write-Host "You can now run deploy commands from any terminal." -ForegroundColor Green
