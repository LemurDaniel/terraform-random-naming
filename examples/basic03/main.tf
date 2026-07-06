
# ----------------------------------------------------------------------------
# Example: AzureAD provider.
#
# AzureAD resources are global (no location), so the pattern omits <LOCATION>:
#   AzureAD: default: "<TYPE>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"
#
# Available kinds:
#   Groups::default / Groups::security  => grp-...
#   Groups::m365                        => grpm-...
#   Applications::default               => app-...
#   ServicePrincipals::default          => sp-...
# ----------------------------------------------------------------------------

module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = "~> 1.0"

  naming = yamldecode(file("${path.module}/naming.basic.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "DEVELOPMENT"
    name        = "TEST"
  }
}

module "naming_aad_group" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "AzureAD::Groups::security"
}

module "naming_aad_app" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "AzureAD::Applications"
}

output "aad_group" {
  value = module.naming_aad_group.name
}

output "aad_app" {
  value = module.naming_aad_app.name
}
