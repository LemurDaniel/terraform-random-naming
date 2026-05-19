
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

### Basic Resource Naming

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

module "disk_naming" {
  source = "./modules/naming-generator"

  schema   = module.schema
  resource = "Azure::Microsoft.Compute/disks::os"
}

output "disk_name" {
  value = module.disk_naming.name  # "osdsk-euwe-dev-myapp-01"
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
    count = 5  # generates vm-euwe-dev-myapp-01 through -05
  }
}

output "vm_names" {
  value = module.vm_naming.by_index  # ["vm-euwe-dev-myapp-01", ..., "vm-euwe-dev-myapp-05"]
}
```

---

## ⚙️ How It Works

### Resource Identifier Format

Every `naming-generator` call takes a `resource` string in the format:

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

### Abbreviation Resolution

For each `resource` string the module looks up the abbreviation in this order — first match wins:

```
type::id   →   type::kind   →   type::default   →   type
```

```yaml
# default.abbreviations.yaml
Azure:
  Microsoft.Compute/disks::os:      osdsk
  Microsoft.Compute/disks::data:    datadsk
  Microsoft.Compute/disks::default: disk

  # Same resource type, different abbreviation per kind
  Microsoft.Web/sites::default:     app
  Microsoft.Web/sites::function:    func
```

Pass `naming_id` to select an abbreviation (and pattern) by a specific identifier instead of kind:

```hcl
module "hub_vnet" {
  source     = "./modules/naming-generator"
  schema     = module.schema
  resource   = "Azure::Microsoft.Network/virtualNetworks"
  naming_id  = "hub"   # matches type::hub before falling back to type::kind
}
```

### Pattern Syntax

Patterns are strings with placeholder tokens replaced at evaluation time:

| Syntax | Behavior |
|---|---|
| `<PARAMETER>` | Required — fails if the parameter is missing |
| `<?PARAMETER;-%s>` | Optional — omitted silently if not provided |
| `<PARAMETER;%02s>` | Format string — uses printf-style formatting |

**Special tokens:**

| Token | Description |
|---|---|
| `<TYPE>` | Resolved abbreviation for the resource type |
| `<NAMING_ID>` | The ID or fallback to Kind on the current naming call |
| `<INDEX;format>` | Numeric index, incremented across the index range |
| `<UNIQUE_ID_n>` | First `n` characters of a random UUID (e.g. `<UNIQUE_ID_4>`) |

### Pattern Resolution

The module searches the schema patterns in this order — first match wins:

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

### Lowercase Enforcement

Controlled globally or per resource type. Provider-level settings take precedence over the global default:

```yaml
enforce_lower_case:
  default: true        # applies to all resources unless overridden

  azurerm:             # provider-level overrides
    default: false
    container_registry: true
    storage_account: true
```

Wildcard matching is supported — `azurerm*` matches all `azurerm_` resource types.

### Value Mappings

Full location and environment names are mapped to short codes before being inserted into the pattern. Matching is case-insensitive:

```yaml
mappings:
  location:
    westeurope:           euwe
    West Europe:          euwe
    germanywestcentral:   gewc
    Germany West Central: gewc

  environment:
    development: dev
    staging:     stg
    production:  prod
```

Any parameter passed to `naming-generator` is automatically mapped if a matching entry exists. Unmapped values are used as-is.

### Index Modifier

`index_modifier` shifts the numeric index before formatting. With `index_modifier: 1` and `index.start: 0`, the first generated name carries index `01` instead of `00`:

```yaml
index_modifier: 1
```

---

## 🗺️ Schema at a Glance

A naming schema is a plain YAML file — pass it via `yamldecode(file(...))` or replace it entirely with a different file per environment without changing any module code.

```yaml
#
# ################################################################################################
# ## (Optional) Define default parameters applied to every name generation.

default_parameters:

#
# ################################################################################################
# ## Define general settings.

# Shifts the numeric index before formatting.
# index_modifier: 1  →  index.start = 0 produces "01", not "00"
index_modifier: 1

# Enforce lowercase output globally or per resource type.
# Provider-level entries override the global default.
# Wildcard matching supported (e.g. azurerm* matches all azurerm_ types).
enforce_lower_case:
  default: true

  azurerm:
    default: false
    container_registry: true
    storage_account: true

#
# ################################################################################################
# ## Define mappings — full names are replaced by short codes before pattern substitution.

mappings:
  location:
    global:               glob
    westeurope:           euwe
    West Europe:          euwe
    germanynorth:         geno
    Germany North:        geno
    germanywestcentral:   gewc
    Germany West Central: gewc

  environment:
    development: dev
    staging:     stg
    test:        tst
    production:  prod

#
# ################################################################################################
# ## Define patterns per provider / resource type.
#
# Tokens:
#   <PARAMETER>        Required — fails if missing
#   <?PARAMETER;-%s>   Optional — omitted if not provided
#   <PARAMETER;%02s>   Printf-style format string
#   <TYPE>             Resolved abbreviation
#   <LOCATION>         Mapped location short code
#   <ENVIRONMENT>      Mapped environment short code
#   <NAME>             Application / workload name
#   <INDEX;%02s>       Numeric index with formatting
#   <UNIQUE_ID_n>      First n characters of a random UUID
#
# Pattern resolution order:
#   resourceType.id → resourceType.kind → resourceType.default → provider default → global default → error

patterns:
  # Global fallback
  default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>-<UNIQUE_ID_4>"

  Azure:
    # Provider fallback
    default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    Microsoft.ContainerRegistry/registries:
      default: "<TYPE>-<LOCATION>-<ENVIRONMENT>-<NAME>-<INDEX;%02s>"

    # Kind-based patterns — selected by ::kind or naming_id
    Microsoft.Compute/disks:
      os:   "<TYPE>-<NAME>-<ENVIRONMENT>"
      data: "<TYPE><INDEX;%02s>-<NAME>-<ENVIRONMENT>"

    # No separators for storage account names (Azure character restrictions)
    Microsoft.Storage/storageAccounts:
      default: "<TYPE><LOCATION><ENVIRONMENT><NAME><INDEX;%02s>"
```
