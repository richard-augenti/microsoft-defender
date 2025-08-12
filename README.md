# Defender for Cloud Automation Toolkit

Automate Microsoft Defender for Cloud deployments across GCP environments with predefined security profiles.

## 🚀 Quick Start

### 1. Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **jq** for JSON processing (`sudo apt install jq` or `brew install jq`)
- **curl** for API calls
- **Python 3.7+** (for Python script)
- **Permissions**: Contributor access to Azure subscription and Security Admin role

### 2. Setup Configuration

Create your `config.json` file with your environment details:

```bash
cp config.json.template config.json
# Edit config.json with your values
```

**Required Configuration:**
```json
{
  "defaults": {
    "subscriptionId": "your-azure-subscription-id",
    "resourceGroup": "your-resource-group",
    "managementProject": "your-gcp-management-project-id",
    "projectId": "your-gcp-project-id",
    "projectNumber": "your-gcp-project-number",
    "workloadIdentityPoolId": "your-workload-identity-pool-id",
    "managementProjectNumber": "your-management-project-number",
    "serviceAccounts": {
      "cspmMonitor": "microsoft-defender-cspm@mdc-mgmt-proj-XXXX.iam.gserviceaccount.com",
      "defenderForServers": "microsoft-defender-for-servers@your-project.iam.gserviceaccount.com",
      ...
    }
  }
}
```

### 3. Find Your Values

**Azure Values:**
```bash
# Subscription ID
az account show --query id -o tsv

# Resource Group (where Defender connectors are created)
az group list --query "[].name" -o table
```

**GCP Values:**
```bash
# Project ID
gcloud config get-value project

# Project Number
gcloud projects describe YOUR_PROJECT_ID --format="value(projectNumber)"

# Management Project (usually your organization's central security project)
# Check your existing Defender connector or ask your GCP admin
```

## 📋 Available Security Profiles

| Profile | Use Case | Monthly Cost* | Features |
|---------|----------|---------------|----------|
| **minimal** | Development/Testing | ~$120 | CSPM monitoring only |
| **standard** | Staging environments | ~$300 | CSPM + Servers P1 + Basic scanning |
| **enhanced** | Production workloads | ~$520 | Full protection: Servers P2, Databases, Containers |
| **maximum** | Critical/Regulated | ~$900 | Enhanced + CIEM, Data discovery, Advanced scanning |

*Cost estimates for 10 VMs

## 🛠️ Usage

### Shell Script (Recommended)

```bash
# Check costs before deploying
./defender_management.sh cost maximum 20

# Deploy maximum security to a connector
./defender_management.sh update \
  DefenderConnector_MyProject \
  my-gcp-project-id \
  maximum

# List all connectors and their current plans
./defender_management.sh list

# Show current configuration
./defender_management.sh show DefenderConnector_MyProject
```

### Python Script (Advanced)

```bash
# Cost comparison
python3 defender_manager.py --action compare

# Apply configuration
python3 defender_manager.py \
  --action apply \
  --resource-group my-resource-group \
  --connector-name MyConnector \
  --defender-group enhanced

# Validate configuration
python3 defender_manager.py --action validate --defender-group maximum
```

## 📁 File Structure

```
defender-toolkit/
├── defender_management.sh       # Main shell script
├── defender_manager.py          # Python script (advanced features)
├── config.json                  # Your environment configuration
├── config.json.template         # Template for new setups
└── README.md                    # This file
```

## 🔧 Commands Reference

### Shell Script Commands

| Command | Description | Example |
|---------|-------------|---------|
| `update` | Apply security profile to connector | `./defender_management.sh update ConnectorName project-id maximum` |
| `show` | Display current connector config | `./defender_management.sh show ConnectorName` |
| `list` | List all connectors with their plans | `./defender_management.sh list` |
| `cost` | Show cost estimate for plan | `./defender_management.sh cost enhanced 15` |
| `tags` | Show connector tags only | `./defender_management.sh tags ConnectorName` |

### Python Script Actions

| Action | Description | Example |
|---------|-------------|---------|
| `apply` | Deploy configuration | `--action apply --defender-group maximum` |
| `list` | List connectors by group | `--action list` |
| `cost` | Cost estimation | `--action cost --defender-group enhanced --vm-count 20` |
| `compare` | Feature comparison table | `--action compare` |
| `validate` | Validate configuration | `--action validate --defender-group maximum` |

## 💡 Common Use Cases

### New Environment Setup
```bash
# 1. Check costs
./defender_management.sh cost enhanced 10

# 2. Apply configuration
./defender_management.sh update MyConnector my-project-id enhanced

# 3. Verify deployment
./defender_management.sh show MyConnector
```

### Upgrade Security Level
```bash
# Upgrade from standard to maximum
./defender_management.sh update ExistingConnector my-project-id maximum
```

### Cost Analysis
```bash
# Compare costs for different VM counts
./defender_management.sh cost minimal 5
./defender_management.sh cost standard 5
./defender_management.sh cost enhanced 5
./defender_management.sh cost maximum 5
```

## 🎯 Security Profile Details

### Minimal Profile
- **Purpose**: Development and testing environments
- **Features**: Basic CSPM monitoring
- **Cost**: ~$7/VM + $50 base
- **Best for**: Non-production workloads

### Standard Profile  
- **Purpose**: Staging and pre-production
- **Features**: CSPM + Defender for Servers P1 + Basic VM scanning
- **Cost**: ~$20/VM + $100 base
- **Best for**: Staging environments with moderate security needs

### Enhanced Profile
- **Purpose**: Production workloads
- **Features**: Full protection suite including Servers P2, Databases, Containers
- **Cost**: ~$37/VM + $150 base
- **Best for**: Business-critical production systems

### Maximum Profile
- **Purpose**: Highly regulated and critical systems
- **Features**: Everything + CIEM discovery, Data sensitivity, Advanced scanning
- **Cost**: ~$65/VM + $250 base
- **Best for**: Financial services, healthcare, government

## 🔍 Troubleshooting

### Common Issues

**"Configuration file not found"**
```bash
# Make sure config.json exists
ls -la config.json
# Copy from template if needed
cp config.json.template config.json
```

**"Failed to get access token"**
```bash
# Re-authenticate with Azure
az login
az account set --subscription "your-subscription-id"
```

**"HTTP 400: Body validation failed"**
- Check your service account email formats in config.json
- Ensure all required fields are present
- Validate JSON syntax: `cat config.json | jq .`

**"Unknown DefenderGroup"**
- Valid options: `minimal`, `standard`, `enhanced`, `maximum`
- Check spelling and case sensitivity

### Validation Commands

```bash
# Test Azure connectivity
az account show

# Test GCP project access
gcloud projects describe YOUR_PROJECT_ID

# Validate JSON syntax
cat config.json | jq .

# Test script with dry run
./defender_management.sh cost minimal 1
```

## 🔐 Security Considerations

- **Least Privilege**: Use service accounts with minimal required permissions
- **Credential Management**: Never commit config.json with real values to version control
- **Environment Separation**: Use different config files for dev/staging/prod
- **Regular Reviews**: Periodically review and update security configurations

## 📚 Additional Resources

- [Microsoft Defender for Cloud Documentation](https://docs.microsoft.com/en-us/azure/defender-for-cloud/)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Azure Security Connector API Reference](https://docs.microsoft.com/en-us/rest/api/defenderforcloud/)

## 🆘 Support

For issues or questions:

1. **Check the troubleshooting section** above
2. **Validate your configuration** using the validation commands
3. **Review Azure and GCP permissions**
4. **Check service account email formats**

## 📝 License

This toolkit is provided as-is for automation of Microsoft Defender for Cloud deployments. Ensure compliance with your organization's security policies and Microsoft's licensing terms.

---

**⚠️ Important**: Always test in a development environment before applying to production systems. Monitor costs closely as Defender for Cloud charges can accumulate quickly with higher security profiles.