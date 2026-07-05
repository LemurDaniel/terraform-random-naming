terraform {
  required_version = ">=1.8.0"
  required_providers {
    terraform = {
      source = "terraform.io/builtin/terraform"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.107.0"
    }
  }
}
