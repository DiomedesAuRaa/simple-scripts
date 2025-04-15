#!/bin/bash

DEFAULT_REGION="us-east-1"

# Get all profile names from config
PROFILES=$(awk '/^\[profile / {gsub(/\[profile |]/,""); print $1}' ~/.aws/config)

for PROFILE in $PROFILES; do
  echo -e "\n=== Profile: $PROFILE ==="

  # Ensure region is set
  REGION=$(aws configure get region --profile "$PROFILE")
  [ -z "$REGION" ] && REGION="$DEFAULT_REGION"

  REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text --profile "$PROFILE" 2>/dev/null)

  for REGION in $REGIONS; do
    CLUSTERS=$(aws eks list-clusters --region "$REGION" --profile "$PROFILE" --query "clusters[]" --output text 2>/dev/null)

    if [ -z "$CLUSTERS" ]; then
      continue
    fi

    for CLUSTER in $CLUSTERS; do
      echo "[+] $CLUSTER ($REGION) from profile $PROFILE"
      aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" --profile "$PROFILE" >/dev/null
    done
  done
done

echo "[✓] Done pulling kubeconfigs from all profiles."
