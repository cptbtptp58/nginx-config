#!/bin/bash

# Get available contexts
contexts=$(kubectl config get-contexts -o name)
predefinedContexts=("dev")
# predefinedContexts=("bjl" "ty2" "gbh")

# Loop through predefined contexts and use each one
for context in "${predefinedContexts[@]}"; do
    if [[ $contexts == *"$context"* ]]; then
        echo "Using context: $context"
        kubectl config use-context "$context"
        
        # Get deployments
        kubectl get deploy
        # Restart deployments with names 'gs-user-fronth5' and 'gs-user-frontpc'
        deployments=("gs-user-fronth5" "gs-user-frontpc")
        for deployment in "${deployments[@]}"; do
            deploymentName=$(kubectl get deploy -o name | grep "$deployment")
            if [ -n "$deploymentName" ]; then
                kubectl rollout restart "$deploymentName"
                echo "Deployment $deploymentName restarted successfully"
            else
                echo "No deployment with name $deployment found"
            fi
        done
    else
        echo "Context $context not found in available contexts"
    fi
done
