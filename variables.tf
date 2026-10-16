

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
  description = "(optional) The index range to generate names for. 'start' is the first index, 'count' is how many names to generate."
  type = object({
    start = optional(number, 0)
    count = optional(number, 1)
  })
  default = {
    start = 0
    count = 1
  }

  validation {
    condition     = var.index.count >= 1
    error_message = "index.count must be at least 1 - it is the number of names to generate."
  }

  validation {
    condition     = var.index.start >= 0
    error_message = "index.start must not be negative."
  }
}



variable "naming_id" {
  nullable    = false
  description = "(optional) An optional identifier to uniquely identify in the schema. If not set kind or default is used."
  type        = string
  default     = ""
}

variable "parameters" {
  nullable    = false
  description = "(optional) The parameters to use for naming. Use 'override' to override the naming generation."
  type        = map(any)
  default     = {}
}
