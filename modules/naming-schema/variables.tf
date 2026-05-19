
variable "convention" {
  nullable    = false
  description = "(Required) The naming convention to use."
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "other"], var.convention)
    error_message = "The naming convention '${var.convention}' was not found!"
  }
}

variable "naming" {
  nullable    = true
  description = "(Optional) The default patterns to use for the schema."
  type = object({
    index_modifier     = number
    enforce_lower_case = any

    mappings      = map(map(string))
    patterns      = any
    abbreviations = any

    default_parameters = optional(map(any))
  })
  default = null
}

variable "parameters" {
  nullable    = false
  description = "(Required) The default parameters to use for the schema."
  type        = map(any)
  default     = {}
}
