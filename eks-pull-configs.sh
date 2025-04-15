#!/bin/bash

ALL_REGIONS=true
DEFAULT_REGION="us-east-1"

if [ "$ALL_REGIONS" = true ]; then
  REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text 2>/dev/null)
else
  REGION=$(aws configure get region)
  [ -z "$REGION" ] && REGION="$DEFAULT_REGION"
  REGIONS=$REGION
fi

for REGION in $REGIONS; do
  CLUSTERS=$(aws eks list-clusters --region "$REGION" --query "clusters[]" --output text 2>/dev/null)

  if [ -z "$CLUSTERS" ]; then
    continue
  fi

  for CLUSTER in $CLUSTERS; do
    echo "Updating kubeconfig for: $CLUSTER ($REGION)"
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER" >/dev/null
  done
done

echo "Done. kubeconfigs updated."
