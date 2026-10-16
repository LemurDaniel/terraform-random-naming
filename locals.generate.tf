locals {

  name_generated = [
    for component in local.pattern :
    {
      isIndex = component.isIndex
      format  = component.paramFormat
      value = coalesce([
        # When NOT Parameter, return the value itself
        !component.isParameter ? component.value : null,

        #When is UniqueId return a substring of the random UUID
        component.isUniqueId ? substr(local.random_uuid, 0, component.uniqueIdNum) : null,

        # When Parameter, return the parameter value
        !component.isUniqueId && component.isParameter ? lookup(local.parameters, component.paramName, null) : null,

        # When Parameter and required, return the parameter value
        !component.isUniqueId && component.isParameter ? local.parameters[component.paramName] : null,
      ]...)
    } if(component.isRequired || (!component.isRequired && lookup(local.parameters, component.paramName, null) != null))
  ]

  # Generates exactly var.index.count names.
  #
  # local.index already carries the starting point (var.index.start, or an
  # 'index' override from var.parameters) plus the schema's index_modifier, so
  # the range here is a pure offset starting at 0. Iterating from
  # var.index.start instead would add the start a second time.
  name_formatted = [
    for offset in range(0, var.index.count) :
    [
      for component in local.name_generated :
      # Makes the index adjustment if the component is an index
      # else applies the correct formatting
      component.isIndex ? format(component.format, local.index + offset) : format(component.format, component.value)
    ]
  ]

  name_final = [
    for name in local.name_formatted :
    local.enforce_lower_case ? replace(lower(join("", compact(name))), "--", "-") : replace(join("", compact(name)), "--", "-")
  ]

}