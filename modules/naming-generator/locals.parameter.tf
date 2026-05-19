
locals {

  resource = {
    full = var.resource

    # provider part of the resource.
    # First identifier of cloud provider.
    # Azure::Microsoft.Compute/disks => provider = Azure
    provider = split("::", var.resource)[0]

    # Retrives the actual resource part.
    # - Microsoft.Compute/virtualMachines => type = Microsoft.Compute/virtualMachines
    type = split("::", var.resource)[1]

    # The kind is a modifier for the resource type. 
    # - Azure::Microsoft.Compute/disks::os       => kind = os
    # - Azure::Microsoft.Compute/disks::data     => kind = data
    # - Azure::Microsoft.Compute/disks           => kind = default

    # This is used for
    # - mapping to the correct abbreviation in default.abbreviations.yaml
    # - (optional) define additional patterns only for that subkind in default.naming.yaml
    kind = length(split("::", var.resource)) > 2 ? split("::", var.resource)[2] : "default"
  }



  /*
    This checks the schema.resources for the correct abbreviation for the resource.
    It processes the schema resources in the following order:
    - >> Match to <resourceType>::<id>
    - >> Match to <resourceType>::<kind>
    - >> Match to <resourceType>::default
    - >> Match to <resourceType>
  */

  resources_provider = lookup(var.schema.abbreviations, local.resource.provider, {})
  abbreviation = coalesce([
    # >> Match to <resourceType>::<id>
    lookup(local.resources_provider, "${local.resource.type}::${var.naming_id}", null),
    # >> Match to <resourceType>::<kind>
    lookup(local.resources_provider, "${local.resource.type}::${local.resource.kind}", null),
    # >> Match to <resourceType>::default
    lookup(local.resources_provider, "${local.resource.type}::default", null),
    # >> Match to <resourceType>
    lookup(local.resources_provider, local.resource.type, null),
  ]...)



  /*
    Checks if lowercase enforcement is required for the resource.
    It processes the schema settings in the following order:
    - >> Match to <resourceType> - wildcards match allowed (e.g. azurerm*)
    - >> provider default - matches all resources of the provider
    - >> default - matches all resources  
  */

  random_uuid = replace(var.schema.random.uuid, "-", "")

  # The lowercase settings for the specific provider
  lowercase_provider = lookup(var.schema.enforce_lower_case, local.resource.provider, {})
  enforce_lower_case = coalesce(concat(
    [
      # >> Match to <resourceType> - wildcards match allowed (e.g. azurerm*)
      for resource, lower_case in local.lowercase_provider :
      lower_case if can(regex(replace(resource, "*", ".*"), local.resource.type))
    ],
    [
      # >> provider default - matches all resources of the provider
      lookup(local.lowercase_provider, "default", null),

      # >> default - matches all resources 
      lookup(var.schema.enforce_lower_case, "default", false)
    ]
  )...)



  /*
    This checks the schema.mappings for the correct abbreviation for the location.
    It processes the schema mappings in the following order:
    - >> Normalize the mapping keys to lowercase.
    - >> Iterate over all parameters and lookup the mapping for each parameter.
      - >> Lookup the mapping for a parameter, iterate through all values for a match
      - >> If a mapping is not found, the parameter is used as is.
  */

  # >> Normalize the mapping keys to lowercase.
  custom_mappings = {
    # This iterates through all parameters in the mappings
    # - location: <mappings>
    # - environment: <mappings>
    for parameter, parameter_mappings in var.schema.mappings :

    # This normalizes all mapped parameters names and keys to lowercase
    lower(parameter) => {
      for key, value in parameter_mappings : lower(key) => value
    }
  }


  parameter_mappings = {

    # >> Iterate over all parameters and lookup the mapping for each parameter.
    #    Either in default_parameters or the provided var.parameters
    for param_name, param_value in merge(var.schema.default_parameters, var.parameters) :


    param_name => coalesce(concat(
      [
        # >> Lookup the mapping for a parameter, iterate through all values for a match.
        for mapping_name, mapping_value in lookup(local.custom_mappings, lower(param_name), {}) :
        # - if "West Europe" matches "West Europe" => use lower(euwe)
        mapping_value if lower(param_value) == lower(mapping_name)
      ],
      [
        # >> If a mapping is not found, the parameter is used as is.
        param_value
      ]
    )...)
  }

  /*
    Modifies the parameters for the naming schema.
    - >> Merges the default parameters with the provided parameters.
    - >> Applies the index modifier from the schema settings.
  */

  # >> Merges the default parameters with the provided parameters.
  parameters = merge(
    {
      index = var.index.start
    },
    // Will overwrite index when provided via parameters
    {
      for key, value in local.parameter_mappings : lower(key) => value
    },
    {
      naming_id    = length(var.naming_id) > 0 ? var.naming_id : local.resource.kind
      abbreviation = local.abbreviation
      type         = local.abbreviation
    }
  )

  # >> Applies the index modifier from the schema settings.
  index = local.parameters.index + var.schema.index_modifier

}
