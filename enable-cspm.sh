#!/bin/bash

set -euo pipefail

# Configuration
CONFIG_FILE="config.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/$CONFIG_FILE"

# CLI arguments
CONNECTOR_NAME=""
PROJECT_ID=""
HIERARCHY_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Show usage
show_usage() {
    echo "Usage: $0 --connector CONNECTOR_NAME --project PROJECT_ID --hierarchy HIERARCHY_ID"
    echo ""
    echo "Enables advanced CSPM with VM scanning, container assessment, data sensitivity discovery, and CIEM"
    echo ""
    echo "Arguments:"
    echo "  --connector CONNECTOR_NAME   GCP security connector name"
    echo "  --project PROJECT_ID         GCP project ID"
    echo "  --hierarchy HIERARCHY_ID     GCP project number (hierarchy identifier)"
    echo ""
    echo "Examples:"
    echo "  $0 --connector GCP_my-project --project my-project-123 --hierarchy 123456789012"
}

# Parse CLI arguments
parse_args() {
    if [[ $# -lt 6 ]]; then
        show_usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --connector)
                CONNECTOR_NAME="$2"
                shift 2
                ;;
            --project)
                PROJECT_ID="$2"
                shift 2
                ;;
            --hierarchy)
                HIERARCHY_ID="$2"
                shift 2
                ;;
            *)
                log_error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$CONNECTOR_NAME" || -z "$PROJECT_ID" || -z "$HIERARCHY_ID" ]]; then
        log_error "Missing required arguments"
        show_usage
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("az" "jq" "curl")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "$dep is not installed. Please install it first."
            exit 1
        fi
    done
}

# Load configuration
load_config() {
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_error "Configuration file not found: $CONFIG_PATH"
        exit 1
    fi
}

# Get Azure access token
get_access_token() {
    log_info "Getting Azure access token..."
    if ! az account show &>/dev/null; then
        log_error "Not logged into Azure. Run 'az login' first."
        exit 1
    fi
    
    ACCESS_TOKEN=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
    if [[ -z "$ACCESS_TOKEN" ]]; then
        log_error "Failed to get access token"
        exit 1
    fi
}

# Build API URL using CLI arguments
build_url() {
    local subscription_id=$(jq -r '.azure.subscriptionId' "$CONFIG_PATH")
    local resource_group=$(jq -r '.azure.resourceGroup' "$CONFIG_PATH")
    local api_version=$(jq -r '.azure.apiVersion' "$CONFIG_PATH")
    
    echo "https://management.azure.com/subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.Security/securityConnectors/$CONNECTOR_NAME?api-version=$api_version"
}

# Generate advanced CSPM payload
generate_advanced_cspm_payload() {
    jq -n \
        --slurpfile config "$CONFIG_PATH" \
        --arg projectId "$PROJECT_ID" \
        --arg hierarchyId "$HIERARCHY_ID" \
        '{
            location: $config[0].azure.location,
            properties: {
                hierarchyIdentifier: $hierarchyId,
                environmentName: "GCP",
                offerings: [
                    {
                        offeringType: "CspmMonitorGcp",
                        nativeCloudConnection: {
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.cspm,
                            serviceAccountEmailAddress: $config[0].serviceAccounts.cspmMonitor
                        }
                    },
                    {
                        offeringType: "DefenderCspmGcp",
                        vmScanners: {
                            enabled: true,
                            configuration: {
                                exclusionTags: {},
                                scanningMode: "Default"
                            }
                        },
                        mdcContainersAgentlessDiscoveryK8s: {
                            enabled: true,
                            workloadIdentityProviderId: "containers",
                            serviceAccountEmailAddress: ("mdc-containers-k8s-operator@" + $projectId + ".iam.gserviceaccount.com")
                        },
                        mdcContainersImageAssessment: {
                            enabled: true,
                            workloadIdentityProviderId: "containers",
                            serviceAccountEmailAddress: ("mdc-containers-artifact-assess@" + $projectId + ".iam.gserviceaccount.com")
                        },
                        dataSensitivityDiscovery: {
                            enabled: true,
                            serviceAccountEmailAddress: ("mdc-data-sec-posture-storage@" + $projectId + ".iam.gserviceaccount.com"),
                            workloadIdentityProviderId: "data-security-posture-storage"
                        },
                        ciemDiscovery: {
                            serviceAccountEmailAddress: ("microsoft-defender-ciem@" + $projectId + ".iam.gserviceaccount.com"),
                            workloadIdentityProviderId: "ciem-discovery",
                            azureActiveDirectoryAppName: "mciem-gcp-oidc-app"
                        }
                    }
                ],
                environmentData: {
                    environmentType: "GcpProject",
                    projectDetails: {
                        projectId: $projectId,
                        workloadIdentityPoolId: $config[0].gcp.workloadIdentityPoolId
                    },
                    organizationalData: $config[0].gcp.organizationalData,
                    scanInterval: $config[0].gcp.scanInterval
                }
            }
        }'
}

# Make API call
make_api_call() {
    local payload="$1"
    local url="$2"
    
    log_info "Making API call to enable advanced CSPM..."
    log_info "Target: $CONNECTOR_NAME (Project: $PROJECT_ID)"
    log_info "Features: VM Scanning, Container Assessment, Data Sensitivity Discovery, CIEM"
    
    local response
    local http_code
    
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -X PUT "$url" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    http_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    response_body=$(echo "$response" | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        log_info "Successfully enabled advanced CSPM (HTTP $http_code)"
        return 0
    else
        log_error "API call failed with HTTP $http_code"
        echo "$response_body" | jq -r '.errorMessage // .message // .' 2>/dev/null || echo "$response_body"
        return 1
    fi
}

# Main function
main() {
    parse_args "$@"
    
    check_dependencies
    load_config
    get_access_token
    
    local url
    url=$(build_url)
    
    log_info "Enabling advanced CSPM for GCP project..."
    
    local payload
    payload=$(generate_advanced_cspm_payload)
    
    make_api_call "$payload" "$url"
}

# Run main function
main "$@"