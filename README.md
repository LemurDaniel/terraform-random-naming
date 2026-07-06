
# Terraform Azure Naming Module

<div align="center">

<br><br>

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![YAML](https://img.shields.io/badge/YAML-CB171E?style=for-the-badge&logo=yaml&logoColor=white)

A consistent, schema-driven approach to Azure resource naming in Terraform.

</div>

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

Reference the module from the [Terraform Registry](https://registry.terraform.io/modules/LemurDaniel-Solutions/naming/azurerm), pinning a version:

```hcl
module "schema" {
  source  = "LemurDaniel-Solutions/naming/azurerm//modules/naming-schema"
  version = "~> 1.0"
  # ...
}
```

> [!NOTE]
> Full runnable examples live under [examples/](examples/): [basic01](examples/basic01/) (index ranges), [basic02](examples/basic02/) (`naming_id` variants), [basic03](examples/basic03/) (AzureAD resources). The snippets below use local `./modules/...` paths for brevity — replace `source` with the registry address above when consuming this module from another repository.

The `naming-schema` module can be consumed in **two ways**:

1. **Convention** — pick one of the bundled conventions shipped with the module (no YAML file required).
2. **Custom YAML** — supply your own schema file via the `naming` variable, partially overriding the bundled one.

### Option 1 — use a bundled convention

```hcl
module "schema" {
  source = "./modules/naming-schema"

  convention = "default"   # loads modules/naming-schema/convention/default.naming.yaml
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}
```

### Option 2 — provide a custom YAML

```hcl
module "schema" {
  source = "./modules/naming-schema"

  naming = yamldecode(file("${path.root}/default.naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}
```

> [!NOTE]
> The custom YAML overrides the bundled convention **per top-level key** (`patterns`, `abbreviations`, `mappings`, `enforce_lower_case`, `index_modifier`). Any key you leave unset in your custom YAML falls back to the value from the convention (defaults to `default`, or set `convention = "..."` to pick another base). So you can ship a minimal file that only redefines what you actually need to change.

### Basic Resource Naming

```hcl
module "disk_naming" {
  source = "./modules/naming-generator"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"
}

output "disk_name" {
  value = module.disk_naming.name  # "osdsk-we-dev-myapp-01"
}
```

### Kind-based Differentiation

Use `::kind` to give the same resource type different abbreviations depending on how it is used:

```hcl
module "disk_os" {
  source   = "./modules/naming-generator"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"    # abbreviation: osdsk
}

module "disk_data" {
  source   = "./modules/naming-generator"
  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::data"  # abbreviation: datadsk
}
```

### Multiple Names via Index

```hcl
module "vm_naming" {
  source = "./modules/naming-generator"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/virtualMachines"

  index = {
    start = 0
    count = 5  # generates vm-we-dev-myapp-01 through -05
  }
}

output "vm_names" {
  value = module.vm_naming.by_index  # ["vm-we-dev-myapp-01", ..., "vm-we-dev-myapp-05"]
}
```

---

## ⚙️ How It Works

<details>
<summary><strong>🧩 How to use</strong> — declare the central naming module once, reference it in all configurations</summary>

<br>

Declare a single `naming-schema` module in your root configuration. It loads the YAML schema (patterns, mappings, abbreviations, and settings — all in one file) once, and acts as the source of truth for every `naming-generator` call across the project.

You have two options for providing the schema:

**A. Use a bundled convention** — the module ships with ready-to-use conventions under [modules/naming-schema/convention/](modules/naming-schema/convention/). Pick one via the `convention` variable:

```hcl
# root module: declare ONCE
module "schema" {
  source = "./modules/naming-schema"

  convention = "default"   # loads the bundled default.naming.yaml
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}
```

**B. Provide your own YAML** — pass a decoded YAML via the `naming` variable to override parts of the bundled schema:

```hcl
# root module: declare ONCE
module "schema" {
  source = "./modules/naming-schema"

  naming = yamldecode(file("${path.root}/default.naming.yaml"))
  parameters = {
    location    = "westeurope"
    environment = "development"
    name        = "myapp"
  }
}
```

The custom YAML is merged on top of the active convention **per top-level key**: `patterns`, `abbreviations`, `mappings`, `enforce_lower_case`, and `index_modifier`. If a key is missing (or null) in your custom YAML, the value from the convention is used instead — so your file only needs to contain the parts you actually want to change. The active convention defaults to `default`; set `convention = "..."` if you want a different base.

Then pass `module.schema` to every `naming-generator` in your configuration:

```hcl
module "rg_naming" {
  source   = "./modules/naming-generator"
  schema   = module.schema
  resource = "Azure::Microsoft.Resources/resourceGroups"
}

module "storage_naming" {
  source   = "./modules/naming-generator"
  schema   = module.schema
  resource = "Azure::Microsoft.Storage/storageAccounts"
}
```

**Resource identifier format** — every `naming-generator` call expects a `resource` string in this shape:

```
Provider::Namespace/Type::kind
```

| Segment | Example | Description |
|---|---|---|
| `Provider` | `Azure` | Cloud provider — selects the pattern and abbreviation namespace |
| `Namespace/Type` | `Microsoft.Compute/disks` | Azure resource provider and type |
| `kind` *(optional)* | `os` | Differentiates resources of the same type; defaults to `default` |

```hcl
resource = "Azure::Microsoft.Compute/disks::os"
resource = "Azure::Microsoft.Storage/storageAccounts"   # kind defaults to "default"
```

To swap conventions between environments, just point `naming` at a different YAML file — no resource code changes required.

</details>

<details>
<summary><strong>🎨 Define your patterns</strong></summary>

<br>

Patterns are strings with placeholder tokens that get substituted at evaluation time.

**Token syntax:**

| Syntax | Behavior |
|---|---|
| `<PARAMETER>` | Required — fails if the parameter is missing |
| `<?PARAMETER;-%s>` | Optional — omitted silently if not provided |
| `<PARAMETER;%02s>` | Format string — uses printf-style formatting |

> [!IMPORTANT]
> **Put separators _inside_ the optional placeholder.**
>
> The format string after `;` is what gets rendered when the parameter is present — and dropped completely when it is missing. So a leading `-` (or `_`, `.`, etc.) inside the format becomes part of the optional segment:
>
> ```yaml
> # ✅ Correct — the leading "-" disappears together with SUBNAME
> default: "<TYPE>-<NAME><?SUBNAME;-%s>-<INDEX;%02s>"
> #                       └──────┬──────┘
> #                              └─ entire "-<value>" is dropped when SUBNAME is empty
>
> # With SUBNAME="api"  →  app-myapp-api-01
> # Without SUBNAME     →  app-myapp-01     (no stray dash)
>
> # ❌ Wrong — leaves a stray "-" when SUBNAME is missing
> default: "<TYPE>-<NAME>-<?SUBNAME;%s>-<INDEX;%02s>"
> # Without SUBNAME     →  app-myapp--01  (double dash!)
> ```

**Special tokens:**

| Token | Description |
|---|---|
| `<TYPE>` | Resolved abbreviation for the resource type |
| `<NAMING_ID>` | The ID, or fallback to Kind on the current naming call |
| `<INDEX;format>` | Numeric index, incremented across the index range |
| `<UNIQUE_ID_n>` | First `n` characters of a random UUID (e.g. `<UNIQUE_ID_4>`) |

**Pattern resolution order** — first match wins:

```
resourceType.id  →  resourceType.kind  →  resourceType.default  →  provider default  →  global default  →  error
```

```yaml
patterns:
  # Global fallback — used when no provider-specific pattern matches
  default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>-<UNIQUE_ID_4>"

  Azure:
    # Provider fallback
    default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    # Single pattern for a resource type (keyed by "default" kind)
    Microsoft.ContainerRegistry/registries:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    # Multiple patterns per resource type — selected by kind or naming_id
    Microsoft.Compute/disks:
      os:   "<TYPE>-<NAME>-<ENVIRONMENT>"
      data: "<TYPE><INDEX;%02s>-<NAME>-<ENVIRONMENT>"

    # Storage accounts: no separators, concatenated
    Microsoft.Storage/storageAccounts:
      default: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
```

**Lowercase enforcement** — controlled globally or per resource type. Provider-level entries override the global default. Wildcard matching is supported (`azurerm*` matches all `azurerm_` types):

```yaml
enforce_lower_case:
  default: true        # applies to all resources unless overridden

  azurerm:             # provider-level overrides
    default: false
    container_registry: true
    storage_account: true
```

**Index modifier** — shifts the numeric index before formatting. With `index_modifier: 1` and `index.start: 0`, the first generated name carries index `01` instead of `00`:

```yaml
index_modifier: 1
```

</details>

<details>
<summary><strong>🔤 Define your abbreviations</strong></summary>

<br>

Abbreviations live under the `abbreviations:` top-level key of the same naming schema YAML and map resource types to short codes used in the `<TYPE>` token. The default set is CAF-aligned and ships with the module — you can override individual entries or add your own provider namespaces alongside `Azure`.

**Abbreviation resolution order** — first match wins:

```
type::id   →   type::kind   →   type::default   →   type
```

```yaml
# default.naming.yaml
abbreviations:
  Azure:
    Microsoft.Compute/disks::os:      osdsk
    Microsoft.Compute/disks::data:    datadsk
    Microsoft.Compute/disks::default: disk

    # Same resource type, different abbreviation per kind
    Microsoft.Web/sites::default:     app
    Microsoft.Web/sites::function:    func

    # Storage account with explicit variant for VMs
    Microsoft.Storage/storageAccounts::default: st
    Microsoft.Storage/storageAccounts::vm:      stvm
```

**Picking a variant with `naming_id`** — pass `naming_id` to select an abbreviation by a specific identifier instead of kind. This takes precedence over the kind from the resource string:

```hcl
module "hub_vnet" {
  source    = "./modules/naming-generator"
  schema    = module.schema
  resource  = "Azure::Microsoft.Network/virtualNetworks"
  naming_id = "hub"   # matches type::hub before falling back to type::kind
}
```

</details>

<details>
<summary><strong>🗺️ Define your mappings</strong></summary>

<br>

Mappings translate full names (e.g. `West Europe`) to short codes (`we`) before they are inserted into the pattern. Matching is **case-insensitive**, so `westeurope` and `West Europe` resolve identically.

```yaml
mappings:
  location:
    global:               glob

    westeurope:           we
    West Europe:          we

    germanynorth:         gn
    Germany North:        gn

    germanywestcentral:   gwc
    Germany West Central: gwc

  environment:
    development: dev
    staging:     stg
    test:        tst
    production:  prod
```

Any parameter passed to `naming-generator` is automatically mapped if a matching entry exists. Unmapped values are used as-is, so you can add new parameter categories (e.g. `tier`, `region_group`) without changing any code — just define the mapping in YAML and reference it from a pattern via the matching `<TOKEN>`.

</details>
