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
REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text --profile "$PROFILE" 2>/dev/null)

for REGION in $REGIONS; do
  CLUSTERS=$(aws eks list-clusters --region "$REGION" --profile "$PROFILE" --query "clusters[]" --output text 2>/dev/null)

  if [ -z "$CLUSTERS" ]; then
    continue
  fi

  for CLUSTER in $CLUSTERS; do
    echo "[+] Updating kubeconfig for: $CLUSTER ($REGION)"
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" --profile "$PROFILE" >/dev/null
  done
done

echo "[✓] Done."
