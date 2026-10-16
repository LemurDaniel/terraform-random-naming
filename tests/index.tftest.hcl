# ----------------------------------------------------------------------------
# Index behaviour: index.count is the NUMBER of names, index.start is the first
# index, and index_modifier shifts both.
#
# output.at_index is a tuple, so it is compared as a joined string and its
# length asserted separately - see .claude/skills/terraform-tests/SKILL.md
# ----------------------------------------------------------------------------

variables {
  schema = {
    random         = { uuid = "abcdef12-3456-7890-abcd-ef1234567890" }
    index_modifier = 1

    enforce_lower_case = { default = true }

    abbreviations = {
      Azure = {
        "Microsoft.Compute/virtualMachines::default" = "vm"
      }
    }

    mappings = {
      environment = { test = "tst" }
    }

    patterns = {
      default = "<TYPE>-<NAME>-<INDEX;%02s>"
      Azure = {
        default = "<TYPE>-<NAME>-<INDEX;%02s>"
      }
    }

    default_parameters = {
      environment = "test"
      name        = "tftest"
    }
  }
}


run "default_is_a_single_name" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/virtualMachines"
  }
  assert {
    condition     = output.name == "vm-tftest-01"
    error_message = "got: ${output.name}"
  }
  assert {
    condition     = length(output.at_index) == 1
    error_message = "expected 1 name, got ${length(output.at_index)}"
  }
}

run "count_is_the_number_of_names" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/virtualMachines"
    index    = { start = 0, count = 5 }
  }
  assert {
    condition = join(",", output.at_index) == join(",", [
      "vm-tftest-01",
      "vm-tftest-02",
      "vm-tftest-03",
      "vm-tftest-04",
      "vm-tftest-05",
    ])
    error_message = "got: ${join(",", output.at_index)}"
  }
  assert {
    condition     = length(output.at_index) == 5
    error_message = "expected 5 names, got ${length(output.at_index)}"
  }
}

run "start_offsets_without_being_counted_twice" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/virtualMachines"
    index    = { start = 2, count = 5 }
  }
  # start=2 plus index_modifier=1 => first index 03, and still 5 names.
  assert {
    condition = join(",", output.at_index) == join(",", [
      "vm-tftest-03",
      "vm-tftest-04",
      "vm-tftest-05",
      "vm-tftest-06",
      "vm-tftest-07",
    ])
    error_message = "got: ${join(",", output.at_index)}"
  }
  assert {
    condition     = length(output.at_index) == 5
    error_message = "expected 5 names, got ${length(output.at_index)}"
  }
}

run "name_output_is_the_first_of_the_range" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/virtualMachines"
    index    = { start = 3, count = 2 }
  }
  assert {
    condition     = output.name == "vm-tftest-04"
    error_message = "got: ${output.name}"
  }
}

run "index_can_be_overridden_via_parameters" {
  command = plan
  variables {
    resource   = "Azure::Microsoft.Compute/virtualMachines"
    parameters = { index = 7 }
  }
  assert {
    condition     = output.name == "vm-tftest-08"
    error_message = "got: ${output.name}"
  }
}

run "aliases_match_at_index" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Compute/virtualMachines"
    index    = { start = 0, count = 3 }
  }
  assert {
    condition     = join(",", output.by_index) == join(",", output.at_index)
    error_message = "by_index != at_index"
  }
  assert {
    condition     = join(",", output.index) == join(",", output.at_index)
    error_message = "index != at_index"
  }
}
