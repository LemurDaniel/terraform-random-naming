/*

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  Common or required variables for the resource group module.
  - location: The common location for resource deployment.
  - tags: The common tags used for resource deployment.
  - naming: The parameters to use for naming. Use 'override' to override the naming generation.
  - naming_schema: The schema to use for naming. From the naming-schema module.
*/

variable "location" {
  nullable    = false
  description = "(Required) The common location for resource deployment."
  type        = string
}

variable "tags" {
  nullable    = false
  description = "(Required) The common tags used for resource deployment."
  type        = map(string)
}

variable "naming" {
  nullable    = false
  description = "(required) The parameters to use for naming. Use 'override' to override the naming generation."
  type        = map(any)
}


variable "naming_schema" {
  nullable    = true
  description = "(optional) The schema to use for naming. Output of the naming-schema module."
  type = object({

    random = object({
      uuid = string
    })

    index_modifier     = number
    enforce_lower_case = any

    abbreviations = map(map(string))
    mappings      = map(map(string))
    patterns      = any

    default_parameters = map(any)
  })
  default = null
}
