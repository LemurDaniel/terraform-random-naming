
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
  source = "../../modules/naming-schema"

  convention = "default"
  naming     = yamldecode(file("${path.module}/naming.basic.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "DEVELOPMENT"
    name        = "TEST"
  }
}

module "naming_aad_group" {
  source = "../../modules/naming-generator"

  schema = module.schema

  resource = "AzureAD::Groups::security"
}

module "naming_aad_app" {
  source = "../../modules/naming-generator"

  schema = module.schema

  resource = "AzureAD::Applications"
}

output "aad_group" {
  value = module.naming_aad_group.name
}

output "aad_app" {
  value = module.naming_aad_app.name
}
