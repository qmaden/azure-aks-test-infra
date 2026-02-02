# terraform.auto.tfvars.example
# 
# This file demonstrates how to use auto-loaded variables in Terraform Cloud/Enterprise
# Files with .auto.tfvars extension are automatically loaded by Terraform Cloud
# 
# To use this file:
# 1. Copy it to terraform.auto.tfvars (which is gitignored)
# 2. Update the values below
# 3. Commit to your repository
# 
# Note: terraform.auto.tfvars will be automatically loaded in Terraform Cloud
# for workspaces using Terraform 0.10.0 or later

resource_group_name              = "rg-aks-test-centralindia"
location                         = "centralindia"
storage_account_name             = "stakstest12345test"  # Must be globally unique across all of Azure
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

tags = {
  Environment = "Test"
  ManagedBy   = "Terraform"
  Project     = "AKS-Test"
}
