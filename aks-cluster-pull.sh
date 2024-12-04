#!/bin/bash

#This script will pull all Azure Subscriptions you have access too and get the kubeconfig for each cluster in each sub and resource group and put it in your kubeconfig. For great use with kubectx. 

# Get all subscriptions (enabled subscriptions only)
subscriptions=$(az account list --query "[?state=='Enabled'].{id:id}" -o tsv)

# Iterate through each subscription
for subscription in $subscriptions; do
    echo "Switching to subscription: $subscription"
    az account set --subscription $subscription

    # Get all AKS clusters in the current subscription
    clusters=$(az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

    if [[ -z "$clusters" ]]; then
        echo "No AKS clusters found in subscription: $subscription"
        continue
    fi

    # Loop through each cluster and fetch kubeconfig
    while read -r cluster; do
        cluster_name=$(echo $cluster | awk '{print $1}')
        resource_group=$(echo $cluster | awk '{print $2}')
        
        echo "Fetching kubeconfig for cluster: $cluster_name in resource group: $resource_group"
        
        # Get kubeconfig and merge into the default kubeconfig
        az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing
    done <<< "$clusters"
done
