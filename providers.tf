terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }

  # Terraform Cloud configuration
  # Update the organization and workspace names according to your setup
  cloud {
    organization = "qmaden-test"
    
    workspaces {
      name = "azure-aks-test-infra"
    }
  }
}

provider "azurerm" {
  features {}
  
  # Authentication via Service Principal
  # Set these as environment variables in Terraform Cloud:
  # - ARM_CLIENT_ID
  # - ARM_CLIENT_SECRET
  # - ARM_TENANT_ID
  # - ARM_SUBSCRIPTION_ID
}
