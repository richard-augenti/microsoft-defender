Microsoft Defender for Cloud - GCP Enablement Scripts
Automate enabling Microsoft Defender for Cloud services on GCP projects through REST API calls.
Prerequisites

Azure CLI (az) installed and authenticated (az login)
jq for JSON processing
curl for API calls
Existing GCP security connector with workload identity federation configured
Required GCP service accounts and workload identity providers already set up

Scripts Overview
1. enable-cspm.sh
Enables basic CSPM (Cloud Security Posture Management) monitoring only.
What it enables:

CspmMonitorGcp - Free foundational security posture monitoring

Use case: New projects that only need basic compliance monitoring without paid features.
2. enable-all-defender.sh
Enables comprehensive protection across all Defender offerings.
What it enables:

CspmMonitorGcp - Basic CSPM monitoring
DefenderCspmGcp - Advanced CSPM with VM scanning, CIEM, data sensitivity discovery
DefenderForContainersGcp - Container security with image assessment, agentless discovery, audit logs
DefenderForDatabasesGcp - Database protection with Arc auto-provisioning

Use case: Production projects requiring maximum security coverage.
3. get-connector-info.sh
Retrieves connector details to simplify command construction.
What it does:

Queries existing connector to extract project ID and hierarchy identifier
Generates ready-to-use CLI commands for other scripts

Use case: When you know the connector name but need to look up project details.
Configuration
config.json
Update with your environment-specific values:
json{
  "azure": {
    "subscriptionId": "your-subscription-id",
    "resourceGroup": "your-resource-group", 
    "apiVersion": "2025-08-01-preview",
    "location": "eastus"
  },
  "gcp": {
    "workloadIdentityPoolId": "your-pool-id",
    "organizationalData": {
      "organizationMembershipType": "Member",
      "parentHierarchyId": "parent-hierarchy-id",
      "managementProjectNumber": "mgmt-project-number"
    },
    "scanInterval": 12
  },
  "serviceAccounts": {
    "cspmMonitor": "microsoft-defender-cspm@mgmt-project.iam.gserviceaccount.com"
  },
  "workloadIdentityProviders": {
    "cspm": "csmp",
    "containers": "containers", 
    "containersStreams": "containers-streams",
    "databasesArc": "defender-for-databases-arc-ap"
  }
}
Usage
Get Connector Information
bashchmod +x get-connector-info.sh
./get-connector-info.sh GCP_my-project
Output:
Connector Name: GCP_my-project
Project ID: my-project-123
Hierarchy ID: 123456789012

CLI Command:
./enable-all-defender.sh --connector GCP_my-project --project my-project-123 --hierarchy 123456789012
Basic CSPM Only
bashchmod +x enable-cspm.sh
./enable-cspm.sh --connector GCP_my-project --project my-project-123 --hierarchy 123456789012
Full Protection Suite
bashchmod +x enable-all-defender.sh  
./enable-all-defender.sh --connector GCP_my-project --project my-project-123 --hierarchy 123456789012
Simplified Workflow
Instead of manually specifying project details, use the info script first:
bash# Step 1: Get connector details
./get-connector-info.sh GCP_my-project

# Step 2: Copy and run the generated command
./enable-all-defender.sh --connector GCP_my-project --project my-project-123 --hierarchy 123456789012
Arguments
ArgumentDescriptionExample--connectorGCP security connector name in AzureGCP_my-project--projectGCP project IDmy-project-123--hierarchyGCP project number123456789012
Cost Considerations

enable-cspm.sh: Only enables free CSPM monitoring
enable-all-defender.sh: Enables multiple paid services that will increase Azure billing

Review Defender for Cloud pricing before running the full enablement script.
Prerequisites Setup
Before using these scripts, ensure you have:

GCP Workload Identity Federation configured between Azure and GCP
Service accounts created in your GCP project with appropriate permissions
Security connector already created in Azure (can be basic/empty initially)
Proper IAM roles in both Azure and GCP for the operation

Troubleshooting
Authentication errors: Verify az login is completed and token is valid
Service account errors: Ensure all required service accounts exist in the target GCP project
Permission errors: Check that your Azure account has Security Admin role on the subscription
Workload identity errors: Verify the workload identity pool and providers are correctly configured
Security Notes

Scripts use Azure CLI authentication tokens (1-hour expiration)
All sensitive configuration is externalized to config.json
No credentials are hardcoded in the scripts
API calls use HTTPS with proper authorization headers

Contributing
When contributing, ensure:

No hardcoded credentials or project-specific values
Proper error handling and logging
Configuration remains externalized
Scripts work across different GCP project configurations