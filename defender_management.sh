#!/bin/bash
# Defender for Cloud Feature Group Management Scripts

# Configuration
SUBSCRIPTION_ID=$(jq -r '.defaults.subscriptionId' config.json)
RESOURCE_GROUP=$(jq -r '.defaults.resourceGroup' config.json)
MANAGEMENT_PROJECT=$(jq -r '.defaults.managementProject' config.json)
WORKLOAD_IDENTITY_POOL_ID=$(jq -r '.defaults.workloadIdentityPoolId' config.json)
MANAGEMENT_PROJECT_NUMBER=$(jq -r '.defaults.managementProjectNumber' config.json)
CSPM_MONITOR_EMAIL=$(jq -r '.defaults.serviceAccounts.cspmMonitor' config.json)
DATA_SENSITIVITY_EMAIL=$(jq -r '.defaults.serviceAccounts.dataSensitivityDiscovery' config.json)
CIEM_DISCOVERY_EMAIL=$(jq -r '.defaults.serviceAccounts.ciemDiscovery' config.json)
CONTAINER_IMAGE_ASSESSMENT_EMAIL=$(jq -r '.defaults.serviceAccounts.containerImageAssessment' config.json)
AGENTLESS_K8S_DISCOVERY_EMAIL=$(jq -r '.defaults.serviceAccounts.agentlessK8sDiscovery' config.json)
DEFENDER_FOR_SERVERS_EMAIL=$(jq -r '.defaults.serviceAccounts.defenderForServers' config.json)
DEFENDER_FOR_DATABASES_EMAIL=$(jq -r '.defaults.serviceAccounts.defenderForDatabases' config.json)
CONTAINER_NATIVE_CONNECTION_EMAIL=$(jq -r '.defaults.serviceAccounts.containerNativeConnection' config.json)
CONTAINER_DATA_PIPELINE_EMAIL=$(jq -r '.defaults.serviceAccounts.containerDataPipeline' config.json)


# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to get minimal configuration JSON
get_minimal_config() {
    local project_id=$1
    cat <<EOF
{
  "location": "eastus",
  "tags": {
    "DefenderTemplate": "minimal",
    "DefenderGroup": "minimal",
    "GcpProject": "${project_id}",
  },
  "properties": {
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "cspm",
          "serviceAccountEmailAddress": "${CSPM_MONITOR_EMAIL}"
        }
      }
    ],
    "environmentName": "GCP",
    "hierarchyIdentifier": "${PROJECT_NUMBER}",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "${project_id}",
        "projectId": "${project_id}",
        "projectNumber": "${PROJECT_NUMBER}",
        "workloadIdentityPoolId": "${WORKLOAD_IDENTITY_POOL_ID}"
      },
      "organizationalData": {
        "organizationMembershipType": "Member",
        "parentHierarchyId": "${MANAGEMENT_PROJECT}",
        "managementProjectNumber": "${MANAGEMENT_PROJECT_NUMBER}"
      }
    }
  }
}
EOF
}

# Function to get standard configuration JSON
get_standard_config() {
    local project_id=$1
    cat <<EOF
{
  "location": "eastus",
  "tags": {
    "DefenderTemplate": "standard",
    "DefenderGroup": "standard",
    "GcpProject": "${project_id}"
  },
  "properties": {
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "cspm",
          "serviceAccountEmailAddress": "${CSPM_MONITOR_EMAIL}"
        }
      },
      {
        "offeringType": "DefenderForServersGcp",
        "defenderForServers": {
          "workloadIdentityProviderId": "defender-for-servers",
          "serviceAccountEmailAddress": "${DEFENDER_FOR_SERVERS_EMAIL}"
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "subPlan": "P1"
      },
      {
        "offeringType": "DefenderCspmGcp",
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        }
      }
    ],
    "environmentName": "GCP",
    "hierarchyIdentifier": "${PROJECT_NUMBER}",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "${project_id}",
        "projectNumber": "${PROJECT_NUMBER}",
        "workloadIdentityPoolId": "${WORKLOAD_IDENTITY_POOL_ID}"
      },
      "organizationalData": {
        "organizationMembershipType": "Member",
        "parentHierarchyId": "${MANAGEMENT_PROJECT}",
        "managementProjectNumber": "${MANAGEMENT_PROJECT_NUMBER}"
      }
    }
  }
}
EOF
}

# Function to get enhanced configuration JSON
get_enhanced_config() {
    local project_id=$1
    cat <<EOF
{
  "location": "eastus",
  "tags": {
    "DefenderTemplate": "enhanced",
    "DefenderGroup": "enhanced",
    "GcpProject": "${project_id}"
  },
  "properties": {
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "cspm",
          "serviceAccountEmailAddress": "${CSPM_MONITOR_EMAIL}"
        }
      },
      {
        "offeringType": "DefenderForServersGcp",
        "defenderForServers": {
          "workloadIdentityProviderId": "defender-for-servers",
          "serviceAccountEmailAddress": "${DEFENDER_FOR_SERVERS_EMAIL}"
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "mdeAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "vaAutoProvisioning": {
          "enabled": true,
          "configuration": {
            "type": "TVM"
          }
        },
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "subPlan": "P2"
      },
      {
        "offeringType": "DefenderForDatabasesGcp",
        "defenderForDatabasesArcAutoProvisioning": {
          "workloadIdentityProviderId": "defender-for-databases-arc-ap",
          "serviceAccountEmailAddress": ${DEFENDER_FOR_DATABASES_EMAIL}
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        }
      },
      {
        "offeringType": "DefenderForContainersGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${CONTAINER_NATIVE_CONNECTION_EMAIL}"
        },
        "enableAuditLogsAutoProvisioning": true,
        "enableDefenderAgentAutoProvisioning": true,
        "enablePolicyAgentAutoProvisioning": true,
        "mdcContainersAgentlessDiscoveryK8s": {
          "enabled": true
        },
        "mdcContainersImageAssessment": {
          "enabled": true,
          "securityFindingsEnabled": true
        },
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "securityGatingEnabled": true
      },
      {
        "offeringType": "DefenderCspmGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "cspm",
          "serviceAccountEmailAddress": "${CSPM_MONITOR_EMAIL}"
        },
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "dataSensitivityDiscovery": {
          "enabled": true,
          "workloadIdentityProviderId": "data-security-posture-storage",
          "serviceAccountEmailAddress": ${DATA_SENSITIVITY_EMAIL}
        }
      }
    ],
    "environmentName": "GCP",
    "hierarchyIdentifier": "${PROJECT_NUMBER}",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "${project_id}",
        "projectNumber": "${PROJECT_NUMBER}",
        "workloadIdentityPoolId": "${WORKLOAD_IDENTITY_POOL_ID}"
      },
      "organizationalData": {
        "organizationMembershipType": "Member",
        "parentHierarchyId": "${MANAGEMENT_PROJECT}",
        "managementProjectNumber": "${MANAGEMENT_PROJECT_NUMBER}"
      }
    }
  }
}
EOF
}

# Function to get maximum configuration JSON - based on your exact working config
get_maximum_config() {
    local project_id=$1
    cat <<EOF
{
  "location": "eastus",
  "tags": {
    "DefenderTemplate": "maximum",
    "DefenderGroup": "maximum",
    "GcpProject": "${project_id}"
  },
  "properties": {
    "offerings": [
      {
        "offeringType": "CspmMonitorGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "cspm",
          "serviceAccountEmailAddress": "${CSPM_MONITOR_EMAIL}"
        }
      },
      {
        "offeringType": "DefenderCspmGcp",
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "dataSensitivityDiscovery": {
          "enabled": true,
          "workloadIdentityProviderId": "data-security-posture-storage",
          "serviceAccountEmailAddress": "${DATA_SENSITIVITY_EMAIL}"
        },
        "ciemDiscovery": {
          "azureActiveDirectoryAppName": "mciem-gcp-oidc-app",
          "workloadIdentityProviderId": "ciem-discovery",
          "serviceAccountEmailAddress": "${CIEM_DISCOVERY_EMAIL}"
        },
        "mdcContainersImageAssessment": {
          "enabled": true,
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${CONTAINER_IMAGE_ASSESSMENT_EMAIL}"
        },
        "mdcContainersAgentlessDiscoveryK8s": {
          "enabled": true,
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${AGENTLESS_K8S_DISCOVERY_EMAIL}"
        }
      },
      {
        "offeringType": "DefenderForServersGcp",
        "defenderForServers": {
          "workloadIdentityProviderId": "defender-for-servers",
          "serviceAccountEmailAddress": "${DEFENDER_FOR_SERVERS_EMAIL}"
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "mdeAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        },
        "vaAutoProvisioning": {
          "enabled": true,
          "configuration": {
            "type": "TVM"
          }
        },
        "vmScanners": {
          "enabled": true,
          "configuration": {
            "scanningMode": "Default",
            "exclusionTags": {}
          }
        },
        "subPlan": "P2"
      },
      {
        "offeringType": "DefenderForDatabasesGcp",
        "defenderForDatabasesArcAutoProvisioning": {
          "workloadIdentityProviderId": "defender-for-databases-arc-ap",
          "serviceAccountEmailAddress": "${DEFENDER_FOR_DATABASES_EMAIL}"
        },
        "arcAutoProvisioning": {
          "enabled": true,
          "configuration": {}
        }
      },
      {
        "offeringType": "DefenderForContainersGcp",
        "nativeCloudConnection": {
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${CONTAINER_NATIVE_CONNECTION_EMAIL}"
        },
        "dataPipelineNativeCloudConnection": {
          "workloadIdentityProviderId": "containers-streams",
          "serviceAccountEmailAddress": "${CONTAINER_DATA_PIPELINE_EMAIL}"
        },
        "mdcContainersImageAssessment": {
          "enabled": true,
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${CONTAINER_IMAGE_ASSESSMENT_EMAIL}"
        },
        "mdcContainersAgentlessDiscoveryK8s": {
          "enabled": true,
          "workloadIdentityProviderId": "containers",
          "serviceAccountEmailAddress": "${AGENTLESS_K8S_DISCOVERY_EMAIL}"
        },
        "auditLogsAutoProvisioningFlag": true,
        "defenderAgentAutoProvisioningFlag": true,
        "policyAgentAutoProvisioningFlag": true
      }
    ],
    "environmentName": "GCP",
    "hierarchyIdentifier": "${PROJECT_NUMBER}",
    "environmentData": {
      "environmentType": "GcpProject",
      "projectDetails": {
        "projectId": "${project_id}",
        "projectNumber": "${PROJECT_NUMBER}",
        "workloadIdentityPoolId": "${WORKLOAD_IDENTITY_POOL_ID}"
      },
      "organizationalData": {
        "organizationMembershipType": "Member",
        "parentHierarchyId": "${MANAGEMENT_PROJECT}",
        "managementProjectNumber": "${MANAGEMENT_PROJECT_NUMBER}"
      },
      "scanInterval": 12
    }
  }
}
EOF
}

# Function to apply configuration via REST API
apply_config_rest_api() {
    local connector_name=$1
    local config_json=$2
    local temp_file="/tmp/defender_config_${connector_name}.json"

    # Save config to temp file
    echo "$config_json" > "$temp_file"

    # DEBUG: Show what we're sending
    echo "DEBUG: Full config being sent:"
    cat "$temp_file"
    echo "---END CONFIG---"
    echo "DEBUG: Service account emails:"
    grep -n "serviceAccountEmailAddress" "$temp_file"

    # Get access token
    log "Getting Azure access token..."
    local access_token=$(az account get-access-token --query accessToken -o tsv)

    if [ -z "$access_token" ]; then
        error "Failed to get access token"
        rm -f "$temp_file"
        return 1
    fi

    # Apply configuration with more verbose error handling
    log "Applying configuration to connector: $connector_name"

    local url="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Security/securityConnectors/${connector_name}?api-version=2023-10-01-preview"

    # Add verbose curl output to see what's happening
    local response=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X PUT "$url" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d @"$temp_file")

    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    local json_response=$(echo "$response" | sed '/HTTP_CODE:/d')

    echo "DEBUG: HTTP Code: $http_code"
    echo "DEBUG: Response: $json_response" | head -5

    # Check both HTTP code and response content
    if [[ "$http_code" -ge 400 ]] || echo "$json_response" | grep -q '"error"'; then
        error "Failed to apply configuration (HTTP: $http_code):"
        echo "$json_response" | jq '.error' 2>/dev/null || echo "$json_response"
        rm -f "$temp_file"
        return 1
    else
        success "Configuration applied successfully to $connector_name"
        rm -f "$temp_file"
        return 0
    fi
}

# Function to create connector with specific group
create_connector() {
    local connector_name=$1
    local project_id=$2
    local PROJECT_NUMBER=$3
    local new_group=$4

    log "Creating connector '$connector_name' with DefenderGroup: $defender_group"

    case $defender_group in
            "minimal")
                config=$(get_minimal_config "$project_id")
                ;;
            "standard")
                config=$(get_standard_config "$project_id")
                ;;
            "enhanced")
                config=$(get_enhanced_config "$project_id")
                ;;
            "maximum")
                config=$(get_maximum_config "$project_id")
                ;;
            *)
                error "Unknown DefenderGroup: $defender_group"
                echo "Valid options: minimal, standard, enhanced, maximum"
                return 1
                ;;
        esac

    apply_config_rest_api "$connector_name" "$config"
}

# Function to update existing connector
update_connector_group() {
    local connector_name=$1
    local project_id=$2
    local PROJECT_NUMBER=$3
    local new_group=$4

    log "Updating connector '$connector_name' to DefenderGroup: $new_group"

    case $new_group in
            "minimal")
                config=$(get_minimal_config "$project_id")
                ;;
            "standard")
                config=$(get_standard_config "$project_id")
                ;;
            "enhanced")
                config=$(get_enhanced_config "$project_id")
                ;;
            "maximum")
                config=$(get_maximum_config "$project_id")
                ;;
            *)
                error "Unknown DefenderGroup: $new_group"
                echo "Valid options: minimal, standard, enhanced, maximum"
                return 1
                ;;
        esac

    apply_config_rest_api "$connector_name" "$config"
}

# Function to show current connector configuration
show_connector_config() {
    local connector_name=$1

    log "Getting configuration for connector: $connector_name"

    local access_token=$(az account get-access-token --query accessToken -o tsv)
    local url="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Security/securityConnectors/${connector_name}?api-version=2023-10-01-preview"

    local response=$(curl -s -X GET "$url" \
        -H "Authorization: Bearer $access_token")

    if echo "$response" | grep -q '"error"'; then
        error "Failed to get connector configuration"
        echo "$response" | jq '.error' 2>/dev/null || echo "$response"
        return 1
    fi

    echo "📋 Current Configuration:"
    echo "$response" | jq '{
        name: .name,
        location: .location,
        tags: .tags,
        offerings: [.properties.offerings[].offeringType]
    }' 2>/dev/null || echo "$response"
}

# Function to show tags only
show_tags() {
    local connector_name=$1

    log "Getting tags for connector: $connector_name"

    az resource show \
        --name "$connector_name" \
        --resource-group "$RESOURCE_GROUP" \
        --resource-type "Microsoft.Security/securityConnectors" \
        --query "tags" \
        --output json
}

# Function to list all connectors with their groups
list_all_connectors() {
    log "Listing all Defender for Cloud connectors..."

    az resource list \
        --resource-type "Microsoft.Security/securityConnectors" \
        --subscription "$SUBSCRIPTION_ID" \
        --query "[].{Name:name, ResourceGroup:resourceGroup, DefenderGroup:tags.DefenderGroup, Environment:tags.Environment}" \
        --output table
}

# Function to show cost estimates
show_cost_estimate() {
    local defender_group=$1
    local vm_count=${2:-10}

    echo ""
    echo "💰 Cost Estimate for DefenderGroup: $defender_group"
    echo "================================================"

    case $defender_group in
        "minimal")
            base_cost=50
            per_vm_cost=7
            features="• CSPM Monitoring only"
            ;;
        "standard")
            base_cost=100
            per_vm_cost=20
            features="• CSPM Monitoring
• Defender for Servers P1
• Basic VM scanning
• Arc auto-provisioning"
            ;;
        "enhanced")
            base_cost=150
            per_vm_cost=37
            features="• CSPM Monitoring
• Defender for Servers P2
• Defender for Databases
• Defender for Containers (full)
• Advanced threat protection
• Vulnerability assessment
• Data sensitivity discovery"
            ;;
        "maximum")
            base_cost=250
            per_vm_cost=65
            features="• All Enhanced features PLUS:
• CIEM Discovery
• Container Image Assessment
• Agentless K8s Discovery
• Data sensitivity discovery"
            ;;
        *)
            error "Unknown DefenderGroup: $defender_group"
            return 1
            ;;
    esac

    total_cost=$((base_cost + (per_vm_cost * vm_count)))
    annual_cost=$((total_cost * 12))

    echo "Base cost: \$${base_cost}/month"
    echo "Per VM cost: \$${per_vm_cost}/month"
    echo "VMs: $vm_count"
    echo "----------------------------------------"
    echo "Total monthly: \$${total_cost}"
    echo "Total annual: \$${annual_cost}"
    echo ""
    echo "Features included:"
    echo "$features"
    echo ""
}

# Function to bulk update connectors
bulk_update_connectors() {
    local defender_group=$1
    local pattern=$2

    log "Bulk updating connectors matching pattern '$pattern' to DefenderGroup: $defender_group"

    # Get list of connectors matching pattern
    local connectors=$(az resource list \
        --resource-type "Microsoft.Security/securityConnectors" \
        --subscription "$SUBSCRIPTION_ID" \
        --query "[?contains(name, '$pattern')].{name:name, resourceGroup:resourceGroup}" \
        --output json)

    if [ "$connectors" == "[]" ]; then
        warning "No connectors found matching pattern: $pattern"
        return 1
    fi

    # Update each connector
    echo "$connectors" | jq -r '.[] | "\(.name)|\(.resourceGroup)"' | while IFS='|' read -r name rg; do
        log "Updating connector: $name in resource group: $rg"
        # Assuming project ID can be extracted from connector name or use default
        local project_id="metal-center-264116"  # Update this logic as needed
        update_connector_group "$name" "$project_id" "$defender_group"
    done
}

# Main function
main() {
    case "${1:-help}" in
        "create")
            if [ $# -lt 4 ]; then
                error "Usage: $0 create <connector_name> <project_id> <defender_group>"
                echo "Example: $0 create MyConnector metal-center-264116 maximum"
                exit 1
            fi
            create_connector "$2" "$3" "$4"
            ;;
        "update")
            if [ $# -lt 5 ]; then
                error "Usage: $0 update <connector_name> <project_id> <project_number> <new_group>"
                echo "Example: $0 update DefenderTesting_metal-center-264116 metal-center-264116 939216070880 maximum"
                exit 1
            fi
            update_connector_group "$2" "$3" "$4" "$5"
            ;;
        "show")
            if [ $# -lt 2 ]; then
                error "Usage: $0 show <connector_name>"
                echo "Example: $0 show DefenderTesting_metal-center-264116"
                exit 1
            fi
            show_connector_config "$2"
            ;;
        "tags")
            if [ $# -lt 2 ]; then
                error "Usage: $0 tags <connector_name>"
                echo "Example: $0 tags DefenderTesting_metal-center-264116"
                exit 1
            fi
            show_tags "$2"
            ;;
        "list")
            list_all_connectors
            ;;
        "cost")
            if [ $# -lt 2 ]; then
                error "Usage: $0 cost <defender_group> [vm_count]"
                echo "Example: $0 cost maximum 15"
                exit 1
            fi
            show_cost_estimate "$2" "${3:-10}"
            ;;
        "bulk")
            if [ $# -lt 3 ]; then
                error "Usage: $0 bulk <defender_group> <name_pattern>"
                echo "Example: $0 bulk maximum 'test'"
                exit 1
            fi
            bulk_update_connectors "$2" "$3"
            ;;
        "help"|*)
            echo "Defender for Cloud Feature Group Management"
            echo "=========================================="
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  create <name> <project_id> <group>   Create new connector with specific group"
            echo "  update <name> <project_id> <group>   Update existing connector group"
            echo "  show <name>                          Show connector configuration"
            echo "  tags <name>                          Show connector tags only"
            echo "  list                                 List all connectors with groups"
            echo "  cost <group> [vm_count]              Show cost estimate for group"
            echo "  bulk <group> <pattern>               Bulk update connectors by name pattern"
            echo "  demo                                 Generate demo script"
            echo "  help                                 Show this help"
            echo ""
            echo "Defender Groups: minimal, standard, enhanced, maximum"
            echo ""
            echo "Examples:"
            echo "  $0 create TestConnector metal-center-264116 maximum"
            echo "  $0 update DefenderTesting_metal-center-264116 metal-center-264116 maximum"
            echo "  $0 tags DefenderTesting_metal-center-264116"
            echo "  $0 cost maximum 20"
            echo "  $0 list"
            ;;
    esac
}

# Run main function with all arguments
main "$@"