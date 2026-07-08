
# Terraform Naming Generator Module

<div align="center">

<br><br>

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-LemurDaniel%2Fnaming%2Frandom-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://registry.terraform.io/modules/LemurDaniel/naming/random/latest)

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white)

A consistent, schema-driven approach to resource naming in Terraform.

📖 For more info and examples, see this module on [GitHub](https://github.com/LemurDaniel/terraform-random-naming) — or ask Claude with the link to the module.

</div>

```hcl
module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = "~> 1.0"

  naming     = yamldecode(file("${path.root}/naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}

module "storage_account_naming" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Storage/storageAccounts"
}

output "storage_account_name" {
  value = module.storage_account_naming.name  # "stwedevmyapp01"
}
```

Naming conventions are just YAML. The `naming.yaml` loaded above looks like this (`naming.basic.yaml`, see [GitHub](https://github.com/LemurDaniel/terraform-random-naming/blob/main/examples/basic01/naming.basic.yaml) if this link doesn't render):

```yaml
# Custom override on top of the "default" convention.
#
# NOTE: `patterns` is replaced wholesale when set (no per-key fallback), so it
# is copied here unmodified from modules/naming-schema/convention/default.naming.yaml.
# `index_modifier` below is the actual override this example demonstrates:
# indices now start at 00 instead of 01.

index_modifier: 0

patterns:
  default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>-<UNIQUE_ID_4>"

  AzureAD:
    default: "<TYPE>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

  Azure:
    default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME><?SUBNAME;-%s>-<INDEX;%02s>"

    Microsoft.Compute/virtualMachines:
      default: "<TYPE><ENVIRONMENT><NAME><INDEX;%02s>"

    Microsoft.ContainerRegistry/registries:
      default: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"

    Microsoft.Resources/resourceGroups:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.Network/virtualNetworks:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.Network/virtualNetworks/subnets:
      default: "<TYPE>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.Network/publicIPAddresses:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.Network/networkSecurityGroups:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.KeyVault/vaults:
      default: "<TYPE>-<ENVIRONMENT>-<NAME>-<UNIQUE_ID_4>"

    Microsoft.Storage/storageAccounts:
      default: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
      vm_pattern: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
```

This example only overrides `patterns` and `index_modifier` — `mappings` and `abbreviations` fall back to the bundled `default` convention (from [`convention/default.naming.yaml`](https://github.com/LemurDaniel/terraform-random-naming-schema/blob/master/convention/default.naming.yaml) in the companion [`terraform-random-naming-schema`](https://github.com/LemurDaniel/terraform-random-naming-schema) repository), which looks like this:

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

> [!NOTE]
> For a fully annotated reference covering every configurable key, see [`naming.full.yaml`](https://github.com/LemurDaniel/terraform-random-naming/blob/main/examples/basic01/naming.full.yaml).

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
- **Extensible** — add abbreviations, locations, or patterns without touching existing code.
- **Index-based Naming** — generate a full set of sequentially named resources in a single call.
- **YAML-driven** — swap the entire schema between environments without changing any resource code.

---

## 🚀 Quick Start

This module (the *generator*) renders names from a schema object. The schema itself comes from the companion [`naming-schema`](https://registry.terraform.io/modules/LemurDaniel/naming-schema/random) module, which loads and merges the YAML naming convention (patterns, abbreviations, mappings, settings).

Reference both from the [Terraform Registry](https://registry.terraform.io/modules/LemurDaniel/naming/random), pinning a version:

```hcl
module "schema" {
  source  = "LemurDaniel/naming-schema/random"
  version = "~> 1.0"

  naming     = yamldecode(file("${path.root}/naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}

module "naming_storage_account" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Storage/storageAccounts"
}

output "storage_account_name" {
  value = module.naming_storage_account.name  # "stwedevmyapp01"
}
```

> [!NOTE]
> Full runnable examples live under [examples/](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples): [basic01](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic01) (index ranges), [basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02) (`naming_id` variants), [basic03](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic03) (AzureAD resources).
>
> The `naming.yaml` referenced above is a custom override on top of the bundled `default` convention — see [`naming.basic.yaml`](https://github.com/LemurDaniel/terraform-random-naming/blob/main/examples/basic01/naming.basic.yaml) in the top example above for what it actually contains.

Declare `naming-schema` **once** per configuration, then pass its output (`module.schema`) to every `naming-generator` call:

```hcl
module "rg_naming" {
  source   = "LemurDaniel/naming/random"
  version  = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Resources/resourceGroups"
}

module "vnet_naming" {
  source   = "LemurDaniel/naming/random"
  version  = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Network/virtualNetworks"
}
```

See the [naming-schema README](https://registry.terraform.io/modules/LemurDaniel/naming-schema/random) for the two ways to configure the schema (bundled convention vs. custom YAML).

### Basic Resource Naming

```hcl
module "disk_naming" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"
}

output "disk_name" {
  value = module.disk_naming.name  # "osdisk-we-dev-myapp"
}
```

### Kind-based Differentiation

Use `::kind` to give the same resource type different abbreviations depending on how it is used:

```hcl
module "disk_os" {
  source   = "LemurDaniel/naming/random"
  version  = "~> 1.0"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"    # abbreviation: osdisk
}

module "disk_data" {
  source   = "LemurDaniel/naming/random"
  version  = "~> 1.0"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::data"  # abbreviation: disk
}
```

### Picking a Variant via `naming_id`

`naming_id` selects an abbreviation and pattern by a specific identifier, taking precedence over the `::kind` on the resource string ([examples/basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02)):

```hcl
module "vm_storage" {
  source    = "LemurDaniel/naming/random"
  version   = "~> 1.0"

  schema    = module.schema
  resource  = "Azure::Microsoft.Storage/storageAccounts::vm"
  naming_id = "vm_pattern"
}

output "vm_storage_name" {
  value = module.vm_storage.name  # "stvmwedevtest01"
}
```

### Multiple Names via Index

```hcl
module "vm_naming" {
  source  = "LemurDaniel/naming/random"
  version = "~> 1.0"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/virtualMachines"

  index = {
    start = 0
    count = 5  # generates vmdevmyapp01 through vmdevmyapp05
  }
}

output "vm_names" {
  value = module.vm_naming.by_index
}
```

### Other Providers (e.g. AzureAD)

The `resource` string is provider-agnostic — anything defined under `abbreviations`/`patterns` in the schema works, not just `Azure::...` ([examples/basic03](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic03)):

```hcl
module "aad_group" {
  source   = "LemurDaniel/naming/random"
  version  = "~> 1.0"

  schema   = module.schema
  resource = "AzureAD::Groups::security"
}

output "aad_group_name" {
  value = module.aad_group.name  # "grp-test-dev-01"
}
```

---

## ⚙️ How It Works

<details>
<summary><strong>🧩 Resource Identifier Format</strong></summary>

<br>

Every `naming-generator` call expects a `resource` string in this shape:

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
| `<TYPE>` | Resolved abbreviation for the resource |
| `<NAMING_ID>` | The `naming_id`, falling back to `kind`, for the current call |
| `<INDEX;%02s>` | Numeric index, shifted by `index_modifier` and incremented across the index range |
| `<UNIQUE_ID_n>` | First `n` characters of a random UUID (e.g. `<UNIQUE_ID_4>`) |

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
> # Without SUBNAME     →  app-myapp--01  (double dash!)
> ```

**Pattern resolution order** — first match wins:

```
resourceType::naming_id  →  resourceType::kind  →  resourceType::default  →  provider default  →  global default  →  error
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

`naming_id` takes precedence over `kind` and is passed explicitly on the `naming-generator` call:

```hcl
module "vm_storage" {
  source    = "LemurDaniel/naming/random"
  version   = "~> 1.0"
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

---

## 📥 Inputs

| Name | Type | Required | Description |
|---|---|---|---|
| `schema` | `object` | Yes | The resolved schema, i.e. the output of the [`naming-schema`](https://registry.terraform.io/modules/LemurDaniel/naming-schema/random) module. |
| `resource` | `string` | Yes | The resource identifier: `Provider::Namespace/Type::kind`. |
| `naming_id` | `string` | No (default `""`) | Selects a specific abbreviation/pattern variant, taking precedence over `kind`. |
| `index` | `object({ start, count })` | No (default `{ start = 0, count = 1 }`) | Range of indices to generate names for. |
| `parameters` | `map(any)` | No (default `{}`) | Additional/overriding parameters merged on top of the schema's `default_parameters` for this call. |

## 📤 Outputs

| Name | Description |
|---|---|
| `name` | The final generated name for `index.start`. |
| `result` | Alias for `name`. |
| `at_index` | Array of names across the full `index` range. |
| `by_index` | Alias for `at_index`. |
| `index` | Alias for `at_index`. |

---

## Examples

Full runnable configurations live under [examples/](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples), each pairing `naming-schema` with `naming-generator`:

- [basic01](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic01) — a custom YAML override (`index_modifier: 0`) and generating a single name.
- [basic02](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic02) — using `naming_id` to select an alternate abbreviation/pattern for the same resource type.
- [basic03](https://github.com/LemurDaniel/terraform-random-naming/tree/main/examples/basic03) — naming `AzureAD` resources (groups, applications), which have no `<LOCATION>` token.

Each example directory also ships a [`naming.full.yaml`](https://github.com/LemurDaniel/terraform-random-naming/blob/main/examples/basic01/naming.full.yaml) — an annotated reference covering every configurable key of the schema, not wired into `main.tf`, meant as a copy-paste starting point for a fully custom convention.

## License

[MIT](https://github.com/LemurDaniel/terraform-random-naming/blob/main/LICENSE)
