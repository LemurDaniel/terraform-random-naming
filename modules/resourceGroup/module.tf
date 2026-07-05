module "naming" {
  source = "../naming-generator"

  resource = "Azure::Microsoft.Resources/resourceGroups"

  location   = var.location
  parameters = var.naming

  schema = var.naming_schema
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.name
  location = var.location

  tags = var.tags
}
