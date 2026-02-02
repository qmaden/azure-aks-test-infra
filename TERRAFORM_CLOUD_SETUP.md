# Terraform Cloud/Enterprise Setup Guide

## Authentication & Login

### Method 1: Login via CLI (Recommended for first time)

```bash
# Login to Terraform Cloud
terraform login

# Or specify the hostname for Terraform Enterprise
terraform login app.terraform.io
```

This will:
1. Open your browser to generate a token
2. Prompt you to paste the token in the terminal
3. Save the token to `~/.terraform.d/credentials.tfrc.json`

### Method 2: Manual Token Configuration

1. Go to Terraform Cloud: https://app.terraform.io/app/settings/tokens
2. Generate a new API token
3. Create or edit `~/.terraform.d/credentials.tfrc.json`:

```json
{
  "credentials": {
    "app.terraform.io": {
      "token": "YOUR-TERRAFORM-CLOUD-TOKEN"
    }
  }
}
```

For Terraform Enterprise, replace `app.terraform.io` with your enterprise hostname.

### Method 3: Environment Variable

```bash
# Set the token as an environment variable
export TF_TOKEN_app_terraform_io="YOUR-TERRAFORM-CLOUD-TOKEN"

# For Terraform Enterprise, use your hostname
export TF_TOKEN_your_enterprise_hostname="YOUR-TOKEN"
```

## Variable Configuration Options

Terraform Cloud provides multiple ways to set variables:

### Option 1: Workspace Variables (UI)

In your Terraform Cloud workspace:

1. Go to **Variables** tab
2. Add **Terraform Variables**:
   - `resource_group_name`
   - `location`
   - `storage_account_name`
   - `storage_account_tier`
   - `storage_account_replication_type`

3. Add **Environment Variables** (for Azure auth):
   - `ARM_CLIENT_ID`
   - `ARM_CLIENT_SECRET` (mark as sensitive)
   - `ARM_TENANT_ID`
   - `ARM_SUBSCRIPTION_ID`

### Option 2: *.auto.tfvars Files (Recommended)

Create `terraform.auto.tfvars` in your repository:

```hcl
resource_group_name              = "rg-aks-test-centralindia"
location                         = "centralindia"
storage_account_name             = "stakstest12345"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

tags = {
  Environment = "Test"
  ManagedBy   = "Terraform"
  Project     = "AKS-Test"
}
```

**Benefits:**
- Automatically loaded by Terraform Cloud (v0.10.0+)
- Version controlled
- Consistent across team
- No manual UI configuration needed

**Note:** DO NOT put sensitive values here. Use Environment Variables for secrets.

### Option 3: Variable Sets

For sharing variables across multiple workspaces:

1. In Terraform Cloud, go to **Settings** > **Variable Sets**
2. Create a new Variable Set
3. Add common variables (like tags, location)
4. Apply to multiple workspaces

### Option 4: Terraform Cloud Provider API

Use the `tfe` provider to automate variable creation:

```hcl
terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.51"
    }
  }
}

provider "tfe" {
  # Token from environment variable TFE_TOKEN
}

resource "tfe_variable" "arm_client_id" {
  workspace_id = var.workspace_id
  key          = "ARM_CLIENT_ID"
  value        = var.azure_client_id
  category     = "env"
}

resource "tfe_variable" "arm_client_secret" {
  workspace_id = var.workspace_id
  key          = "ARM_CLIENT_SECRET"
  value        = var.azure_client_secret
  category     = "env"
  sensitive    = true
}
```

### Option 5: Variables API

Use the REST API to bulk-add variables:

```bash
# Set workspace variables via API
curl \
  --header "Authorization: Bearer $TF_CLOUD_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload.json \
  https://app.terraform.io/api/v2/workspaces/WORKSPACE_ID/vars

# payload.json example:
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_ID",
      "value": "00000000-0000-0000-0000-000000000000",
      "category": "env",
      "sensitive": false
    }
  }
}
```

## Initial Setup Workflow

### Step 1: Install Terraform

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Or download from: https://www.terraform.io/downloads
```

### Step 2: Login to Terraform Cloud

```bash
terraform login
```

### Step 3: Update Configuration

Edit `providers.tf` and update:

```hcl
cloud {
  organization = "your-actual-org-name"  # Change this!
  
  workspaces {
    name = "azure-aks-test-infra"
  }
}
```

### Step 4: Configure Azure Authentication

Choose one method:

**A. Via Terraform Cloud UI:**
Add environment variables in your workspace

**B. Via terraform.auto.tfvars:**
For non-sensitive Terraform variables only

**C. Via Variable Sets:**
For shared variables across workspaces

### Step 5: Initialize Terraform

```bash
terraform init
```

This will:
- Connect to Terraform Cloud
- Initialize the Azure provider
- Download required provider plugins

### Step 6: Plan and Apply

```bash
# Create execution plan (runs in Terraform Cloud)
terraform plan

# Apply changes
terraform apply
```

## Best Practices

1. **Secrets Management:**
   - NEVER commit secrets to git
   - Use Terraform Cloud Environment Variables for:
     - `ARM_CLIENT_SECRET`
     - Storage account keys
     - Any API tokens
   - Mark them as "Sensitive" in the UI

2. **Non-Secret Variables:**
   - Use `terraform.auto.tfvars` for:
     - Resource names
     - Locations
     - Tags
     - Configuration settings

3. **Workspace Organization:**
   - Use separate workspaces for: dev, staging, production
   - Use Variable Sets for common values
   - Use naming conventions: `project-env-purpose`

4. **Version Control:**
   - Commit `.tf` files
   - Commit `terraform.auto.tfvars`
   - DO NOT commit `terraform.tfvars` (if it contains secrets)
   - Use `.gitignore` properly

## Troubleshooting

### Authentication Issues

```bash
# Clear cached credentials
rm -rf ~/.terraform.d/credentials.tfrc.json

# Re-login
terraform login
```

### Workspace Not Found

```bash
# List workspaces
terraform workspace list

# Select correct workspace
terraform workspace select workspace-name
```

### Backend Configuration Issues

```bash
# Reinitialize with reconfiguration
terraform init -reconfigure
```

### Azure Authentication Failures

Check environment variables in Terraform Cloud:
- Verify all 4 ARM_* variables are set
- Verify the Service Principal has correct permissions
- Test the Service Principal locally:
  ```bash
  az login --service-principal \
    -u $ARM_CLIENT_ID \
    -p $ARM_CLIENT_SECRET \
    --tenant $ARM_TENANT_ID
  ```

## Additional Resources

- [Terraform Cloud Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Cloud Variables](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)
- [Azure Provider Authentication](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
