
# ----------------------------------------------------------------------------
# Example: basic resource naming with an index range.
#
# Declare the schema once, then generate a full set of sequentially
# named resources in a single naming-generator call.
# ----------------------------------------------------------------------------

module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = "~> 1.0"
  
  naming     = yamldecode(file("${path.module}/naming.basic.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "DEVELOPMENT"
    name        = "TEST"
  }
}

module "naming_storage_account" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema = module.schema
  resource = "Azure::Microsoft.Storage/storageAccounts"
}

output "single" {
  value = module.naming_storage_account.name
}