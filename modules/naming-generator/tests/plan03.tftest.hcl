
variables {

  convention = "default"

  location = "westeurope"

  naming = {
    environment = "test"
    name        = "tftest"
  }

}

run "storage_account" {
  command = apply
  plan_options {
    mode = normal
    refresh = false
    replace = []
    target  = []
  }


  variables {
    resource = "azurerm_storage_account"
  }

  # verify that the generated name is correct.
  assert {
    condition     = output.result == "stwetesttftest01"
    error_message = "Generated Name is Invalid"
  }
}
