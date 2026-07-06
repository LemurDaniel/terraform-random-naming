
variables {

  convention = "default"

  location = "westeurope"

  naming = {
    environment = "test"
    name        = "tftest"
  }

}

run "subnet" {
  command = apply
  plan_options {
    mode = normal
    refresh = false
    replace = []
    target  = []
  }


  variables {
    resource = "azurerm_subnet"
  }

  # verify that the generated name is correct.
  assert {
    condition     = output.result == "snet-we-test-tftest-01"
    error_message = "Generated Name is Invalid"
  }
}