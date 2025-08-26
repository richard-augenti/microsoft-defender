# Setting The Environment Variables
MgmtProjectId="mdc-mgmt-proj-$(date +%Y%m%d%H%M)"
AutoProvisionerServiceAccountName="mdc-onboarding-sa"
CspmServiceAccountName="microsoft-defender-cspm"
OrganizationID="414682614336"
IAMRoleID="MDCCustomRole"
CspmCustomRoleID="MDCCspmCustomRole"
WorkloadIdentityPoolDescription="Microsoft defender for cloud provisioner workload identity pool"
WorkloadIdentityPoolName="microsoft defender for cloud"
WorkloadIdentityPoolId="8efa1c55953c42dfa19dd4599e4c64d4"

# Create a custom role for MDC CSPM

        if gcloud iam roles describe "${CspmCustomRoleID}" \
        --organization="${OrganizationID}" 2>/dev/null; then
    gcloud iam roles update "${CspmCustomRoleID}" \
        --organization="${OrganizationID}" \
        --title="${CspmCustomRoleID}" \
        --description="Microsoft Defender for cloud CSPM custom role" \
        --permissions="resourcemanager.folders.getIamPolicy,resourcemanager.folders.list,resourcemanager.organizations.get,resourcemanager.organizations.getIamPolicy,storage.buckets.getIamPolicy" \
    
else
    gcloud iam roles create "${CspmCustomRoleID}" \
        --organization="${OrganizationID}" \
        --title="${CspmCustomRoleID}" \
        --description="Microsoft Defender for cloud CSPM custom role" \
        --permissions="resourcemanager.folders.getIamPolicy,resourcemanager.folders.list,resourcemanager.organizations.get,resourcemanager.organizations.getIamPolicy,storage.buckets.getIamPolicy" \
    
fi


# Create a custom role for a an organization

        if gcloud iam roles describe "${IAMRoleID}" \
        --organization="${OrganizationID}" 2>/dev/null; then
    gcloud iam roles update "${IAMRoleID}" \
        --organization="${OrganizationID}" \
        --title="${IAMRoleID}" \
        --description="Microsoft organizaion custom role for onboarding" \
        --permissions="resourcemanager.folders.get,resourcemanager.folders.list,resourcemanager.projects.get,resourcemanager.projects.list,serviceusage.services.enable" \
    
else
    gcloud iam roles create "${IAMRoleID}" \
        --organization="${OrganizationID}" \
        --title="${IAMRoleID}" \
        --description="Microsoft organizaion custom role for onboarding" \
        --permissions="resourcemanager.folders.get,resourcemanager.folders.list,resourcemanager.projects.get,resourcemanager.projects.list,serviceusage.services.enable" \
    
fi


# Check if the Management Project Exists
existingProject=$(gcloud projects describe "${MgmtProjectId}" 2>/dev/null)

if [ -z "${existingProject}" ]; then
    # Project does not exist, creating it
    gcloud projects create "${MgmtProjectId}"     --organization="${OrganizationID}"     --name="Microsoft MGMT Project"

    echo "Sleep 1m - waiting for creation"
    sleep 60s
else
    echo "Project '${MgmtProjectId}' already exists. Skipping project creation."
fi

# Check if Project is Linked to a Billing Account
linkedBillingAccount=$(gcloud beta billing projects describe "${MgmtProjectId}" --format="value(billingAccountName)" 2>/dev/null)

if [ -z "${linkedBillingAccount}" ]; then
    # Billing account is not linked, so ask for input
    echo -n "Please enter a billing account id to link to management project '${MgmtProjectId}': "
    read billingAccountId
    gcloud beta billing projects link "${MgmtProjectId}" --billing-account="${billingAccountId}"
else
    echo "Project '${MgmtProjectId}' is already linked to billing account '${linkedBillingAccount}'. Skipping billing linkage."
fi

# Get Project number
ProjectNumber=$(gcloud projects describe ${MgmtProjectId} --format="value(projectNumber)")

# Set context to target project
gcloud config set project ${MgmtProjectId}

# create a Service Account
if gcloud iam service-accounts describe "${AutoProvisionerServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" 2>/dev/null; then
    gcloud iam service-accounts update "${AutoProvisionerServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
        --display-name="Microsoft Onboarding management service account" --project="${MgmtProjectId}"
else
    gcloud iam service-accounts create ${AutoProvisionerServiceAccountName} \
        --display-name="Microsoft Onboarding management service account" --project="${MgmtProjectId}"
fi

if gcloud iam service-accounts describe "${CspmServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" 2>/dev/null; then
    gcloud iam service-accounts update "${CspmServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
        --display-name="Microsoft Defender CSPM" --project="${MgmtProjectId}"
else
    gcloud iam service-accounts create ${CspmServiceAccountName} \
        --display-name="Microsoft Defender CSPM" --project="${MgmtProjectId}"
fi


# Assign the Custom Role to the Service Account
gcloud organizations add-iam-policy-binding ${OrganizationID} \
    --member="serviceAccount:${AutoProvisionerServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
    --role="organizations/${OrganizationID}/roles/${IAMRoleID}"

# Enable APIs
gcloud services enable cloudresourcemanager.googleapis.com --project=${MgmtProjectId}
gcloud services enable iam.googleapis.com --project=${MgmtProjectId}
gcloud services enable sts.googleapis.com --project=${MgmtProjectId}
gcloud services enable iamcredentials.googleapis.com --project=${MgmtProjectId}
gcloud services enable compute.googleapis.com --project=${MgmtProjectId}
gcloud services enable container.googleapis.com --project=${MgmtProjectId}
gcloud services enable sqladmin.googleapis.com --project=${MgmtProjectId}
gcloud services enable apikeys.googleapis.com --project=${MgmtProjectId}
gcloud services enable cloudkms.googleapis.com --project=${MgmtProjectId}

# Configure Workload Identity Federation Provider - Create Federation or show & update properties if already exists
if gcloud iam workload-identity-pools describe "${WorkloadIdentityPoolId}" --location="global" --project "${MgmtProjectId}" 2>/dev/null; then
    gcloud iam workload-identity-pools update "${WorkloadIdentityPoolId}" \
        --location="global" \
        --project "${MgmtProjectId}" \
        --display-name="${WorkloadIdentityPoolName}" \
        --description="${WorkloadIdentityPoolDescription}"
else
    gcloud iam workload-identity-pools create "${WorkloadIdentityPoolId}" \
        --location="global" \
        --project "${MgmtProjectId}" \
        --display-name="${WorkloadIdentityPoolName}" \
        --description="${WorkloadIdentityPoolDescription}"
fi

# Add The Service Account To The Idetity Federation
gcloud iam service-accounts add-iam-policy-binding "${AutoProvisionerServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
    --role=roles/iam.workloadIdentityUser \
    --member="principalSet://iam.googleapis.com/projects/${ProjectNumber}/locations/global/workloadIdentityPools/${WorkloadIdentityPoolId}/*" \
    --project=${MgmtProjectId}

gcloud iam service-accounts add-iam-policy-binding "${CspmServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
    --role=roles/iam.workloadIdentityUser \
    --member="principalSet://iam.googleapis.com/projects/${ProjectNumber}/locations/global/workloadIdentityPools/${WorkloadIdentityPoolId}/*" \
    --project=${MgmtProjectId}

# Add policy binding for cspm service account
gcloud organizations add-iam-policy-binding ${OrganizationID} \
        --member="serviceAccount:${CspmServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
        --role="roles/viewer"
gcloud organizations add-iam-policy-binding ${OrganizationID} \
    --member="serviceAccount:${CspmServiceAccountName}@${MgmtProjectId}.iam.gserviceaccount.com" \
    --role="organizations/${OrganizationID}/roles/${CspmCustomRoleID}"

# Create Identity Provider
if gcloud iam workload-identity-pools providers describe "auto-provisioner" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" 2>/dev/null; then
    gcloud iam workload-identity-pools providers update-oidc "auto-provisioner" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" \
        --issuer-uri="https://sts.windows.net/33e01921-4d64-4f8c-a055-5bdaffd5e33d" \
        --allowed-audiences="api://d17a7d74-7e73-4e7d-bd41-8d9525e86cab" \
         \
        --attribute-mapping="google.subject=assertion.sub"
else
    gcloud iam workload-identity-pools providers create-oidc "auto-provisioner" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" \
        --issuer-uri="https://sts.windows.net/33e01921-4d64-4f8c-a055-5bdaffd5e33d" \
        --allowed-audiences="api://d17a7d74-7e73-4e7d-bd41-8d9525e86cab" \
         \
        --attribute-mapping="google.subject=assertion.sub"
fi


# Create CSPM identity pool
if gcloud iam workload-identity-pools providers describe "cspm" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" 2>/dev/null; then
    gcloud iam workload-identity-pools providers update-oidc "cspm" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" \
        --issuer-uri="https://sts.windows.net/33e01921-4d64-4f8c-a055-5bdaffd5e33d" \
        --allowed-audiences="api://6e81e733-9e7f-474a-85f0-385c097f7f52" \
         \
        --attribute-mapping="google.subject=assertion.sub"
else
    gcloud iam workload-identity-pools providers create-oidc "cspm" --location="global" --project="${MgmtProjectId}" --workload-identity-pool="${WorkloadIdentityPoolId}" \
        --issuer-uri="https://sts.windows.net/33e01921-4d64-4f8c-a055-5bdaffd5e33d" \
        --allowed-audiences="api://6e81e733-9e7f-474a-85f0-385c097f7f52" \
         \
        --attribute-mapping="google.subject=assertion.sub"
fi