#!/usr/bin/env python3
"""
Defender for Cloud Feature Group Automation
Automatically applies security configurations based on DefenderGroup tags
"""

import json
import subprocess
import sys
from typing import Dict, List, Optional
import argparse
from pathlib import Path


class DefenderGroupManager:
    """Manages Defender for Cloud configurations based on tags"""

    def __init__(self, config_file: str = "config.json"):
        self.config_file = config_file
        self.config = self._load_config()
        self.feature_profiles = {
            "minimal": self._get_minimal_config(),
            "standard": self._get_standard_config(),
            "enhanced": self._get_enhanced_config(),
            "maximum": self._get_maximum_config()
        }

    def _load_config(self) -> Dict:
        """Load configuration from JSON file"""
        config_path = Path(self.config_file)

        if not config_path.exists():
            print(f"❌ Configuration file not found: {self.config_file}")
            print("Make sure config.json exists in the same directory")
            sys.exit(1)

        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in config file: {e}")
            sys.exit(1)

    def _get_config_value(self, key: str):
        """Get configuration value from defaults"""
        return self.config["defaults"][key]

    def _get_service_account(self, service_type: str):
        """Get service account email from config"""
        return self.config["defaults"]["serviceAccounts"][service_type]

    def _get_minimal_config(self) -> Dict:
        """Basic security configuration for dev/test workloads"""
        return {
            "location": "eastus",
            "tags": {
                "Environment": "Development",
                "ProjectName": self._get_config_value("projectId"),
                "CostCenter": "IT-Security",
                "Owner": "cloud@company.com",
                "DefenderTemplate": "minimal",
                "DefenderGroup": "minimal",
                "GcpProject": self._get_config_value("projectId"),
                "BusinessUnit": "Engineering",
                "SecurityProfile": "basic"
            },
            "properties": {
                "offerings": [
                    {
                        "offeringType": "CspmMonitorGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "cspm",
                            "serviceAccountEmailAddress": self._get_service_account("cspmMonitor")
                        }
                    }
                ],
                "environmentName": "GCP",
                "hierarchyIdentifier": self._get_config_value("projectNumber"),
                "environmentData": {
                    "environmentType": "GcpProject",
                    "projectDetails": {
                        "projectId": self._get_config_value("projectId"),
                        "projectNumber": self._get_config_value("projectNumber"),
                        "workloadIdentityPoolId": self._get_config_value("workloadIdentityPoolId")
                    },
                    "organizationalData": {
                        "organizationMembershipType": "Member",
                        "parentHierarchyId": self._get_config_value("managementProject"),
                        "managementProjectNumber": self._get_config_value("managementProjectNumber")
                    }
                }
            }
        }

    def _get_standard_config(self) -> Dict:
        """Standard production configuration with basic threat protection"""
        return {
            "location": "eastus",
            "tags": {
                "Environment": "Staging",
                "ProjectName": self._get_config_value("projectId"),
                "CostCenter": "IT-Security",
                "Owner": "cloud@company.com",
                "DefenderTemplate": "standard",
                "DefenderGroup": "standard",
                "GcpProject": self._get_config_value("projectId"),
                "BusinessUnit": "Engineering",
                "SecurityProfile": "production-ready"
            },
            "properties": {
                "offerings": [
                    {
                        "offeringType": "CspmMonitorGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "cspm",
                            "serviceAccountEmailAddress": self._get_service_account("cspmMonitor")
                        }
                    },
                    {
                        "offeringType": "DefenderForServersGcp",
                        "defenderForServers": {
                            "workloadIdentityProviderId": "defender-for-servers",
                            "serviceAccountEmailAddress": self._get_service_account("defenderForServers")
                        },
                        "arcAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        },
                        "vmScanners": {
                            "enabled": True,
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
                            "enabled": True,
                            "configuration": {
                                "scanningMode": "Default",
                                "exclusionTags": {}
                            }
                        }
                    }
                ],
                "environmentName": "GCP",
                "hierarchyIdentifier": self._get_config_value("projectNumber"),
                "environmentData": {
                    "environmentType": "GcpProject",
                    "projectDetails": {
                        "projectId": self._get_config_value("projectId"),
                        "projectNumber": self._get_config_value("projectNumber"),
                        "workloadIdentityPoolId": self._get_config_value("workloadIdentityPoolId")
                    },
                    "organizationalData": {
                        "organizationMembershipType": "Member",
                        "parentHierarchyId": self._get_config_value("managementProject"),
                        "managementProjectNumber": self._get_config_value("managementProjectNumber")
                    }
                }
            }
        }

    def _get_enhanced_config(self) -> Dict:
        """Enhanced configuration for critical production workloads"""
        return {
            "location": "eastus",
            "tags": {
                "Environment": "Production",
                "ProjectName": self._get_config_value("projectId"),
                "CostCenter": "IT-Security",
                "Owner": "cloud@company.com",
                "DefenderTemplate": "enhanced",
                "DefenderGroup": "enhanced",
                "GcpProject": self._get_config_value("projectId"),
                "BusinessUnit": "Engineering",
                "SecurityProfile": "critical-production",
                "ComplianceLevel": "SOC2"
            },
            "properties": {
                "offerings": [
                    {
                        "offeringType": "CspmMonitorGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "cspm",
                            "serviceAccountEmailAddress": self._get_service_account("cspmMonitor")
                        }
                    },
                    {
                        "offeringType": "DefenderForServersGcp",
                        "defenderForServers": {
                            "workloadIdentityProviderId": "defender-for-servers",
                            "serviceAccountEmailAddress": self._get_service_account("defenderForServers")
                        },
                        "arcAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        },
                        "mdeAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        },
                        "vaAutoProvisioning": {
                            "enabled": True,
                            "configuration": {
                                "type": "TVM"
                            }
                        },
                        "vmScanners": {
                            "enabled": True,
                            "configuration": {
                                "scanningMode": "Default",
                                "exclusionTags": {}
                            }
                        },
                        "subPlan": "P2"
                    },
                    {
                        "offeringType": "DefenderCspmGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "cspm",
                            "serviceAccountEmailAddress": self._get_service_account("cspmMonitor")
                        },
                        "vmScanners": {
                            "enabled": True,
                            "configuration": {
                                "scanningMode": "Default",
                                "exclusionTags": {}
                            }
                        },
                        "dataSensitivityDiscovery": {
                            "enabled": True,
                            "workloadIdentityProviderId": "data-security-posture-storage",
                            "serviceAccountEmailAddress": self._get_service_account("dataSensitivityDiscovery")
                        }
                    }
                ],
                "environmentName": "GCP",
                "hierarchyIdentifier": self._get_config_value("projectNumber"),
                "environmentData": {
                    "environmentType": "GcpProject",
                    "projectDetails": {
                        "projectId": self._get_config_value("projectId"),
                        "projectNumber": self._get_config_value("projectNumber"),
                        "workloadIdentityPoolId": self._get_config_value("workloadIdentityPoolId")
                    },
                    "organizationalData": {
                        "organizationMembershipType": "Member",
                        "parentHierarchyId": self._get_config_value("managementProject"),
                        "managementProjectNumber": self._get_config_value("managementProjectNumber")
                    }
                }
            }
        }

    def _get_maximum_config(self) -> Dict:
        """Maximum security configuration for highly sensitive workloads"""
        return {
            "location": "eastus",
            "tags": {
                "Environment": "Critical-Production",
                "ProjectName": self._get_config_value("projectId"),
                "CostCenter": "IT-Security",
                "Owner": "cloud@company.com",
                "DefenderTemplate": "maximum",
                "DefenderGroup": "maximum",
                "GcpProject": self._get_config_value("projectId"),
                "BusinessUnit": "Engineering",
                "SecurityProfile": "maximum-security",
                "ComplianceLevel": "highest",
                "DataClassification": "restricted"
            },
            "properties": {
                "offerings": [
                    {
                        "offeringType": "CspmMonitorGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "cspm",
                            "serviceAccountEmailAddress": self._get_service_account("cspmMonitor")
                        }
                    },
                    {
                        "offeringType": "DefenderCspmGcp",
                        "vmScanners": {
                            "enabled": True,
                            "configuration": {
                                "scanningMode": "Default",
                                "exclusionTags": {}
                            }
                        },
                        "dataSensitivityDiscovery": {
                            "enabled": True,
                            "workloadIdentityProviderId": "data-security-posture-storage",
                            "serviceAccountEmailAddress": self._get_service_account("dataSensitivityDiscovery")
                        },
                        "ciemDiscovery": {
                            "azureActiveDirectoryAppName": "mciem-gcp-oidc-app",
                            "workloadIdentityProviderId": "ciem-discovery",
                            "serviceAccountEmailAddress": self._get_service_account("ciemDiscovery")
                        },
                        "mdcContainersImageAssessment": {
                            "enabled": True,
                            "workloadIdentityProviderId": "containers",
                            "serviceAccountEmailAddress": self._get_service_account("containerImageAssessment")
                        },
                        "mdcContainersAgentlessDiscoveryK8s": {
                            "enabled": True,
                            "workloadIdentityProviderId": "containers",
                            "serviceAccountEmailAddress": self._get_service_account("agentlessK8sDiscovery")
                        }
                    },
                    {
                        "offeringType": "DefenderForServersGcp",
                        "defenderForServers": {
                            "workloadIdentityProviderId": "defender-for-servers",
                            "serviceAccountEmailAddress": self._get_service_account("defenderForServers")
                        },
                        "arcAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        },
                        "mdeAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        },
                        "vaAutoProvisioning": {
                            "enabled": True,
                            "configuration": {
                                "type": "TVM"
                            }
                        },
                        "vmScanners": {
                            "enabled": True,
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
                            "serviceAccountEmailAddress": self._get_service_account("defenderForDatabases")
                        },
                        "arcAutoProvisioning": {
                            "enabled": True,
                            "configuration": {}
                        }
                    },
                    {
                        "offeringType": "DefenderForContainersGcp",
                        "nativeCloudConnection": {
                            "workloadIdentityProviderId": "containers",
                            "serviceAccountEmailAddress": self._get_service_account("containerNativeConnection")
                        },
                        "dataPipelineNativeCloudConnection": {
                            "workloadIdentityProviderId": "containers-streams",
                            "serviceAccountEmailAddress": self._get_service_account("containerDataPipeline")
                        },
                        "mdcContainersImageAssessment": {
                            "enabled": True,
                            "workloadIdentityProviderId": "containers",
                            "serviceAccountEmailAddress": self._get_service_account("containerImageAssessment")
                        },
                        "mdcContainersAgentlessDiscoveryK8s": {
                            "enabled": True,
                            "workloadIdentityProviderId": "containers",
                            "serviceAccountEmailAddress": self._get_service_account("agentlessK8sDiscovery")
                        },
                        "auditLogsAutoProvisioningFlag": True,
                        "defenderAgentAutoProvisioningFlag": True,
                        "policyAgentAutoProvisioningFlag": True
                    }
                ],
                "environmentName": "GCP",
                "hierarchyIdentifier": self._get_config_value("projectNumber"),
                "environmentData": {
                    "environmentType": "GcpProject",
                    "projectDetails": {
                        "projectId": self._get_config_value("projectId"),
                        "projectNumber": self._get_config_value("projectNumber"),
                        "workloadIdentityPoolId": self._get_config_value("workloadIdentityPoolId")
                    },
                    "organizationalData": {
                        "organizationMembershipType": "Member",
                        "parentHierarchyId": self._get_config_value("managementProject"),
                        "managementProjectNumber": self._get_config_value("managementProjectNumber")
                    }
                }
            }
        }

    def get_connector_tags(self, subscription_id: str, resource_group: str, connector_name: str) -> Optional[Dict]:
        """Get current tags from a Defender connector"""
        try:
            cmd = [
                "az", "resource", "show",
                "--name", connector_name,
                "--resource-group", resource_group,
                "--resource-type", "Microsoft.Security/securityConnectors",
                "--subscription", subscription_id,
                "--query", "tags",
                "-o", "json"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return json.loads(result.stdout) if result.stdout.strip() != "null" else {}
        except subprocess.CalledProcessError as e:
            print(f"Error getting connector tags: {e}")
            return None

    def apply_configuration(self, subscription_id: str, resource_group: str,
                            connector_name: str, defender_group: str,
                            additional_tags: Optional[Dict] = None) -> bool:
        """Apply configuration based on DefenderGroup tag using REST API"""

        if defender_group not in self.feature_profiles:
            print(
                f"Error: Unknown DefenderGroup '{defender_group}'. Valid options: {list(self.feature_profiles.keys())}")
            return False

        # Get base configuration for the group
        config = self.feature_profiles[defender_group].copy()

        # Merge additional tags if provided
        if additional_tags:
            config["tags"].update(additional_tags)

        # Add DefenderGroup tag
        config["tags"]["DefenderGroup"] = defender_group

        # Create temporary file for configuration
        config_file = f"/tmp/defender_config_{connector_name}.json"
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)

        try:
            # Get access token
            token_cmd = ["az", "account", "get-access-token", "--query", "accessToken", "-o", "tsv"]
            token_result = subprocess.run(token_cmd, capture_output=True, text=True, check=True)
            access_token = token_result.stdout.strip()

            # Apply configuration using REST API
            url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Security/securityConnectors/{connector_name}?api-version=2023-10-01-preview"

            curl_cmd = [
                "curl", "-s", "-X", "PUT", url,
                "-H", f"Authorization: Bearer {access_token}",
                "-H", "Content-Type: application/json",
                "-H", "Accept: application/json",
                "-d", f"@{config_file}"
            ]

            result = subprocess.run(curl_cmd, capture_output=True, text=True, check=True)

            # Check if response contains error
            try:
                response_json = json.loads(result.stdout)
                if "error" in response_json:
                    print(f"❌ Error applying configuration: {response_json['error']}")
                    return False
            except json.JSONDecodeError:
                pass  # Response might not be JSON

            print(f"✅ Successfully applied '{defender_group}' configuration to {connector_name}")
            return True

        except subprocess.CalledProcessError as e:
            print(f"❌ Error applying configuration: {e}")
            if e.stderr:
                print(f"Error output: {e.stderr}")
            return False
        finally:
            # Clean up temp file
            try:
                import os
                os.remove(config_file)
            except:
                pass

    def list_connectors_by_group(self, subscription_id: str) -> Dict[str, List[str]]:
        """List all connectors grouped by DefenderGroup tag"""
        try:
            cmd = [
                "az", "resource", "list",
                "--resource-type", "Microsoft.Security/securityConnectors",
                "--subscription", subscription_id,
                "--query", "[].{name:name, group:tags.DefenderGroup, resourceGroup:resourceGroup}",
                "-o", "json"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            connectors = json.loads(result.stdout)

            grouped = {}
            for connector in connectors:
                group = connector.get("group", "untagged")
                if group not in grouped:
                    grouped[group] = []
                grouped[group].append(f"{connector['name']} ({connector['resourceGroup']})")

            return grouped

        except subprocess.CalledProcessError as e:
            print(f"Error listing connectors: {e}")
            return {}

    def validate_configuration(self, defender_group: str) -> bool:
        """Validate a configuration before applying"""
        if defender_group not in self.feature_profiles:
            return False

        config = self.feature_profiles[defender_group]

        # Basic validation
        required_fields = ["location", "tags", "properties"]
        for field in required_fields:
            if field not in config:
                print(f"Missing required field: {field}")
                return False

        # Validate offerings
        if "offerings" not in config["properties"]:
            print("Missing offerings in configuration")
            return False

        print(f"✅ Configuration for '{defender_group}' is valid")
        return True

    def show_cost_estimate(self, defender_group: str, vm_count: int = 10) -> None:
        """Show estimated monthly costs for a configuration"""
        cost_matrix = {
            "minimal": {"per_vm": 7, "base": 50},
            "standard": {"per_vm": 20, "base": 100},
            "enhanced": {"per_vm": 37, "base": 150},
            "maximum": {"per_vm": 65, "base": 250}
        }

        if defender_group in cost_matrix:
            costs = cost_matrix[defender_group]
            total_cost = (costs["per_vm"] * vm_count) + costs["base"]

            print(f"\n💰 Cost Estimate for '{defender_group}' profile:")
            print(f"   Base cost: ${costs['base']}/month")
            print(f"   Per VM: ${costs['per_vm']}/month")
            print(f"   Total for {vm_count} VMs: ${total_cost}/month")
            print(f"   Annual cost: ${total_cost * 12}/year")

    def show_configuration_comparison(self) -> None:
        """Show side-by-side comparison of all profiles"""
        print("\n🔍 DefenderGroup Configuration Comparison")
        print("=" * 60)
        print(f"{'Feature':<20} {'Minimal':<10} {'Standard':<10} {'Enhanced':<10} {'Maximum':<10}")
        print("-" * 60)
        print(f"{'CSPM Basic':<20} {'✅':<10} {'✅':<10} {'✅':<10} {'✅':<10}")
        print(f"{'Servers P1':<20} {'❌':<10} {'✅':<10} {'❌':<10} {'❌':<10}")
        print(f"{'Servers P2':<20} {'❌':<10} {'❌':<10} {'✅':<10} {'✅':<10}")
        print(f"{'Advanced CSPM':<20} {'❌':<10} {'❌':<10} {'✅':<10} {'✅':<10}")
        print(f"{'Data Discovery':<20} {'❌':<10} {'❌':<10} {'✅':<10} {'✅':<10}")
        print(f"{'Advanced Features':<20} {'❌':<10} {'❌':<10} {'❌':<10} {'✅':<10}")
        print(f"{'Monthly Cost*':<20} {'$120':<10} {'$300':<10} {'$520':<10} {'$900':<10}")
        print("\n* Cost estimates for 10 VMs")


def main():
    parser = argparse.ArgumentParser(description="Manage Defender for Cloud configurations based on tags")
    parser.add_argument("--config", default="config.json", help="Configuration file path")
    parser.add_argument("--subscription-id", help="Azure subscription ID (overrides config)")
    parser.add_argument("--resource-group", help="Resource group name")
    parser.add_argument("--connector-name", help="Connector name")
    parser.add_argument("--defender-group", choices=["minimal", "standard", "enhanced", "maximum"],
                        help="Security profile to apply")
    parser.add_argument("--action", choices=["apply", "list", "validate", "cost", "compare"], required=True,
                        help="Action to perform")
    parser.add_argument("--vm-count", type=int, default=10, help="Number of VMs for cost estimation")

    args = parser.parse_args()

    manager = DefenderGroupManager(args.config)

    # Use subscription ID from command line or config
    subscription_id = args.subscription_id or manager._get_config_value("subscriptionId")

    if args.action == "apply":
        if not all([args.resource_group, args.connector_name, args.defender_group]):
            print("Error: apply action requires --resource-group, --connector-name, and --defender-group")
            sys.exit(1)

        # Get existing tags to preserve them
        existing_tags = manager.get_connector_tags(subscription_id, args.resource_group, args.connector_name)
        if existing_tags is None:
            print("Warning: Could not retrieve existing tags, proceeding without them")
            existing_tags = {}

        success = manager.apply_configuration(
            subscription_id,
            args.resource_group,
            args.connector_name,
            args.defender_group,
            existing_tags
        )
        sys.exit(0 if success else 1)

    elif args.action == "list":
        grouped = manager.list_connectors_by_group(subscription_id)
        print("\n📋 Connectors by DefenderGroup:")
        for group, connectors in grouped.items():
            print(f"\n{group.upper()}:")
            for connector in connectors:
                print(f"  • {connector}")

    elif args.action == "validate":
        if not args.defender_group:
            print("Error: validate action requires --defender-group")
            sys.exit(1)

        is_valid = manager.validate_configuration(args.defender_group)
        sys.exit(0 if is_valid else 1)

    elif args.action == "cost":
        if not args.defender_group:
            print("Error: cost action requires --defender-group")
            sys.exit(1)

        manager.show_cost_estimate(args.defender_group, args.vm_count)

    elif args.action == "compare":
        manager.show_configuration_comparison()


if __name__ == "__main__":
    main()