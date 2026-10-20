# ----------------------------------------------------------------------------
# Integration test against the PUBLISHED naming-schema module.
#
# The suite under tests/ is hermetic: it feeds the generator a literal schema
# object, so it says nothing about whether the real schema module still
# produces a shape this generator accepts. This file closes that gap, and is
# the release gate for the cross-repo contract.
#
# It therefore does NOT live under tests/ - it needs the network and is slower.
# Run it explicitly:
#
#   terraform init -backend=false
#   terraform test -test-directory=tests-integration
#
# SCHEMA VERSION PIN: the version below is the latest published tag of
# LemurDaniel/naming-schema/random at the time of the last release. The
# release process refreshes it from the schema repo's newest tag before
# tagging - see .claude/skills/release/SKILL.md step 3c. Terraform requires a
# literal here, so it cannot be passed in as a variable.
#
# No `naming` override is passed: this asserts the bundled default convention,
# which is the stable published contract. Patterns containing <UNIQUE_ID_n>
# are avoided because the real module generates a random uuid.
# ----------------------------------------------------------------------------

run "schema" {
  module {
    source  = "LemurDaniel/naming-schema/random"
    version = "1.1.1"
  }

  variables {
    parameters = {
      location    = "westeurope"
      environment = "development"
      name        = "tftest"
    }
  }
}

run "schema_shape_is_accepted" {
  command = plan

  variables {
    schema   = run.schema
    resource = "Azure::Microsoft.Network/virtualNetworks"
  }

  assert {
    condition     = output.name == "vnet-we-dev-tftest-01"
    error_message = "got: ${output.name}"
  }
}

run "default_convention_abbreviations_resolve" {
  command = plan

  variables {
    schema   = run.schema
    resource = "Azure::Microsoft.Storage/storageAccounts"
  }

  assert {
    condition     = output.name == "stwedevtftest01"
    error_message = "got: ${output.name}"
  }
}

run "kind_resolves_against_published_abbreviations" {
  command = plan

  variables {
    schema   = run.schema
    resource = "Azure::Microsoft.Compute/disks::os"
  }

  assert {
    condition     = can(regex("^osdisk", output.name))
    error_message = "expected the os-disk abbreviation, got: ${output.name}"
  }
}

run "index_range_against_published_schema" {
  command = plan

  variables {
    schema   = run.schema
    resource = "Azure::Microsoft.Compute/virtualMachines"
    index    = { start = 0, count = 3 }
  }

  assert {
    condition     = length(output.at_index) == 3
    error_message = "expected 3 names, got ${length(output.at_index)}"
  }
}
