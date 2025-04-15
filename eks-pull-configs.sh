#!/bin/bash

# Optional: enable this to discover clusters across all regions
ALL_REGIONS=true

if [ "$ALL_REGIONS" = true ]; then
  REGIONS=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
else
  REGIONS=$(aws configure get region)
fi

for REGION in $REGIONS; do
  echo "Checking region: $REGION"
  CLUSTERS=$(aws eks list-clusters --region "$REGION" --query "clusters[]" --output text)

  for CLUSTER in $CLUSTERS; do
    echo "Updating kubeconfig for cluster: $CLUSTER in $REGION"
    aws eks update-kubeconfig \
      --region "$REGION" \
      --name "$CLUSTER"
  done
done

echo "All kubeconfigs updated. Use 'kubectx' to switch between them."
