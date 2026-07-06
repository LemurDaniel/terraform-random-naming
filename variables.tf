

variable "schema" {
  nullable    = true
  description = "(Required) The schema to use for naming. If not set, the default schema is used."
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

}

variable "resource" {
  nullable    = false
  description = "(required) The resource to use for naming."
  type        = string
}



variable "index" {
  nullable    = false
  description = "(optional) The index to use for naming. If not set, the default index is used."
  type = object({
    start = optional(number, 0)
    count = optional(number, 1)
  })
  default = {
    start = 0
    count = 1
  }
}



variable "naming_id" {
  nullable    = false
  description = "(optional) An optional identifier to uniquely identify in the schema. If not set kind or default is used."
  type        = string
  default     = ""
}

variable "location" {
  nullable    = true
  description = "(optional) The location to use for naming."
  type        = string
  default     = null
}

variable "parameters" {
  nullable    = false
  description = "(optional) The parameters to use for naming. Use 'override' to override the naming generation."
  type        = map(any)
  default     = {}
}


variable "extend_attribute" {
  nullable    = false
  description = "(Optional) Name of the attribute to add to the object."
  type = string
  default = "name"
}

variable "extend_object" {
  nullable    = false
  description = "(Optional) Extend an object with naming parameter."
  type = any
  default = {}
}
