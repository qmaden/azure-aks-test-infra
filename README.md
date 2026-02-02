# Azure AKS Test Infrastructure

This Terraform project creates Azure infrastructure including a resource group and storage account in Central India region.

## Prerequisites

1. **Azure Subscription**: You need an active Azure subscription
2. **Terraform Cloud**: Account setup (already configured)
3. **Service Principal**: For Azure authentication

## Azure Provider Authentication

Since you're using Terraform Cloud, you need to configure Azure authentication using a Service Principal with Client Secret.

### Create a Service Principal

Run these commands in Azure CLI:

```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription="YOUR-SUBSCRIPTION-ID"

# Create Service Principal with Contributor role
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/YOUR-SUBSCRIPTION-ID" --name="terraform-sp"
```

This will output:
```json
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "terraform-sp",
  "password": "your-client-secret",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

### Configure Terraform Cloud Variables

In your Terraform Cloud workspace, add these environment variables:

| Variable Name | Value | Sensitive |
|--------------|-------|-----------|
| `ARM_CLIENT_ID` | The `appId` from above | No |
| `ARM_CLIENT_SECRET` | The `password` from above | **Yes** |
| `ARM_TENANT_ID` | The `tenant` from above | No |
| `ARM_SUBSCRIPTION_ID` | Your Azure subscription ID | No |

**Important**: Mark `ARM_CLIENT_SECRET` as sensitive in Terraform Cloud!

## Configuration

1. **Update providers.tf**: Change the organization and workspace names:
   ```hcl
   cloud {
     organization = "your-actual-organization-name"
     
     workspaces {
       name = "azure-aks-test-infra"
     }
   }
   ```

2. **Set Variables in Terraform Cloud**: You can set Terraform variables in your workspace:
   - `resource_group_name` (default: "rg-aks-test-centralindia")
   - `location` (default: "centralindia")
   - `storage_account_name` (must be globally unique!)
   - `storage_account_tier` (default: "Standard")
   - `storage_account_replication_type` (default: "LRS")

   Or create a `terraform.tfvars` file locally (not recommended for Terraform Cloud).

## Resources Created

- **Resource Group**: A resource group in Central India
- **Storage Account**: 
  - StorageV2 account
  - Hot access tier
  - HTTPS only enabled
  - TLS 1.2 minimum
  - Public blob access disabled

## Usage

### Initialize Terraform
```bash
terraform login
terraform init
```

### Plan Changes
```bash
terraform plan
```

### Apply Configuration
```bash
terraform apply
```

### Destroy Resources
```bash
terraform destroy
```

## Important Notes

1. **Storage Account Name**: Must be globally unique across all of Azure, 3-24 characters, lowercase letters and numbers only
2. **Terraform Cloud**: Runs are executed in Terraform Cloud, not locally
3. **State Management**: State is managed in Terraform Cloud automatically
4. **Cost**: Standard LRS storage account in Central India will incur charges

## Outputs

After applying, you'll get:
- Resource group ID and name
- Storage account ID and name
- Primary blob endpoint
- Primary access key (sensitive)
- Primary connection string (sensitive)

To view sensitive outputs:
```bash
terraform output storage_account_primary_access_key
```

## File Structure

```
.
├── providers.tf              # Provider and Terraform Cloud config
├── variables.tf              # Variable definitions
├── main.tf                   # Main resources
├── outputs.tf                # Output definitions
├── terraform.tfvars.example  # Example variable values
├── .gitignore               # Git ignore patterns
└── README.md                # This file
```
