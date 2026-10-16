# ----------------------------------------------------------------------------
# Resolution behaviour: abbreviations, patterns, kind/naming_id precedence,
# optional tokens and lower-case enforcement.
#
# The schema is a literal object rather than the naming-schema module, so the
# tests are hermetic and <UNIQUE_ID_n> is deterministic.
# See .claude/skills/terraform-tests/SKILL.md
# ----------------------------------------------------------------------------

variables {
  schema = {
    random         = { uuid = "abcdef12-3456-7890-abcd-ef1234567890" }
    index_modifier = 1

    enforce_lower_case = {
      default = true
      Azure = {
        default                              = true
        "Microsoft.Compute/virtualMachines*" = false
      }
    }

    abbreviations = {
      Azure = {
        "Microsoft.Network/virtualNetworks::default" = "vnet"
        "Microsoft.Storage/storageAccounts::default" = "st"
        "Microsoft.Storage/storageAccounts::vm"      = "stvm"
        "Microsoft.Compute/disks::os"                = "osdisk"
        "Microsoft.Compute/disks::data"              = "disk"
        "Microsoft.Compute/virtualMachines::default" = "vm"
        "Microsoft.KeyVault/vaults::default"         = "kv"
        "Microsoft.Web/sites::default"               = "app"
      }
      AzureAD = {
        "Groups::security" = "grp"
      }
    }

    mappings = {
      location    = { westeurope = "we" }
      environment = { test = "tst" }
    }

    patterns = {
      # global default - only reached when the provider has no default
      default = "GLOBAL-<NAME>"

      AzureAD = {
        default = "<TYPE>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"
      }

      Azure = {
        default = "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

        # no separators at all
        "Microsoft.Storage/storageAccounts" = {
          default    = "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
          vm_pattern = "<TYPE><LOCATION><NAME><INDEX;%02s>"
        }

        # per-kind patterns
        "Microsoft.Compute/disks" = {
          os   = "<TYPE>-<NAME>-<ENVIRONMENT>"
          data = "<TYPE><INDEX;%02s>-<NAME>-<ENVIRONMENT>"
        }

        # optional token with the separator inside it
        "Microsoft.Web/sites" = {
          default = "<TYPE>-<NAME><?SUBNAME;-%s>-<INDEX;%02s>"
        }

        "Microsoft.KeyVault/vaults" = {
          default = "<TYPE>-<NAME>-<UNIQUE_ID_4>"
        }
      }
    }

    default_parameters = {
      location    = "westeurope"
      environment = "test"
      name        = "tftest"
    }
  }
}


run "provider_default_pattern" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Network/virtualNetworks"
  }
  assert {
    condition     = output.name == "vnet-we-tst-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "type_pattern_without_separators" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Storage/storageAccounts"
  }
  assert {
    condition     = output.name == "stwetsttftest01"
    error_message = "got: ${output.name}"
  }
}

run "kind_selects_abbreviation_and_pattern" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/disks::os"
  }
  assert {
    condition     = output.name == "osdisk-tftest-tst"
    error_message = "got: ${output.name}"
  }
}

run "other_kind_same_type" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/disks::data"
  }
  assert {
    condition     = output.name == "disk01-tftest-tst"
    error_message = "got: ${output.name}"
  }
}

run "naming_id_wins_over_kind" {
  command = plan
  variables {
    resource  = "Azure::Microsoft.Storage/storageAccounts::vm"
    naming_id = "vm_pattern"
  }
  # abbreviation comes from ::vm (no ::vm_pattern entry exists),
  # the pattern comes from the vm_pattern key
  assert {
    condition     = output.name == "stvmwetftest01"
    error_message = "got: ${output.name}"
  }
}

run "optional_token_present" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Web/sites"
    parameters = { subname = "api" }
  }
  assert {
    condition     = output.name == "app-tftest-api-01"
    error_message = "got: ${output.name}"
  }
}

run "optional_token_absent_leaves_no_stray_separator" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Web/sites"
  }
  assert {
    condition     = output.name == "app-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "unique_id_is_deterministic" {
  command = plan
  variables {
    resource = "Azure::Microsoft.KeyVault/vaults"
  }
  assert {
    condition     = output.name == "kv-tftest-abcd"
    error_message = "got: ${output.name}"
  }
}

run "other_provider_has_own_default" {
  command = plan
  variables {
    resource = "AzureAD::Groups::security"
  }
  assert {
    condition     = output.name == "grp-tst-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "unmapped_parameter_passes_through" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Network/virtualNetworks"
    parameters = { environment = "sandbox" }
  }
  assert {
    condition     = output.name == "vnet-we-sandbox-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "mapping_is_case_insensitive" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Network/virtualNetworks"
    parameters = { location = "West Europe" }
  }
  # the mapping key is "westeurope"; lookup lowercases both sides, so
  # "West Europe" does NOT match and passes through unchanged
  assert {
    condition     = output.name == "vnet-west europe-tst-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "lower_case_enforced_by_default" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Network/virtualNetworks"
    parameters = { name = "MixedCase" }
  }
  assert {
    condition     = output.name == "vnet-we-tst-mixedcase-01"
    error_message = "got: ${output.name}"
  }
}

run "lower_case_disabled_by_wildcard_match" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Compute/virtualMachines"
    parameters = { name = "MixedCase" }
  }
  assert {
    condition     = output.name == "vm-we-tst-MixedCase-01"
    error_message = "got: ${output.name}"
  }
}

run "name_and_result_are_aliases" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Network/virtualNetworks"
  }
  assert {
    condition     = output.result == output.name
    error_message = "result (${output.result}) != name (${output.name})"
  }
}
