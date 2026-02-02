# Variables Configuration Guide

This guide explains how to configure variables for Terraform Cloud/Enterprise.

## Quick Start: Using .auto.tfvars Files

The easiest way to configure variables is using `terraform.auto.tfvars`:

1. Copy the example file:
   ```bash
   cp terraform.auto.tfvars.example terraform.auto.tfvars
   ```

2. Edit `terraform.auto.tfvars` with your values:
   ```hcl
   storage_account_name = "mystorageacct123"  # Make this globally unique
   ```

3. Commit to git:
   ```bash
   git add terraform.auto.tfvars
   git commit -m "Add auto-loaded variables"
   git push
   ```

4. Terraform Cloud will automatically load these values!

## Variable Loading Priority

Terraform loads variables in this order (last wins):

1. Environment variables (`TF_VAR_name`)
2. `terraform.tfvars` file
3. `terraform.tfvars.json` file
4. `*.auto.tfvars` files (alphabetical order)
5. `*.auto.tfvars.json` files (alphabetical order)
6. `-var` command line flags
7. Terraform Cloud workspace variables (UI)

## Required Variables for This Project

### Terraform Variables (in workspace or .auto.tfvars)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group_name` | string | `rg-aks-test-centralindia` | Name of the resource group |
| `location` | string | `centralindia` | Azure region |
| `storage_account_name` | string | `stakstest` | Storage account name (must be globally unique) |
| `storage_account_tier` | string | `Standard` | Storage tier: Standard or Premium |
| `storage_account_replication_type` | string | `LRS` | Replication: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS |
| `tags` | map(string) | See variables.tf | Resource tags |

### Environment Variables (in Terraform Cloud workspace)

| Variable | Required | Sensitive | Description |
|----------|----------|-----------|-------------|
| `ARM_CLIENT_ID` | Yes | No | Azure Service Principal App ID |
| `ARM_CLIENT_SECRET` | Yes | **Yes** | Azure Service Principal password |
| `ARM_TENANT_ID` | Yes | No | Azure AD Tenant ID |
| `ARM_SUBSCRIPTION_ID` | Yes | No | Azure Subscription ID |

## Configuration Methods

### Method 1: terraform.auto.tfvars (Recommended)

**Advantages:**
- Automatically loaded in Terraform Cloud
- Version controlled
- Team consistency
- No UI configuration needed

**File: terraform.auto.tfvars**
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
  Owner       = "DevOps-Team"
}
```

### Method 2: Terraform Cloud Workspace UI

1. Navigate to your workspace
2. Click **Variables** tab
3. Add **Terraform Variables** section:
   - Click "Add variable"
   - Enter key and value
   - Select "Terraform variable" category

### Method 3: Environment-Specific Files

Create multiple `.auto.tfvars` files:

**dev.auto.tfvars:**
```hcl
storage_account_name = "stakstestdev"
tags = {
  Environment = "Development"
}
```

**prod.auto.tfvars:**
```hcl
storage_account_name = "stakstestprod"
tags = {
  Environment = "Production"
}
```

Only commit the one for your workspace's environment.

### Method 4: Variable Sets (Multiple Workspaces)

For shared variables across workspaces:

1. In Terraform Cloud: **Settings** > **Variable Sets**
2. Create new set: "Azure Common Variables"
3. Add variables:
   - `location` = `centralindia`
   - `tags` = `{"ManagedBy": "Terraform"}`
4. Apply to workspaces: Select workspaces to apply

### Method 5: Terraform Cloud Provider (Automation)

**setup-variables.tf:**
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
  token = var.tfe_token
}

# Set Azure authentication variables
resource "tfe_variable" "azure_client_id" {
  workspace_id = var.workspace_id
  key          = "ARM_CLIENT_ID"
  value        = var.azure_client_id
  category     = "env"
  description  = "Azure Service Principal Client ID"
}

resource "tfe_variable" "azure_client_secret" {
  workspace_id = var.workspace_id
  key          = "ARM_CLIENT_SECRET"
  value        = var.azure_client_secret
  category     = "env"
  sensitive    = true
  description  = "Azure Service Principal Client Secret"
}

resource "tfe_variable" "azure_tenant_id" {
  workspace_id = var.workspace_id
  key          = "ARM_TENANT_ID"
  value        = var.azure_tenant_id
  category     = "env"
  description  = "Azure AD Tenant ID"
}

resource "tfe_variable" "azure_subscription_id" {
  workspace_id = var.workspace_id
  key          = "ARM_SUBSCRIPTION_ID"
  value        = var.azure_subscription_id
  category     = "env"
  description  = "Azure Subscription ID"
}

# Set Terraform variables
resource "tfe_variable" "storage_account_name" {
  workspace_id = var.workspace_id
  key          = "storage_account_name"
  value        = var.storage_account_name
  category     = "terraform"
  description  = "Azure Storage Account Name"
}
```

### Method 6: REST API (Bulk Operations)

**Script: set-variables.sh**
```bash
#!/bin/bash

WORKSPACE_ID="ws-xxxxxxxxxxxxx"
TF_TOKEN="your-terraform-cloud-token"

# Function to create variable
create_var() {
  local key=$1
  local value=$2
  local category=$3
  local sensitive=${4:-false}

  curl \
    --header "Authorization: Bearer $TF_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data "{
      \"data\": {
        \"type\": \"vars\",
        \"attributes\": {
          \"key\": \"$key\",
          \"value\": \"$value\",
          \"category\": \"$category\",
          \"sensitive\": $sensitive
        }
      }
    }" \
    https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/vars
}

# Set environment variables (Azure auth)
create_var "ARM_CLIENT_ID" "00000000-0000-0000-0000-000000000000" "env" false
create_var "ARM_CLIENT_SECRET" "your-secret-here" "env" true
create_var "ARM_TENANT_ID" "00000000-0000-0000-0000-000000000000" "env" false
create_var "ARM_SUBSCRIPTION_ID" "00000000-0000-0000-0000-000000000000" "env" false

# Set Terraform variables
create_var "storage_account_name" "stakstest12345" "terraform" false
create_var "location" "centralindia" "terraform" false
```

## Validation

Variables are validated in `variables.tf`:

```hcl
variable "storage_account_name" {
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 chars, lowercase and numbers only."
  }
}

variable "storage_account_tier" {
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}
```

## Best Practices

### ✅ DO:
- Use `terraform.auto.tfvars` for non-sensitive variables
- Use Environment Variables for secrets (ARM_CLIENT_SECRET)
- Mark sensitive variables in Terraform Cloud UI
- Commit `.auto.tfvars` files to git
- Use descriptive variable names
- Add validation rules
- Document default values

### ❌ DON'T:
- Commit secrets to git
- Put ARM_CLIENT_SECRET in .auto.tfvars
- Use production secrets in development
- Hard-code values in .tf files
- Skip variable validation
- Use cryptic variable names

## Testing Your Variables

### Local Test:
```bash
# Set environment variables locally
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="your-secret"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"

# Test plan
terraform plan
```

### Terraform Cloud Test:
```bash
# Variables are automatically loaded from:
# 1. terraform.auto.tfvars (in git)
# 2. Workspace Environment Variables (in UI)

terraform plan
```

## Troubleshooting

### Variable Not Loading

Check loading order:
```bash
# See what Terraform will use
terraform console
> var.storage_account_name
```

### Validation Errors

```
Error: Invalid value for variable

Storage account name must be 3-24 chars, lowercase and numbers only.
```

Fix: Update variable to match validation rules in `variables.tf`

### Missing Required Variables

```
Error: No value for required variable

Variable "storage_account_name" is required but no value was set.
```

Fix: Set the variable in `terraform.auto.tfvars` or Terraform Cloud workspace

## Example Complete Setup

**1. Create terraform.auto.tfvars:**
```hcl
resource_group_name              = "rg-aks-test-centralindia"
location                         = "centralindia"
storage_account_name             = "stakstest$(date +%s)"  # Unique name
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

tags = {
  Environment = "Test"
  ManagedBy   = "Terraform"
  Project     = "AKS-Test"
}
```

**2. Set Environment Variables in Terraform Cloud UI:**
- ARM_CLIENT_ID: `<your-value>`
- ARM_CLIENT_SECRET: `<your-value>` (sensitive)
- ARM_TENANT_ID: `<your-value>`
- ARM_SUBSCRIPTION_ID: `<your-value>`

**3. Run Terraform:**
```bash
terraform init
terraform plan
terraform apply
```

Done! 🎉
