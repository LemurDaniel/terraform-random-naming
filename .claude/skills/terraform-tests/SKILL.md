---
name: terraform-tests
description: Write, run, and fix the native Terraform tests (.tftest.hcl) for this naming module. Use when adding a test for a new resource type, abbreviation or pattern, when `terraform test` fails, when a generated name needs to be asserted, or when the user asks to test / verify / validate the module ("add a test", "test schreiben", "tests laufen lassen", "warum failt der test"). Covers the hermetic schema-object fixture, deterministic UNIQUE_ID, and the tuple-vs-list assertion trap.
---

# Testing the naming generator

## Two suites

| Directory | What it covers | Needs network |
|---|---|---|
| `tests/` | The generator in isolation, against a **literal** schema object | no |
| `tests-integration/` | The generator against the **published** `naming-schema` module | yes |

```bash
# the hermetic suite - the one you run while developing
terraform init -backend=false
terraform test

# the cross-repo contract - the release gate
terraform init -backend=false -test-directory=tests-integration
terraform test -test-directory=tests-integration
```

`terraform test` requires Terraform 1.8+ and runs every `*.tftest.hcl` in the test directory.

> [!IMPORTANT]
> `terraform init` only scans the **default** test directory. Running the integration suite
> without `-test-directory=tests-integration` on the `init` as well fails with "Module not
> installed" before any assertion runs — that is a missing init, not a failing test.

New behaviour goes in `tests/`. Only add to `tests-integration/` when the thing under test is
genuinely the contract with the schema module — its output shape, or an abbreviation/pattern
that has to exist in the published default convention. The schema version there is a literal
pin that the [release](../release/SKILL.md) process refreshes from the schema repo's newest
tag; do not try to pass it in as a variable, Terraform does not allow it.

## Build the fixture as a literal schema object — not from the schema module

The `schema` variable is a plain object (see `variables.tf`), so a test can construct it
inline. Do that instead of wiring in the `naming-schema` module via a `run` block, for two
reasons:

1. **No cross-repo dependency.** Sourcing `LemurDaniel/naming-schema/random` makes the tests
   need the network and pins them to a published version of a different repo — and the
   generator is what is under test, not the schema loader.
2. **`<UNIQUE_ID_n>` becomes deterministic.** The schema module generates a real
   `random_uuid`, so any pattern containing `<UNIQUE_ID_4>` produces an unassertable name. A
   literal `random = { uuid = "..." }` fixes the value, and `<UNIQUE_ID_4>` becomes the first
   4 characters of the uuid with dashes stripped.

The object must supply **every** attribute, since the variable's type has no `optional()`
markers — a missing one is a type error, not a default:

```hcl
variables {
  schema = {
    random             = { uuid = "abcdef12-3456-7890-abcd-ef1234567890" }
    index_modifier     = 1
    enforce_lower_case = { default = true }

    abbreviations = {
      Azure = {
        "Microsoft.Network/virtualNetworks::default" = "vnet"
        "Microsoft.Storage/storageAccounts::default" = "st"
      }
    }

    mappings = {
      location    = { westeurope = "we" }
      environment = { test = "tst" }
    }

    patterns = {
      default = "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"
      Azure = {
        default = "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"
        "Microsoft.Storage/storageAccounts" = {
          default = "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
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
```

A file-level `variables` block is shared by every `run` in that file; a `run`-level
`variables` block overrides it per case. Keep the schema at file level and vary only
`resource`, `naming_id`, `index` and `parameters` per run.

Keep each fixture **minimal and local to what it asserts** — a handful of abbreviations and
patterns, not a copy of the whole default convention. A test that fails should point at one
behaviour.

## `command = plan` is enough

The module declares no resources, only `locals` and `outputs`, so a plan fully evaluates every
name. Use `command = plan`; it is faster and needs no state. `command = apply` is only
necessary if a test ever pulls in the schema module (which creates `random_uuid`) — the
fixture above avoids that. The `plan_options` block in the existing files is noise and can be
dropped.

## Asserting names

Single name:

```hcl
run "virtual_network" {
  command = plan
  variables {
    resource = "Azure::Microsoft.Network/virtualNetworks"
  }
  assert {
    condition     = output.name == "vnet-we-tst-tftest-01"
    error_message = "got: ${output.name}"
  }
}
```

Always interpolate the **actual** value into `error_message`. `terraform test` prints the
message but not the computed value, so without it a failure tells you nothing.

> [!IMPORTANT]
> **`output.at_index` is a tuple, not a list.** Comparing it to a list literal fails with
> "LHS and RHS values are of different types" even when the elements match — including when
> wrapped in `tolist()`. Compare the joined strings, and assert the length separately:
>
> ```hcl
> assert {
>   condition = join(",", output.at_index) == join(",", [
>     "vnet-we-tst-tftest-01",
>     "vnet-we-tst-tftest-02",
>   ])
>   error_message = "got: ${join(",", output.at_index)}"
> }
>
> assert {
>   condition     = length(output.at_index) == 2
>   error_message = "expected 2 names, got ${length(output.at_index)}"
> }
> ```

## Deriving the expected name

Work it out from the fixture, then **run the test to confirm** — never commit an expected
value reasoned out by hand. The traps, in the order they bite:

- **`index_modifier` shifts every index.** With `index_modifier: 1` the first name ends in
  `01`; with `0` it ends in `00`. This is the single most common wrong expectation.
- **`index.count` is the number of names; `index.start` only shifts the first index.** With
  `index_modifier: 1`, `{ start = 2, count = 5 }` yields five names numbered `03` … `07`.
  Assert the length as well as the contents — an off-by-one in the range shows up as a
  missing or extra element, which a joined-string comparison alone reports confusingly.
- **`mappings` are applied before the pattern**, case-insensitively, so `environment = "test"`
  renders as `tst` when the mapping says so. Unmapped values pass through unchanged.
- **`enforce_lower_case.default` is `true`** in the real convention, so names come out
  lower-cased regardless of input casing. Set it in the fixture rather than relying on it.
- **A literal `--` in a finished name is collapsed to `-`.** Do not write a test that depends
  on that; test the optional-token form (`<?SUBNAME;-%s>`) instead.
- **A missing abbreviation fails the plan** rather than rendering an empty `<TYPE>`, so the
  fixture must define an abbreviation for every resource it names.

## What is worth a test

One `run` block per behaviour, named after it:

- a new resource type's abbreviation and pattern resolving end to end
- separator-free patterns (storage accounts) — catches a stray `-`
- `::kind` selecting a different abbreviation for the same type (`disks::os` vs `disks::data`)
- `naming_id` taking precedence over `kind`
- each fallback level actually falling back: `type.<naming_id>` → `type.<kind>` →
  `type.default` → `<provider>.default` → `patterns.default`
- an optional token both present and absent
- `<UNIQUE_ID_n>` against the fixed fixture uuid
- an index range, asserting both contents and length

## Related

- A test change is its own commit — see
  [git-commit-conventions](../git-commit-conventions/SKILL.md).
- The suite is a hard gate before tagging a version — see
  [release](../release/SKILL.md).
