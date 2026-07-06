
output "debug" {
  value = {
    components = local.name_generated
  }
}


/*

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  The outputs for naming.
  There are two outputs:
  - name: The final generated name based on the schema and parameters.
  - at_index: An array of names with different indices applied.

  Additionally there are aliases for the outputs:
  - result: An alias for 'name'.
  - by_index: An alias for 'at_index'.
  - index: An alias for 'at_index'.

  Use the name you prefer in your configuration.
*/


output "name" {
  description = "The final generated name based on the schema and parameters."
  value       = local.name_final[0]
}

output "result" {
  description = "The final generated name based on the schema and parameters. (alias for 'name')."
  value       = local.name_final[0]

}

output "at_index" {
  description = "The name generated at the specified index."
  value       = local.name_final
}

output "by_index" {
  description = "The names generated with the index applied. (alias for 'at_index')."
  value       = local.name_final
}

output "index" {
  description = "The names generated with the index applied. (alias for 'at_index')."
  value       = local.name_final
}

