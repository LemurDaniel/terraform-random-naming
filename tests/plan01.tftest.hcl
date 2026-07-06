
run "schema" {
  module {
    source = "./modules/naming-schema"
  }

  variables {
    parameters = {
      environment = "test"
      location    = "westeurope"
      name        = "tftest"
    }
  }
}

run "name_virtual_network" {
  command = plan
  plan_options {
    mode    = normal
    refresh = false
    replace = []
    target  = []
  }

  variables {
    schema   = run.schema
    resource = "azurerm_virtual_network"
    parameters = {
      environment = "test"
      location    = "westeurope"
      name        = "tftest"
    }
  }

  # verify that the generated name is correct.
  assert {
    condition     = output.name == "vnet-we-tst-tftest-01"
    error_message = "Generated Name is Invalid"
  }
}
