#!/bin/bash

set -euo pipefail

CONFIG_FILE="config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/$CONFIG_FILE"

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

# Usage
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 CONNECTOR_NAME"
    echo "Example: $0 GCP_tf-test-project-95-758b0034"
    exit 1
fi

CONNECTOR_NAME="$1"

# Get access token
ACCESS_TOKEN=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)

# Build URL
SUBSCRIPTION_ID=$(jq -r '.azure.subscriptionId' "$CONFIG_PATH")
RESOURCE_GROUP=$(jq -r '.azure.resourceGroup' "$CONFIG_PATH")
API_VERSION=$(jq -r '.azure.apiVersion' "$CONFIG_PATH")

URL="https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Security/securityConnectors/$CONNECTOR_NAME?api-version=$API_VERSION"

# Query connector
log_info "Retrieving connector details for: $CONNECTOR_NAME"

RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$URL")

# Extract and display info
PROJECT_ID=$(echo "$RESPONSE" | jq -r '.properties.environmentData.projectDetails.projectId // "null"')
HIERARCHY_ID=$(echo "$RESPONSE" | jq -r '.properties.hierarchyIdentifier // "null"')

if [[ "$PROJECT_ID" == "null" || "$HIERARCHY_ID" == "null" ]]; then
    echo "Error: Could not retrieve connector details"
    exit 1
fi

echo "Connector Name: $CONNECTOR_NAME"
echo "Project ID: $PROJECT_ID"
echo "Hierarchy ID: $HIERARCHY_ID"
echo ""
echo "CLI Command:"
echo "./enable-all-defender.sh --connector $CONNECTOR_NAME --project $PROJECT_ID --hierarchy $HIERARCHY_ID"