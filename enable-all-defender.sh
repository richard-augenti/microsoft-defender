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
    echo "Enables all Microsoft Defender for Cloud services:"
    echo "  • Basic CSPM monitoring"
    echo "  • Advanced CSPM with VM scanning, CIEM, data sensitivity discovery"
    echo "  • Defender for Containers with all sub-features"
    echo "  • Defender for Databases with Arc auto-provisioning"
    echo ""
    echo "Arguments:"
    echo "  --connector NAME    GCP security connector name"
    echo "  --project ID        GCP project ID"  
    echo "  --hierarchy ID      GCP project number (hierarchy identifier)"
    echo ""
    echo "Example:"
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

# Generate service account email addresses based on project ID
generate_service_accounts() {
    cat << EOF
{
  "cspmMonitor": "$(jq -r '.serviceAccounts.cspmMonitor' "$CONFIG_PATH")",
  "containerNative": "microsoft-defender-containers@$PROJECT_ID.iam.gserviceaccount.com",
  "containerStream": "ms-defender-containers-stream@$PROJECT_ID.iam.gserviceaccount.com",
  "containerK8s": "mdc-containers-k8s-operator@$PROJECT_ID.iam.gserviceaccount.com",
  "containerArtifact": "mdc-containers-artifact-assess@$PROJECT_ID.iam.gserviceaccount.com",
  "databasesArc": "microsoft-databases-arc-ap@$PROJECT_ID.iam.gserviceaccount.com",
  "dataSensitivity": "mdc-data-sec-posture-storage@$PROJECT_ID.iam.gserviceaccount.com",
  "ciem": "microsoft-defender-ciem@$PROJECT_ID.iam.gserviceaccount.com"
}
EOF
}

# Generate comprehensive payload with all offerings
generate_all_services_payload() {
    local service_accounts=$(generate_service_accounts)
    
    jq -n \
        --slurpfile config "$CONFIG_PATH" \
        --argjson serviceAccounts "$service_accounts" \
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
                            serviceAccountEmailAddress: $serviceAccounts.cspmMonitor
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
                            serviceAccountEmailAddress: $serviceAccounts.containerK8s
                        },
                        mdcContainersImageAssessment: {
                            enabled: true,
                            workloadIdentityProviderId: "containers",
                            serviceAccountEmailAddress: $serviceAccounts.containerArtifact
                        },
                        dataSensitivityDiscovery: {
                            enabled: true,
                            serviceAccountEmailAddress: $serviceAccounts.dataSensitivity,
                            workloadIdentityProviderId: "data-security-posture-storage"
                        },
                        ciemDiscovery: {
                            serviceAccountEmailAddress: $serviceAccounts.ciem,
                            workloadIdentityProviderId: "ciem-discovery",
                            azureActiveDirectoryAppName: "mciem-gcp-oidc-app"
                        }
                    },
                    {
                        offeringType: "DefenderForContainersGcp",
                        nativeCloudConnection: {
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.containers,
                            serviceAccountEmailAddress: $serviceAccounts.containerNative
                        },
                        dataPipelineNativeCloudConnection: {
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.containersStreams,
                            serviceAccountEmailAddress: $serviceAccounts.containerStream
                        },
                        mdcContainersImageAssessment: {
                            enabled: true,
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.containers,
                            serviceAccountEmailAddress: $serviceAccounts.containerArtifact
                        },
                        mdcContainersAgentlessDiscoveryK8s: {
                            enabled: true,
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.containers,
                            serviceAccountEmailAddress: $serviceAccounts.containerK8s
                        },
                        enableAuditLogsAutoProvisioning: true,
                        enableDefenderAgentAutoProvisioning: true,
                        enablePolicyAgentAutoProvisioning: true
                    },
                    {
                        offeringType: "DefenderForDatabasesGcp",
                        defenderForDatabasesArcAutoProvisioning: {
                            workloadIdentityProviderId: $config[0].workloadIdentityProviders.databasesArc,
                            serviceAccountEmailAddress: $serviceAccounts.databasesArc
                        },
                        arcAutoProvisioning: {
                            enabled: true,
                            configuration: {
                                proxy: null,
                                privateLinkScope: null
                            }
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
    
    log_info "Making API call to enable all Defender services..."
    log_info "Target: $CONNECTOR_NAME (Project: $PROJECT_ID)"
    log_info "Services: CSPM, Advanced CSPM, Containers, Databases"
    
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
        log_info "Successfully enabled all Defender services (HTTP $http_code)"
        log_info "Enabled offerings:"
        log_info "  • CspmMonitorGcp - Basic cloud security posture monitoring"
        log_info "  • DefenderCspmGcp - Advanced CSPM with VM scanning and CIEM"
        log_info "  • DefenderForContainersGcp - Container security with all features"
        log_info "  • DefenderForDatabasesGcp - Database protection with Arc integration"
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
    
    log_info "Enabling comprehensive Microsoft Defender for Cloud protection..."
    log_warn "This will enable all paid Defender services and may increase costs"
    
    local payload
    payload=$(generate_all_services_payload)
    
    make_api_call "$payload" "$url"
}

# Run main function
main "$@"