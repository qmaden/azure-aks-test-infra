# Multi-Environment Setup with Terraform Cloud

This guide explains how to handle multiple environments (dev, staging, prod) and multiple Azure subscriptions.

## Architecture Approaches

### Approach 1: Multiple Workspaces (Recommended)

Create separate Terraform Cloud workspaces for each environment:

```
Workspaces:
├── azure-aks-dev
├── azure-aks-staging
└── azure-aks-prod
```

**Advantages:**
- Clear separation of environments
- Different state files per environment
- Independent deployment lifecycles
- Different approval workflows
- Easy to manage permissions per environment

#### Setup:

**1. Create workspaces in Terraform Cloud:**
- `azure-aks-dev`
- `azure-aks-staging`
- `azure-aks-prod`

**2. Update providers.tf to use variable for workspace:**

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }

  cloud {
    organization = "qmaden-test"
    
    workspaces {
      # This will be set per environment
      # Option 1: Use tags to select workspace dynamically
      tags = ["azure", "aks"]
      
      # Option 2: Use specific workspace name (static)
      # name = "azure-aks-dev"
    }
  }
}
```

**3. Set environment-specific variables in each workspace:**

**Workspace: azure-aks-dev**
- Environment Variables:
  - `ARM_SUBSCRIPTION_ID` = `<dev-subscription-id>`
  - `ARM_CLIENT_ID` = `<dev-sp-client-id>`
  - `ARM_CLIENT_SECRET` = `<dev-sp-secret>`
  - `ARM_TENANT_ID` = `<tenant-id>`

- Terraform Variables:
  - `resource_group_name` = `rg-aks-dev-centralindia`
  - `storage_account_name` = `stakstestdev001`
  - `tags` = `{"Environment": "Development"}`

**Workspace: azure-aks-staging**
- Environment Variables:
  - `ARM_SUBSCRIPTION_ID` = `<staging-subscription-id>`
  - (same pattern as dev)

- Terraform Variables:
  - `resource_group_name` = `rg-aks-staging-centralindia`
  - `storage_account_name` = `staksteststaging001`
  - `tags` = `{"Environment": "Staging"}`

**Workspace: azure-aks-prod**
- Environment Variables:
  - `ARM_SUBSCRIPTION_ID` = `<prod-subscription-id>`
  - (same pattern)

- Terraform Variables:
  - `resource_group_name` = `rg-aks-prod-centralindia`
  - `storage_account_name` = `stakstestprod001`
  - `tags` = `{"Environment": "Production"}`

**4. Deploy to specific environment:**

```bash
# Select workspace
export TF_WORKSPACE=azure-aks-dev
terraform init
terraform plan
terraform apply

# Or for production
export TF_WORKSPACE=azure-aks-prod
terraform init
terraform plan
terraform apply
```

---

### Approach 2: Directory-Based Environments

Separate directories for each environment with shared modules:

```
.
├── modules/
│   ├── resource-group/
│   ├── storage-account/
│   └── aks-cluster/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.auto.tfvars
│   │   └── providers.tf
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.auto.tfvars
│   │   └── providers.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.auto.tfvars
│       └── providers.tf
└── README.md
```

**environments/dev/providers.tf:**
```hcl
terraform {
  cloud {
    organization = "qmaden-test"
    workspaces {
      name = "azure-aks-dev"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
```

**environments/dev/terraform.auto.tfvars:**
```hcl
subscription_id              = "dev-subscription-id"
resource_group_name          = "rg-aks-dev-centralindia"
storage_account_name         = "stakstestdev001"
environment                  = "dev"
```

**environments/prod/terraform.auto.tfvars:**
```hcl
subscription_id              = "prod-subscription-id"
resource_group_name          = "rg-aks-prod-centralindia"
storage_account_name         = "stakstestprod001"
environment                  = "prod"
```

---

### Approach 3: Variable Sets (Shared Variables)

Use Terraform Cloud Variable Sets for common values across environments.

**Create Variable Sets:**

**1. "Azure Common Settings"** (applied to all workspaces):
- `location` = `centralindia`
- `tags` (base tags common to all)
- `ARM_TENANT_ID` = `<tenant-id>`

**2. "Development Environment"** (applied to dev workspaces):
- `ARM_SUBSCRIPTION_ID` = `<dev-subscription-id>`
- `ARM_CLIENT_ID` = `<dev-sp-client-id>`
- `ARM_CLIENT_SECRET` = `<dev-sp-secret>` (sensitive)
- `environment` = `dev`

**3. "Production Environment"** (applied to prod workspaces):
- `ARM_SUBSCRIPTION_ID` = `<prod-subscription-id>`
- `ARM_CLIENT_ID` = `<prod-sp-client-id>`
- `ARM_CLIENT_SECRET` = `<prod-sp-secret>` (sensitive)
- `environment` = `prod`

Then each workspace only needs environment-specific overrides.

---

### Approach 4: Terraform Workspaces (Local - Not Recommended for Terraform Cloud)

**Note:** Don't confuse Terraform Cloud workspaces with local `terraform workspace` command. They're different concepts.

---

## Recommended Setup for Your Use Case

### Multiple Azure Subscriptions + Multiple Environments

**Structure:**
```
Terraform Cloud Workspaces:
├── azure-aks-dev           (Dev subscription)
├── azure-aks-staging       (Staging subscription)
└── azure-aks-prod          (Production subscription, different subscription)
```

**File Structure:**
```
azure-aks-test-infra/
├── main.tf                 # Common resources
├── variables.tf            # All variable definitions
├── outputs.tf              # Common outputs
├── providers.tf            # Provider config with workspace selection
├── terraform.auto.tfvars   # Default/dev values (committed)
└── README.md
```

**providers.tf (updated):**
```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }

  cloud {
    organization = "qmaden-test"
    
    # Use tags to allow CLI to select workspace
    workspaces {
      tags = ["azure", "aks"]
    }
  }
}

provider "azurerm" {
  features {}
  # Authentication from environment variables (set per workspace):
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}
```

**variables.tf (add environment variable):**
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}

# ... rest of variables
```

**terraform.auto.tfvars (dev defaults):**
```hcl
environment                  = "dev"
resource_group_name          = "rg-aks-dev-centralindia"
location                     = "centralindia"
storage_account_name         = "stakstestdev001"
storage_account_tier         = "Standard"
storage_account_replication_type = "LRS"

tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
  Project     = "AKS-Test"
}
```

**In Terraform Cloud:**

**Workspace: azure-aks-dev**
- Environment Variables:
  ```
  ARM_SUBSCRIPTION_ID = "<dev-subscription-id>"
  ARM_CLIENT_ID       = "<dev-sp-client-id>"
  ARM_CLIENT_SECRET   = "<dev-sp-secret>" (sensitive)
  ARM_TENANT_ID       = "<tenant-id>"
  ```
- Terraform Variables (override .auto.tfvars):
  ```
  environment = "dev" (if different from auto.tfvars)
  ```

**Workspace: azure-aks-staging**
- Environment Variables:
  ```
  ARM_SUBSCRIPTION_ID = "<staging-subscription-id>"
  ARM_CLIENT_ID       = "<staging-sp-client-id>"
  ARM_CLIENT_SECRET   = "<staging-sp-secret>" (sensitive)
  ARM_TENANT_ID       = "<tenant-id>"
  ```
- Terraform Variables:
  ```
  environment              = "staging"
  resource_group_name      = "rg-aks-staging-centralindia"
  storage_account_name     = "staksteststaging001"
  tags = {
    Environment = "Staging"
    ManagedBy   = "Terraform"
    Project     = "AKS-Test"
  }
  ```

**Workspace: azure-aks-prod**
- Environment Variables:
  ```
  ARM_SUBSCRIPTION_ID = "<prod-subscription-id>"
  ARM_CLIENT_ID       = "<prod-sp-client-id>"
  ARM_CLIENT_SECRET   = "<prod-sp-secret>" (sensitive)
  ARM_TENANT_ID       = "<tenant-id>"
  ```
- Terraform Variables:
  ```
  environment              = "prod"
  resource_group_name      = "rg-aks-prod-centralindia"
  storage_account_name     = "stakstestprod001"
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "AKS-Test"
  }
  ```

**Deploy to each environment:**
```bash
# Development
terraform workspace select azure-aks-dev
terraform plan
terraform apply

# Staging
terraform workspace select azure-aks-staging
terraform plan
terraform apply

# Production
terraform workspace select azure-aks-prod
terraform plan
terraform apply
```

---

## Service Principal Strategy

### Option 1: Separate Service Principals per Environment (Most Secure)

Create different SPs for each environment:

```bash
# Dev Service Principal
az ad sp create-for-rbac \
  --name "terraform-sp-aks-dev" \
  --role="Contributor" \
  --scopes="/subscriptions/<dev-subscription-id>"

# Staging Service Principal
az ad sp create-for-rbac \
  --name "terraform-sp-aks-staging" \
  --role="Contributor" \
  --scopes="/subscriptions/<staging-subscription-id>"

# Prod Service Principal
az ad sp create-for-rbac \
  --name "terraform-sp-aks-prod" \
  --role="Contributor" \
  --scopes="/subscriptions/<prod-subscription-id>"
```

**Advantages:**
- Principle of least privilege
- Compromised dev credentials can't affect prod
- Different access levels per environment
- Audit trail per environment

### Option 2: Single Service Principal with Multiple Subscription Access

```bash
# Create SP with access to multiple subscriptions
az ad sp create-for-rbac \
  --name "terraform-sp-aks-all" \
  --role="Contributor" \
  --scopes="/subscriptions/<dev-sub-id>" \
           "/subscriptions/<staging-sub-id>" \
           "/subscriptions/<prod-sub-id>"
```

**Advantages:**
- Simpler credential management
- Same SP across all workspaces

**Disadvantages:**
- Less secure (prod access from all environments)
- Harder to audit

---

## Best Practices

### 1. Naming Conventions

```
Resource Group: rg-{project}-{env}-{region}
Example: rg-aks-dev-centralindia

Storage Account: st{project}{env}{random}
Example: stakstestdev001

Workspace: {project}-{env}
Example: azure-aks-dev
```

### 2. Tagging Strategy

```hcl
tags = {
  Environment     = "Development|Staging|Production"
  ManagedBy       = "Terraform"
  Project         = "AKS-Test"
  CostCenter      = "Engineering"
  Owner           = "platform-team@example.com"
  Terraform       = "true"
  WorkspaceId     = "azure-aks-dev"
  SubscriptionType = "dev|staging|prod"
}
```

### 3. Variable Precedence

Remember the order (last wins):
1. Default values in `variables.tf`
2. `terraform.auto.tfvars` (committed to git)
3. Terraform Cloud workspace variables (UI)
4. Environment variables (`TF_VAR_*`)

### 4. Security Best Practices

- ✅ Use separate Service Principals per environment
- ✅ Store secrets only in Terraform Cloud (mark as sensitive)
- ✅ Never commit `ARM_CLIENT_SECRET` to git
- ✅ Use least privilege (Reader vs Contributor vs Owner)
- ✅ Rotate Service Principal secrets regularly
- ✅ Enable Multi-Factor Auth on Terraform Cloud
- ✅ Use approval workflows for production

### 5. Deployment Strategy

```bash
# Always plan first
terraform plan -out=tfplan

# Review plan
# Apply only after review
terraform apply tfplan

# For production, use manual approval in Terraform Cloud
# Settings → General → Execution Mode → Manual Apply
```

---

## Migration Path

From current single workspace to multi-environment:

### Step 1: Create additional workspaces
```bash
# In Terraform Cloud UI, create:
- azure-aks-staging
- azure-aks-prod
```

### Step 2: Create Service Principals for each
```bash
# Staging
az ad sp create-for-rbac \
  --name "terraform-sp-aks-staging" \
  --role="Contributor" \
  --scopes="/subscriptions/<staging-subscription-id>"

# Production
az ad sp create-for-rbac \
  --name "terraform-sp-aks-prod" \
  --role="Contributor" \
  --scopes="/subscriptions/<prod-subscription-id>"
```

### Step 3: Configure workspace variables
Set environment-specific variables in each workspace (as shown above)

### Step 4: Update providers.tf
Change from single workspace name to tags:
```hcl
workspaces {
  tags = ["azure", "aks"]
}
```

### Step 5: Deploy to each environment
```bash
terraform workspace select azure-aks-dev
terraform apply

terraform workspace select azure-aks-staging
terraform apply

terraform workspace select azure-aks-prod
terraform apply
```

---

## Summary

**For multiple environments + multiple subscriptions:**

1. ✅ Use **separate Terraform Cloud workspaces** (one per environment)
2. ✅ Use **separate Azure Service Principals** (one per environment) 
3. ✅ Set **ARM_SUBSCRIPTION_ID** as environment variable per workspace
4. ✅ Use **terraform.auto.tfvars** for defaults (dev)
5. ✅ Override in **workspace Terraform variables** for staging/prod
6. ✅ Use **Variable Sets** for common values (location, base tags)
7. ✅ Tag all resources with environment identifier
8. ✅ Use approval workflows for production deployments

This gives you complete isolation, security, and flexibility across environments and subscriptions! 🎉
