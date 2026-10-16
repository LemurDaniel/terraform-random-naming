---
name: release
description: Cut a new version of this Terraform module and tag it so the Terraform Registry picks it up. Use when the user wants to release, publish, cut, bump, or tag a new module version ("release 1.1.0", "neue version", "bump patch", "tag a release", "publish to registry"), or asks which version is current / what changed since the last tag.
---

# Releasing a new module version

This repository is published on the Terraform Registry as a module. The Registry has no
"publish" API — **it discovers versions purely from git tags** on the repository. Cutting a
release therefore means: validate, tag with a semver tag, push the tag.

> **Any commit this process creates follows
> [git-commit-conventions](../git-commit-conventions/SKILL.md) — read it before committing.**
> In particular: no `Co-Authored-By` or "Generated with Claude Code" trailers, English
> imperative subject, and a body explaining the why. The same rule applies to the tag's
> annotation message and to any GitHub release notes.

## Tagging rules the Registry enforces

These are not style preferences — get them wrong and the version silently never appears:

- The tag must be **semantic versioning**: `x.y.z`, three numeric segments.
- An optional `v` prefix is allowed (`v1.2.0` and `1.2.0` both work). **Match whatever this
  repo already uses** — never mix the two styles in one repo.
- Tags with a pre-release suffix (`v1.2.0-rc1`) are listed but never resolved as `latest` and
  are not matched by `~>` constraints. Only cut one if the user explicitly asks.
- The tag must be pushed to the remote; a local tag does nothing.
- Never move or delete a published tag. Consumers pin against it and the Registry caches it.
  A mistake is fixed by cutting the next patch version, not by re-tagging.

## Steps

### 1. Establish the current version and tag style

```bash
git fetch --tags --prune
git tag --sort=-v:refname | head -5
```

Take the highest tag as the current version, and read the `v`-prefix style off it. If the repo
has no tags at all, the first release is `v1.0.0` (or `v0.1.0` if the user wants to signal
instability — ask).

Gaps in the tag history are normal (a version may have been skipped); always bump from the
**highest** existing tag, not from the count.

### 2. Decide the bump

If the user named a version or a bump level, use it. Otherwise look at what changed and
propose one, stating the reason:

```bash
git log <last-tag>..HEAD --oneline
git diff <last-tag>..HEAD --stat
```

For a Terraform module, the module's **public interface** is its variables and outputs, so:

- **major** — a variable was removed or renamed, a variable became required, a variable's type
  got stricter, an output was removed or renamed, or a generated *name* changes for an input
  that used to produce a different one. Renaming a name a consumer already applied forces
  resource replacement, so treat changed naming output as breaking.
- **minor** — a new optional variable, a new output, a new resource type / abbreviation /
  pattern in the convention, new functionality that leaves existing configs rendering the same.
- **patch** — bug fixes, docs, comments, examples, tests, formatting; nothing a consumer's plan
  would notice.

When unsure between minor and major, ask rather than guess — a wrong major is cosmetic, a
wrong minor breaks pinned consumers.

Commit bodies written per [git-commit-conventions](../git-commit-conventions/SKILL.md) state
whether a change is breaking and whether it alters a generated name; read them rather than
re-deriving the answer from the diff. Where a body is missing or says nothing (most of the
older history does), fall back to the diff of `variables.tf` and `outputfs.tf`.

### 3. Run the test suite — mandatory gate

**The test suite runs before anything is tagged, and it must pass.** A released tag is
immutable and consumers pin against it, so an untested release cannot be taken back, only
superseded.

```bash
terraform init -backend=false
terraform test
```

- **Green** → continue.
- **Red** → stop and report which `run` blocks failed. Do not tag. Fix the failure (or the
  test, if the test is what is wrong) and start over.
- **Fails before any assertion runs** (an init or variable error rather than an assertion) →
  the suite itself is broken, not the module. Say so explicitly, state that the release is
  therefore **unverified**, and ask whether to proceed anyway. Never let a broken suite read
  as a pass.

See [terraform-tests](../terraform-tests/SKILL.md) for the fixture pattern and how to interpret
a failure.

### 3b. Test against the newest published schema version — mandatory gate

The suite under `tests/` is hermetic: it feeds the generator a **literal** schema object, so it
cannot tell you whether the real `naming-schema` module still produces a shape this generator
accepts. That cross-repo contract is what actually breaks in the field, so it gets its own gate
against the **newest published tag** of the schema repo.

**Fetch the newest schema tag:**

```bash
git ls-remote --tags --refs https://github.com/LemurDaniel/terraform-random-naming-schema \
  | sed 's#.*refs/tags/##' | sort -V | tail -1
```

Use `sort -V`, not `sort` — plain lexicographic sort puts `v1.0.10` before `v1.0.9`. Read the
tag from the **remote**, not from a local clone, which may be stale or ahead of what is
actually published.

**Refresh the pin.** Strip the `v` to get the Registry version (`v1.0.3` → `1.0.3`) and compare
it to the `version` in `tests-integration/schema.tftest.hcl`. Terraform requires a literal
there, so it cannot be passed in — if it differs, edit the file. A changed pin is a real change
to what is tested: commit it (per
[git-commit-conventions](../git-commit-conventions/SKILL.md)) rather than tagging a dirty tree.

**Run it:**

```bash
terraform init -backend=false -test-directory=tests-integration
terraform test -test-directory=tests-integration
```

> [!IMPORTANT]
> `terraform init` only scans the **default** test directory. Without
> `-test-directory=tests-integration` on the `init` too, the run fails with "Module not
> installed" and never reaches an assertion — which is easy to misread as a broken test rather
> than a missing init.

- **Green** → continue.
- **Red** → stop. Determine which side moved: a generator change that the published schema no
  longer satisfies, or a schema release that changed its output shape. If the schema repo is the
  one at fault, **release the fix there first** and re-pin, rather than working around it here.
- This gate needs network access. If it cannot run, say so and state that the release is
  unverified against the published schema — do not substitute the hermetic suite for it.

### 3c. Remaining pre-release checks

All of these must also pass. Report failures and stop; do not tag a broken tree.

```bash
git status --porcelain          # must be empty — tag only committed state
git rev-parse --abbrev-ref HEAD # must be the default branch (main here, master in some repos)
git log origin/<branch>..HEAD --oneline   # must be empty — push commits before tagging

terraform fmt -check -recursive
terraform validate
```

### 4. Check version constraints and docs

A release is also a documentation change. Before tagging:

- `README.md` and `examples/**/*.tf` state constraints as **minimums** (`version = ">= 2.0.0"`,
  and `>= 1.1.0` for `naming-schema`), deliberately, so it is explicit which release a shown
  snippet actually needs. On a bump that the docs or examples rely on, raise those minimums and
  the "Version requirements" note in `README.md` to the version being cut. Do not convert them
  to `~>`: a `~> 1.0` constraint never resolves a `2.x` release, which is how examples end up
  silently pinning readers to an old major.
- Check that `README.md` still matches the actual `variables.tf` and outputs — a release is the
  point where docs drift becomes visible to consumers.
- If this module depends on the companion module (`LemurDaniel/naming-schema/random`) and that
  side got a breaking change, bump its constraint here too, and release the dependency first.

Commit any such changes before tagging, so the tag contains them — using
[git-commit-conventions](../git-commit-conventions/SKILL.md) for the message, and splitting
docs/constraint changes from logic changes as that skill requires. Push the commit before
tagging; a tag on an unpushed commit cannot be resolved by the Registry.

### 5. Tag and push

Use an **annotated** tag — the Registry and `git describe` both prefer them, and the message
becomes the release note. Write the annotation the way
[git-commit-conventions](../git-commit-conventions/SKILL.md) describes a commit message:
English, imperative, no attribution trailers.

```bash
git tag -a v1.2.0 -m "v1.2.0

- <change one>
- <change two>"

git push origin v1.2.0
```

Push the tag by name, not with `--tags`, so a stray local tag is never published by accident.

### 6. Confirm

- The Registry re-scans on a webhook and usually shows the version within a few minutes; it can
  take longer. The new version appears at
  `https://registry.terraform.io/modules/LemurDaniel/naming/random/<version>`.
- If the repo has GitHub releases and the `gh` CLI is available, optionally mirror the tag:
  `gh release create v1.2.0 --notes "..."`. `gh` is **not** required for the Registry to pick
  up the version — skip this if `gh` is not installed.
- Report the tagged version, the bump level with its reason, and what still needs the user's
  attention.

## Related repositories

The companion schema module lives in `terraform-random-naming-schema` and is released the same
way, but its default branch is **`master`**, not `main`. Check the branch per repo instead of
assuming.
