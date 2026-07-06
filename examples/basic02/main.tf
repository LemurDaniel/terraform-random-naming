
# ----------------------------------------------------------------------------
# Example: naming_id selects a *variant* of a resource.
#
# The resource string is <PROVIDER>::<RESOURCE>::<KIND>.
#   - kind is the third segment, which is also optional to use.
#   - ommitting kind will always fallback to ::default as kind.
#   - "Azure::Microsoft.Compute/disks::os" => kind=os).
#
# The <KIND> selects different abbreviations for the same resource:
#   - "Azure::Microsoft.Compute/disks::os" => osdisk-...
#   - "Azure::Microsoft.Compute/disks::data" => disk-...
#
# Additionally a <NAMING_ID> can be specified on every call.
#
# Resolution order (most specific wins):
#
#   abbreviations (default.abbreviations.yaml):
#     1. <type>::<naming_id>    <- naming_id has highest priority
#     2. <type>::<kind>
#     3. <type>::default
#     4. <type>
#
#   patterns (default.naming.yaml -> patterns.<provider>.<type>):
#     1. <naming_id>             <- naming_id has highest priority
#     2. <kind>  OR  default
#     3. provider default
#     4. global default
#
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

module "naming_vm_storage" {
  source = "../../modules/naming-generator"

  schema = module.schema

  resource = "Azure::Microsoft.Storage/storageAccounts::vm"
  // naming_id = "vm_pattern"
}

output "vm_storage" {
  # naming_id="vm" -> abbreviation "stvm" instead of "st"
  value = module.naming_vm_storage.name
}
