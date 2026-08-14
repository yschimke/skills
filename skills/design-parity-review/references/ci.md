# Running parity in CI

Two reusable workflows, called from the consumer repo. They are separate on
purpose: the design side and the code side move at completely different
speeds — see [reference-cache.md](./reference-cache.md).

## The run

```yaml
# .github/workflows/design-parity.yml
on:
  pull_request:
  push:
    branches: [main]
jobs:
  parity:
    uses: yschimke/design-parity/.github/workflows/design-parity-reusable.yml@main
    permissions:
      contents: write
    with:
      module: ':catalog'
      shards: 1
      reference-cache-branch: design-parity/reference
    secrets:
      figma-token: ${{ secrets.FIGMA_TOKEN }}
```

Mode is auto-selected from the event, mirroring the sibling `compose-preview`
`apply` action:

- **`pull_request` → comment.** Read the changed files, keep the
  `design-map.json` components whose file changed (a PR touching none is
  treated as non-UI and skipped), run the pipeline, post/update a **single**
  verdict comment (idempotent via the report marker). Exits non-zero only
  when the direction blocks — i.e. `design-led` plus a failure.
- **`push` to the development branch → baseline.** Render the full mapped
  surface and publish browsable artifacts to `design-parity/<dev-branch>`.
- **`skip`** — nothing applies.

`mode: baseline|comment|skip` overrides the selector.

## Two levers, in order: scope, then shard

A parity run costs roughly `fixed + per_component × components`. The fixed
part is the candidate render's Gradle configure + compile (~4 min, paid
whether one preview is drawn or a thousand); the marginal part is one render
+ reference fetch + diff per component.

### Lever 1 — scope the render (not optional, costs no coverage)

A catalog module draws far more previews than any component maps to:
m3-catalog draws **1,095** and maps **77**. Only mapped components are ever
compared, so excluding the unmapped previews removes work nobody was going
to look at. Doing this by hand took one catalog from **~43 min to ~4**.

The workflow derives the exclusion itself, from the `compose-preview`
discovery manifest:

```
everything in previews.json  −  the previews this shard compares
```

Point `preview-manifest` at that file (empty derives it from `module`:
`:a:b` ⇒ `a/b/build/compose-previews/previews.json`).

**If the manifest is absent the render is NOT scoped** — every shard draws
the whole module. The run warns loudly rather than silently paying it, so
treat that warning as the thing to fix first.

> Deriving the exclusion from `design-map.json` instead does not work: taken
> against the map, a shard names only the previews the *other shards* own and
> says nothing about the 1,018 unmapped ones — every shard still renders the
> whole module and sharding divides nothing.

### Lever 2 — shard what's left

`shards: N` runs N jobs, each rendering and comparing a **disjoint slice of
the same exhaustive component list**; `design-parity merge` unions them into
the artifact set one serial run would have produced.

**Try `shards: 1` with a correct `preview-manifest` first.** It is a complete
answer for most catalogs, and it is the one that does not multiply the
reference API's rate limit by N. Two reasons:

- Only the **marginal** cost divides — every shard pays the ~4 min `fixed`
  cost in full, because every shard compiles the module before drawing
  anything. So **4–8 is the useful range**; a large fleet is buying Gradle
  configure time, not throughput (8 → 16 shards improved one wall clock by
  ~3 minutes).
- Each shard is an independent client of the reference API. N shards make N
  concurrent callers on one token, the adapter surfaces a 429 as a soft
  failure, and **the run stays green** — so an over-sharded run degrades into
  silent under-coverage. Exactly the failure the reference cache exists to
  prevent; if you shard hard, cache first.

More shards than components is allowed — the tail shards no-op.

**The one invariant:** each shard's render and its comparison must select the
same components, or the shard renders previews it never diffs and diffs
components it never rendered — which surfaces only as "no candidate render
available" warnings on a green run. Both sides therefore read the partition
from the same place (`design-parity shard --shard i/N`); neither re-derives
it. Don't pre-slice the component list before passing it — `--shard`
partitions what it is handed, so a pre-sliced list gets sliced twice.

## Other inputs worth knowing

| Input | Why you'd set it |
|---|---|
| `design-map-command` | Shell run before the partition, to regenerate `design-map.json` from the repo (e.g. projecting it out of `@CatalogComponent(reference = …)` annotations). Runs in **every** shard — cheap next to the render, and the partition must derive from the same map the comparison uses. |
| `components` | Comma-separated handles to compare. Empty (default) means **every** component in the map — the exhaustive run this workflow exists to make affordable. Set it only to deliberately narrow. |
| `cache-paths` | Space-separated paths whose content decides whether a run would reproduce the published board (the module, the version catalog, the build files). Unchanged + same tool version ⇒ the run is skipped and the previous verdict re-applied. **Empty by default on purpose**: a wrong list produces a stale skip, which is worse than never skipping — so the caller has to say what feeds its render. |
| `force-refresh` | Ignore the cache and run anyway. The key can't cover everything that moves — a runner image, a font, a renderer's transitive deps — so a scheduled unconditional run is the companion to caching, not an optional extra. |
| `design-parity-ref` | Build and run an **unreleased** design-parity from a git ref instead of the published version. For testing the tool itself. |

## Canonical reference

- [`docs/PARALLEL_PARITY.md`](https://github.com/yschimke/design-parity/blob/main/docs/PARALLEL_PARITY.md)
  — the arithmetic, how to pick a shard count, and the measured numbers.
- [`.github/workflows/design-parity-reusable.yml`](https://github.com/yschimke/design-parity/blob/main/.github/workflows/design-parity-reusable.yml)
  — the full input list, documented inline.
