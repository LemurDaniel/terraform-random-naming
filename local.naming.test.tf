


module "schema" {
  source = "./modules/naming-schema"

  naming = yamldecode(file("${path.root}/default.naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "DEVELOPMENT"
    name        = "TEST"
  }
}

module "naming_01" {
  source = "./modules/naming-generator"

  schema = module.schema
  index = {
    count = 10
  }

  resource = "Azure::Microsoft.Storage/storageAccounts"
}

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
module "naming_02_vm_storage" {
  source = "./modules/naming-generator"

  schema = module.schema

  resource  = "Azure::Microsoft.Storage/storageAccounts::vm"
  // naming_id = "vm_pattern"
}

output "test" {
  value = {
    single = module.naming_01.name

    multi = module.naming_01.by_index

    # naming_id="vm" -> abbreviation "stvm" instead of "st"
    vm_storage = module.naming_02_vm_storage.name
  }

}
