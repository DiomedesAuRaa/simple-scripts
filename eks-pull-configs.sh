#!/bin/bash

DEFAULT_REGION="us-east-1"

# Ask for profile name
read -rp "Enter AWS profile name to use: " PROFILE

# Check auth
echo "[*] Verifying credentials for profile '$PROFILE'..."
aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "[!] Auth failed for profile '$PROFILE'. Run 'aws sso login --profile $PROFILE' or check your credentials."
  exit 1
fi

echo "[✓] Auth successful."

# Get regions
REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --*
