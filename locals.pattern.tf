
locals {

  /*
    This checks the schema.patterns for a matching pattern for the resource.
    It processes the schema patterns in the following order:
    - Match to <resourceType>.<id>
    - Match to <resourceType>.<kind>
    - Match to <resourceType>.default
    - Match to default
    - Fail with an error, if no pattern is found
  */

  patterns_provider = lookup(var.schema.patterns, local.resource.provider, {})

  pattern_selected = coalesce([
    // Match to <resourceType>.<id>
    lookup(lookup(local.patterns_provider, local.resource.type, {}), var.naming_id, null),
    // Match to <resourceType>.<kind>
    lookup(lookup(local.patterns_provider, local.resource.type, {}), local.resource.kind, null),
    // Match to <resourceType>.default
    lookup(lookup(local.patterns_provider, local.resource.type, {}), "default", null),
    // Match to Provider default
    lookup(local.patterns_provider, "default", null),
    // Fallback to global default
    var.schema.patterns.default
  ]...)



  /*
    This splits the selected pattern into components.

    For each component, metadata is added:
    - value: The value of the component, without any angle brackets.
    - format: The format string, if specified, otherwise defaults to "%s".
    - isRequired: A boolean indicating if the component is required (not optional).
    - isParameter: A boolean indicating if the component is a parameter (enclosed in angle brackets).  
  */

  pattern_compacted = compact(split("~&", replace(replace(local.pattern_selected, "<", "~&<"), ">", ">~&")))

  pattern_transform = [
    for component in local.pattern_compacted :
    {
      raw   = component
      value = replace(replace(component, "<", ""), ">", "")

      isRequired  = !strcontains(component, "?")
      isParameter = strcontains(component, "<") && strcontains(component, ">")
    }
  ]

  pattern_tranform_2 = [
    for component in local.pattern_transform :
    {
      raw   = component.raw
      value = component.value

      paramName   = replace(lower(split(";", component.value)[0]), "?", "")
      paramFormat = strcontains(component.value, ";") ? split(";", component.value)[1] : "%s"

      isRequired  = component.isRequired
      isParameter = component.isParameter

      isIndex    = strcontains(lower(component.value), "index") && component.isParameter
      isUniqueId = strcontains(lower(component.value), "unique_id") && component.isParameter
    }
  ]

  pattern = [
    for component in local.pattern_tranform_2 :
    {
      raw = component.raw

      value       = component.value
      paramName   = component.paramName
      paramFormat = component.paramFormat

      isRequired  = component.isRequired
      isParameter = component.isParameter

      isIndex     = component.isIndex
      isUniqueId  = component.isUniqueId
      uniqueIdNum = component.isUniqueId ? parseint(replace(component.paramName, "unique_id_", ""), 10) : null
    }
  ]
}
