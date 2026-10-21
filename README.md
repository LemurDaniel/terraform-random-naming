
> [!CAUTION]
> ## ⚠️ This module is deprecated and no longer maintained
>
> It has been replaced by the **[LemurDaniel/naming Terraform provider](https://github.com/LemurDaniel/terraform-provider-naming)**.
> Please migrate to the provider — this module receives no further fixes or features.

# Terraform Naming Generator Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-LemurDaniel%2Fnaming%2Frandom-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://registry.terraform.io/modules/LemurDaniel/naming/random/latest)

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white)

<br>

A consistent, schema-driven approach to resource naming in Terraform.

> [!NOTE]
> AI disclaimer: Originally written by hand, then improved with the help of AI. The module is covered by terraform test. 🤖

📖 For more info and examples, see this module on [GitHub](https://github.com/LemurDaniel/terraform-random-naming) — or ask Claude with the link to the module.

---

## 🙏 Acknowledgments

- 🟣 **HashiCorp** for [Terraform](https://www.terraform.io/) and the amazing IaC tooling
- ☁️ **Microsoft** for [Azure](https://azure.microsoft.com/) and the extensive resource provider ecosystem
- 🔤 **CAF Naming Conventions** for the abbreviation guidelines this module is built around
- 💖 **Open Source** contributors and the Azure community for inspiration

---

## Why This Module?

- **Centralized Naming** — maintain conventions in one place, not scattered across modules.
- **Consistency** — all resources follow the same logic, regardless of provider or type.
- **Extensible** — add abbreviations, locations, or patterns in YAML, without touching any HCL.
- **Index-based Naming** — generate a full set of sequentially named resources in a single call.
- **YAML-driven** — swap the entire schema between environments without changing any resource code.

---

## 🚀 Quick Start

This module (the *generator*) renders names from a schema object. The schema itself comes from the companion [`naming-schema`](https://registry.terraform.io/modules/LemurDaniel/naming-schema/random) module, which loads and merges the YAML naming convention (patterns, abbreviations, mappings, settings).

Declare `naming-schema` **once** per configuration, then pass it to every generator call. Both modules come from the [Terraform Registry](https://registry.terraform.io/modules/LemurDaniel/naming/random) and should be pinned to a version:

```hcl
module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = ">= 1.1.0"

  # Omitting `naming` entirely uses the bundled "default" convention.
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}

module "naming_storage_account" {
  source  = "LemurDaniel/naming/random"
  version = ">= 2.0.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Storage/storageAccounts"
}

output "storage_account_name" {
  value = module.naming_storage_account.name  # "stwedevmyapp01"
}
```

> [!NOTE]
> All names on this page assume the bundled `default` convention, which sets `index_modifier: 1` — so the first index renders as `01`. The examples under [examples/](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples) override this to `0` where noted, and then render `00`.

> [!IMPORTANT]
> **Version requirements.** This page and the examples require **`naming-schema` >= 1.1.0**, which merges a custom YAML convention per key over the bundled default — earlier versions replaced `patterns` wholesale, so a partial convention produced no patterns at all. They also require **`naming` (this module) >= 2.0.0**, where `index.count` is the number of names to generate rather than the range's exclusive upper bound. Both are stated as minimums rather than `~>` so it is explicit what the examples depend on; pin them with `~>` in your own configuration.

### Basic Resource Naming

```hcl
module "disk_naming" {
  source  = "LemurDaniel/naming/random"
  version = ">= 2.0.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"
}

output "disk_name" {
  value = module.disk_naming.name  # "osdisk-we-dev-myapp-01"
}
```

### Kind-based Differentiation

Use `::kind` to give the same resource type different abbreviations depending on how it is used:

```hcl
module "disk_os" {
  source   = "LemurDaniel/naming/random"
  version  = ">= 2.0.0"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"    # abbreviation: osdisk
}

module "disk_data" {
  source   = "LemurDaniel/naming/random"
  version  = ">= 2.0.0"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::data"  # abbreviation: disk
}
```

### Picking a Variant via `naming_id`

`naming_id` selects an abbreviation and pattern by a specific identifier, taking precedence over the `::kind` on the resource string ([examples/basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02)):

```hcl
module "vm_storage" {
  source    = "LemurDaniel/naming/random"
  version   = ">= 2.0.0"

  schema    = module.schema
  resource  = "Azure::Microsoft.Storage/storageAccounts::vm"
  naming_id = "vm_pattern"
}

output "vm_storage_name" {
  value = module.vm_storage.name  # "stvmwedevmyapp01"
}
```

Two independent lookups happen here, both keyed on `vm_pattern` first: the **abbreviation**
falls back to `storageAccounts::vm` → `stvm`, while the **pattern** matches the type's
`vm_pattern` key. [examples/basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02)
overrides that pattern to drop `<ENVIRONMENT>` and so renders `stvmwetest01` instead.

### Multiple Names via Index

`index.count` is **how many names to generate**; `index.start` is the first index:

```hcl
module "vm_naming" {
  source  = "LemurDaniel/naming/random"
  version = ">= 2.0.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/virtualMachines"

  index = {
    start = 0
    count = 5  # 5 names: vmdevmyapp01 through vmdevmyapp05
  }
}

output "vm_names" {
  value = module.vm_naming.by_index
}
```

`start` shifts the first index on top of `index_modifier`, and `count` is unaffected by it —
`{ start = 2, count = 5 }` yields five names numbered `03` through `07`.

### Other Providers (e.g. AzureAD)

The `resource` string is provider-agnostic — anything defined under `abbreviations`/`patterns` in the schema works, not just `Azure::...` ([examples/basic03](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic03)):

```hcl
module "aad_group" {
  source   = "LemurDaniel/naming/random"
  version  = ">= 2.0.0"

  schema   = module.schema
  resource = "AzureAD::Groups::security"
}

output "aad_group_name" {
  value = module.aad_group.name  # "grp-dev-myapp-01"
}
```

---

## Examples

Full runnable configurations live under [examples/](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples), each pairing the `naming-schema` module with this generator:

- [basic01](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic01) — a custom YAML override (`index_modifier: 0`) and generating a single name.
- [basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02) — using `naming_id` to select an alternate abbreviation/pattern for the same resource type.
- [basic03](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic03) — naming `AzureAD` resources (groups, applications), which have no `<LOCATION>` token.

Naming conventions are just YAML. Pass one into `naming-schema` via its `naming` input:

```hcl
module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = ">= 1.1.0"

  naming = yamldecode(file("${path.root}/naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}
```

**Every key is merged per entry over the bundled `default` convention, and your value wins.** So a `naming.yaml` only contains what actually differs — `basic01`'s is one line:

```yaml
index_modifier: 0
```

Overriding a single pattern leaves every other pattern in place (`basic03`):

```yaml
patterns:
  AzureAD:
    default: "<TYPE>-<NAME>-<ENVIRONMENT>-<INDEX;%02s>"
```

The same applies at the resource-type level — this adds a variant without touching the type's `default` pattern (`basic02`):

```yaml
patterns:
  Azure:
    Microsoft.Storage/storageAccounts:
      vm_pattern: "<TYPE><LOCATION><NAME><INDEX;%02s>"
```

Everything you don't override comes from the bundled `default` convention ([`convention/default.naming.yaml`](https://github.com/LemurDaniel/terraform-random-naming-schema/blob/master/convention/default.naming.yaml) in the companion [`terraform-random-naming-schema`](https://github.com/LemurDaniel/terraform-random-naming-schema) repository), which looks like this:

```yaml
mappings:
  location:
    westeurope: we
    West Europe: we
    eastus: eus
    East US: eus
    # ... every Azure region

  environment:
    development: dev
    staging: stg
    test: tst
    production: prod
    # ... more shortened environment names

abbreviations:
  Azure:
    Microsoft.Compute/disks::os: osdisk
    Microsoft.Compute/disks::data: disk
    Microsoft.Storage/storageAccounts::default: st
    Microsoft.Network/virtualNetworks::default: vnet
    # ... the full set of CAF resource abbreviations
```

Add an abbreviation or a region the same way — a single entry, merged in on top:

```yaml
abbreviations:
  Azure:
    Microsoft.Storage/storageAccounts::backup: stbkp

mappings:
  location:
    germanywestcentral: gwc
```

> [!NOTE]
> For a fully annotated reference covering every configurable key, see [`naming.full.yaml`](https://github.com/LemurDaniel/terraform-random-naming/blob/main/examples/basic01/naming.full.yaml).

---

## ⚙️ How It Works

<details>
<summary><strong>🧩 Resource Identifier Format</strong></summary>

<br>

Every generator call expects a `resource` string in this shape:

```
Provider::Namespace/Type::kind
```

| Segment | Example | Description |
|---|---|---|
| `Provider` | `Azure` | Cloud provider — selects the pattern and abbreviation namespace |
| `Namespace/Type` | `Microsoft.Compute/disks` | Resource provider and type |
| `kind` *(optional)* | `os` | Differentiates resources of the same type; defaults to `default` |

```hcl
resource = "Azure::Microsoft.Compute/disks::os"
resource = "Azure::Microsoft.Storage/storageAccounts"   # kind defaults to "default"
```

</details>

<details>
<summary><strong>🎨 Pattern Token Syntax</strong></summary>

<br>

Patterns are strings with placeholder tokens, resolved from `schema.patterns` and rendered at evaluation time.

| Token | Meaning |
|---|---|
| `<PARAMETER>` | Required — fails if the parameter is missing |
| `<?PARAMETER;-%s>` | Optional — the whole format (including any separator) is dropped when the parameter is missing |
| `<PARAMETER;%02s>` | Format string — printf-style formatting |
| `<TYPE>` | Resolved abbreviation for the resource (also available as `<ABBREVIATION>`) |
| `<NAMING_ID>` | The `naming_id`, falling back to `kind`, for the current call |
| `<INDEX;%02s>` | Numeric index, shifted by `index_modifier` and incremented across the index range |
| `<UNIQUE_ID_n>` | First `n` characters of a random UUID (e.g. `<UNIQUE_ID_4>`) |

Token names are matched case-insensitively against the available parameters, so any key from
`parameters`/`default_parameters` can be referenced as `<MY_KEY>`.

> [!IMPORTANT]
> **Put separators _inside_ the optional placeholder.**
>
> ```yaml
> # ✅ Correct — the leading "-" disappears together with SUBNAME
> default: "<TYPE>-<NAME><?SUBNAME;-%s>-<INDEX;%02s>"
> # With SUBNAME="api"  →  app-myapp-api-01
> # Without SUBNAME     →  app-myapp-01     (no stray dash)
>
> # ❌ Wrong — leaves a stray "-" when SUBNAME is missing
> default: "<TYPE>-<NAME>-<?SUBNAME;%s>-<INDEX;%02s>"
> # Without SUBNAME     →  app-myapp--01    (collapsed to app-myapp-01, but don't rely on it)
> ```

**Pattern resolution order** — first match wins, looked up under `patterns.<provider>`:

```
<type>.<naming_id>  →  <type>.<kind>  →  <type>.default  →  <provider>.default  →  patterns.default  →  error
```

```yaml
patterns:
  default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>-<UNIQUE_ID_4>"

  AzureAD:
    default: "<TYPE>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"   # no <LOCATION> — AzureAD resources are global

  Azure:
    default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.Compute/disks:
      os:   "<TYPE>-<NAME>-<ENVIRONMENT>"
      data: "<TYPE><INDEX;%02s>-<NAME>-<ENVIRONMENT>"

    # Storage accounts: no separators, concatenated
    Microsoft.Storage/storageAccounts:
      default: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
```

**Index modifier** — shifts the numeric index before formatting. With `index_modifier: 1` and `index.start: 0`, the first generated name carries index `01` instead of `00`.

</details>

<details>
<summary><strong>🔤 Abbreviations</strong></summary>

<br>

Abbreviations live under `schema.abbreviations` and map resource types to short codes used in the `<TYPE>` token. The bundled `default` convention (from `naming-schema`) ships with the full set of [CAF resource abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

**Abbreviation resolution order** — first match wins:

```
type::naming_id   →   type::kind   →   type::default   →   type
```

```yaml
abbreviations:
  Azure:
    Microsoft.Compute/disks::os:      osdisk
    Microsoft.Compute/disks::data:    disk

    # Same resource type, different abbreviation per kind
    Microsoft.Web/sites::default:     app
    Microsoft.Web/sites::function:    func

    # Storage account with explicit variant for VMs
    Microsoft.Storage/storageAccounts::default: st
    Microsoft.Storage/storageAccounts::vm:      stvm
```

If no entry matches, the module fails rather than guessing an abbreviation.

`naming_id` takes precedence over `kind` and is passed explicitly on the generator call:

```hcl
module "vm_storage" {
  source    = "LemurDaniel/naming/random"
  version   = ">= 2.0.0"
  schema    = module.schema
  resource  = "Azure::Microsoft.Storage/storageAccounts::vm"
  naming_id = "vm_pattern"   # matches type::vm_pattern before falling back to type::vm (kind)
}
```

</details>

<details>
<summary><strong>🗺️ Mappings</strong></summary>

<br>

Mappings translate full parameter values (e.g. `West Europe`) to short codes (`we`) before they are inserted into the pattern. Matching is **case-insensitive**, so `westeurope` and `West Europe` resolve identically.

```yaml
mappings:
  location:
    westeurope: we
    West Europe: we

  environment:
    development: dev
    staging:     stg
    test:        tst
    production:  prod
```

Any parameter passed via `schema` (`default_parameters`) or the generator's own `parameters` input is automatically mapped if a matching entry exists. Unmapped values are used as-is, so new parameter categories (e.g. `tier`) work without any code change — just add the mapping in YAML and reference it from a pattern via the matching `<TOKEN>`.

</details>

<details>
<summary><strong>🔡 Lower-case Enforcement</strong></summary>

<br>

`schema.enforce_lower_case` decides whether a finished name is lower-cased. It resolves per
provider, with wildcard matching on the resource type:

```
<provider>.<type pattern>   →   <provider>.default   →   enforce_lower_case.default
```

```yaml
enforce_lower_case:
  default: true

  Azure:
    default: true
    "Microsoft.Compute/virtualMachines*": false
```

The bundled `default` convention sets `default: true`, so **every** name is lower-cased unless a
convention overrides it for the matching provider.

</details>

---

## 📥 Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `schema` | `object` | Yes | The resolved schema, i.e. the output of the [`naming-schema`](https://registry.terraform.io/modules/LemurDaniel/naming-schema/random) module. |
| `resource` | `string` | Yes | The resource identifier: `Provider::Namespace/Type::kind`. |
| `naming_id` | `string` | No (default `""`) | Selects a specific abbreviation/pattern variant, taking precedence over `kind`. |
| `index` | `object({ start, count })` | No (default `{ start = 0, count = 1 }`) | `start` is the first index, `count` is how many names to generate (must be >= 1). |
| `parameters` | `map(any)` | No (default `{}`) | Additional/overriding parameters merged on top of the schema's `default_parameters` for this call. |

## 📤 Outputs

| Name | Description |
|---|---|
| `name` | The final generated name for `index.start`. |
| `result` | Alias for `name`. |
| `at_index` | Array of names across the full `index` range. |
| `by_index` | Alias for `at_index`. |
| `index` | Alias for `at_index`. |
| `debug` | The resolved pattern components — useful when a pattern doesn't render as expected. |

---

## License

[MIT](https://github.com/LemurDaniel/terraform-random-naming/blob/main/LICENSE)
