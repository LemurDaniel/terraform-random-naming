# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Module Does

This is a schema-driven Terraform module for generating consistent Azure resource names following Microsoft's Cloud Adoption Framework (CAF) conventions. A YAML schema drives all naming logic — patterns, abbreviations, mappings, and settings — so new resource types can be added without changing HCL.

## Repository Layout

**The repository root *is* the module** — the name generator, published on the Terraform Registry as [`LemurDaniel/naming/random`](https://registry.terraform.io/modules/LemurDaniel/naming/random). There are no submodules under `modules/`.

| Path | Purpose |
|---|---|
| `variables.tf`, `outputs.tf` | The module's public interface |
| `locals.parameter.tf` | Parses the `resource` identifier; resolves abbreviation, lower-case setting and parameter mappings |
| `locals.pattern.tf` | Resolves the pattern and splits it into typed components |
| `locals.generate.tf` | Renders the components into the final name(s) |
| `tests/` | Hermetic tests — literal schema object, no network |
| `tests-integration/` | Tests against the published schema module — needs network |
| `examples/basic01..03/` | Runnable scratchpad configs, not consumable modules |

The companion **schema** module lives in a **separate repository**, `terraform-random-naming-schema` (published as `LemurDaniel/naming-schema/random`, default branch `master`). It owns `convention/default.naming.yaml` and merges a caller's YAML over it. This repo consumes its output as the `schema` input. Changes that span both repos are separate commits in separate repos, and the schema side is released first.

## Commands

```bash
# Hermetic suite (requires Terraform 1.8+)
terraform init -backend=false
terraform test

# Cross-repo suite against the published schema module.
# NOTE: the flag is needed on `init` too, or the run fails with "Module not installed".
terraform init -backend=false -test-directory=tests-integration
terraform test -test-directory=tests-integration

terraform fmt -check -recursive
terraform validate
```

## Skills

Repository workflows live in `.claude/skills/` — read the relevant one before acting:

- **`release`** — cutting a version and tagging it for the Registry
- **`git-commit-conventions`** — commit format and the no-attribution rule
- **`terraform-tests`** — writing and fixing `.tftest.hcl` tests

## Module Interface

- `schema` *(required)* — the resolved schema object, i.e. the output of the `naming-schema` module. Every attribute is required, so a test fixture must supply all of them.
- `resource` *(required)* — `"Provider::Namespace/Type::kind"`, e.g. `"Azure::Microsoft.Compute/disks::os"`. `kind` is optional and defaults to `default`.
- `naming_id` — variant selector; takes precedence over `kind`.
- `index` — `{ start, count }`. `count` is **how many names** to generate; `start` is the first index.
- `parameters` — merged on top of the schema's `default_parameters` for this call.

Outputs: `name` / `result` (first name), `at_index` / `by_index` / `index` (all names), and `debug` (resolved pattern components).

## Pattern Token Syntax

Patterns use angle-bracket tokens rendered by `locals.generate.tf`:

| Token | Meaning |
|---|---|
| `<PARAM>` | Required parameter — errors if missing |
| `<?PARAM;-separator%s>` | Optional parameter with inline separator |
| `<PARAM;%02s>` | Printf-formatted parameter |
| `<TYPE>` | Resolved abbreviation for the resource (also `<ABBREVIATION>`) |
| `<NAMING_ID>` | The `naming_id`, falling back to `kind` |
| `<INDEX;%02s>` | Numeric index (shifted by `index_modifier`) |
| `<UNIQUE_ID_n>` | First *n* chars of a random UUID |

Put separators **inside** optional tokens (`<?SUBNAME;-%s>`), or a missing parameter leaves a stray separator.

## Resolution Hierarchy

Abbreviations (`locals.parameter.tf`) — first match wins:

1. `<type>::<naming_id>`
2. `<type>::<kind>`
3. `<type>::default`
4. `<type>`

Patterns (`locals.pattern.tf`), looked up under `patterns.<provider>` — first match wins:

1. `<type>.<naming_id>`
2. `<type>.<kind>`
3. `<type>.default`
4. `<provider>.default`
5. `patterns.default`

Lower-case enforcement resolves `<provider>.<type pattern>` (with `*` expanded to `.*`) → `<provider>.default` → `default`. The bundled convention sets `default: true`, so names are lower-cased unless a convention overrides it.

## Gotchas

- **`index_modifier` shifts every index.** The default convention uses `1`, so the first name ends in `01`. Expected names in tests and docs are wrong most often because of this.
- **`output.at_index` is a tuple, not a list** — comparing it to a list literal fails on type even when the elements match, including via `tolist()`. Compare joined strings and assert the length separately.
- **Never document a generated name you have not rendered.** Point a scratch config at the local module path and apply it.
- **A literal `--` in a finished name is collapsed to `-`**, which masks a missing optional-token separator.
- **A missing abbreviation fails the plan** rather than rendering an empty `<TYPE>`.

## Updating Abbreviations

The abbreviations live in `convention/default.naming.yaml` in the **schema** repository and are currently maintained by hand against Microsoft's [CAF abbreviation list](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

A `generate.ps1` that scraped that page used to exist at `modules/naming-schema/generate.ps1` in **this** repo. It was deleted in `e0f27f8` ("remove unecessery files") when the schema moved to its own repository, and was never carried over — the schema repo's history starts fresh. It is recoverable if wanted:

```bash
git show e0f27f8^:modules/naming-schema/generate.ps1
```

Do not reference it as if it were present in either working tree.
