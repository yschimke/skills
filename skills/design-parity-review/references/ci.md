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
| `design-map-command` | Shell run before the partition, to regenerate `design-map.json` from the repo (e.g. projecting it out of `@CatalogComponent(reference = …)` annotations). Runs in **every** shard — cheap next to the render, and the partition must derive from the same map the comparison uses. Don't hand-write that projection — see [Deriving the map from annotations](#deriving-the-map-from-annotations). |
| `components` | Comma-separated handles to compare. Empty (default) means **every** component in the map — the exhaustive run this workflow exists to make affordable. Set it only to deliberately narrow. |
| `cache-paths` | Space-separated paths whose content decides whether a run would reproduce the published board (the module, the version catalog, the build files). Unchanged + same tool version ⇒ the run is skipped and the previous verdict re-applied. **Empty by default on purpose**: a wrong list produces a stale skip, which is worse than never skipping — so the caller has to say what feeds its render. |
| `force-refresh` | Ignore the cache and run anyway. The key can't cover everything that moves — a runner image, a font, a renderer's transitive deps — so a scheduled unconditional run is the companion to caching, not an optional extra. |
| `design-parity-ref` | Build and run an **unreleased** design-parity from a git ref instead of the published version. For testing the tool itself. |

## Deriving the map from annotations

For a Compose catalog whose components already carry
`@CatalogComponent(reference = "figma:<fileKey>/<nodeId>")`, the map is a
**projection of the annotations**, not a file anyone maintains. Two commands
produce it, and the split between them is the point:

```sh
# 1. annotations → base refs + unresolved variant declarations
./gradlew :<module>:composePreviewDiscover
node compose-ai-tools/scripts/design-artifacts/emit-design-map.mjs \
  --previews <module>/build/compose-previews/previews.json

# 2. variant declarations → kit node ids
npx @design-parity/kit-index resolve
```

**Why two.** Step 1 knows what the annotations mean — it lives in
`compose-ai-tools` beside `@CatalogComponent` / `@CatalogVariant` /
`@OverrideVariant`, so renaming a field changes both in one commit. It stops at
the variant renders, because `size=l` is a fact about a Compose API and
`Size=Large` is a fact about somebody's design kit; translating between them
needs that kit's published vocabulary. Step 1 therefore emits those renders as
**declarations** in a `design-map-variants.json` sidecar, and step 2 —
[`@design-parity/kit-index`](https://github.com/yschimke/design-parity/tree/main/packages/kit-index)
— resolves them against a committed kit index into tagged `ref`/`previewId`
pairs.

**Each step is useful alone.** Stop after step 1 and you have a valid map of
base references, which is most of the value at no design-tool credential. Step 2
needs a committed `figma-kit-index.json` (built once with
`design-parity-kit-index dump` + `build`, which do need a `FIGMA_TOKEN`); the
`resolve` itself reads only committed files, so it is safe in every shard.

**Practicalities.** Both steps are published packages now, so a
`design-map-command` needs no checkout of either repo:
[`@yschimke/compose-design-map`](https://www.npmjs.com/package/@yschimke/compose-design-map)
is step 1 (the `emit-design-map.mjs` projection, released in lockstep with the
compose-ai-tools version it projects) and `@design-parity/kit-index` is step 2.

**Pin both to an exact version.** The outputs are committed and CI fails on any
difference, so a floating `npx` makes an upstream release turn a repo red for a
change nobody there made — a floating step 2 once resolved 0.1.49 against a map
built by 0.1.50's slug matching and reported 439 variant references where the
committed map had 442. Pinning makes a bump a commit that regenerates the map in
the same diff.

**Stage both steps and copy the finished pair into place.** Step 1's map is an
intermediate — base refs with the variants still unresolved — so a run that wrote
it directly and then failed in step 2 leaves a map that looks complete while
silently comparing hundreds of nodes fewer.

### A dark-only catalog projects zero components

Step 1 pairs each component's reference with the capture whose id ends `_Light`,
because kits draw their frames in light mode and diffing a dark render against a
light reference reports the whole palette as a finding. Sound for a light/dark
catalog; fatal for a **dark-first** one.

A Wear catalog is dark-first by convention — a black watch face, so the component
multipreview bakes a single dark capture and no preview id ends in `_Light`. Every
component can carry a reference and the projector still writes:

```
Wrote design-map.json: 0 mapped component(s), 0 naming their component set.
```

And an empty map does **not** skip the way a missing `FIGMA_TOKEN` does — the
parity run exits 1 with `no components: pass --components, or commit a
design-map.json with entries`. So a dark-first catalog wired the usual way carries
a red X on every push for a reason nothing in the log attributes to the mode.

Until the projector can name a dark capture
([compose-ai-tools#4192](https://github.com/yschimke/compose-ai-tools/issues/4192)),
run parity on `workflow_dispatch` only, commit no map, and say why in the repo —
a known red X is how a signal stops being read. Keep the references on the
annotations regardless: they are what makes the map a projection the day the
projector can see them, and a test asserting every component carries one costs
nothing and holds the inventory rule in the meantime.

Both commands take `--check`, which regenerates in memory and fails if the
committed file has drifted. That is the right shape for a freshness gate on a
repo that commits its map: the map is an output, and a stale one silently
compares the wrong nodes.

## Canonical reference

- [`docs/PARALLEL_PARITY.md`](https://github.com/yschimke/design-parity/blob/main/docs/PARALLEL_PARITY.md)
  — the arithmetic, how to pick a shard count, and the measured numbers.
- [`.github/workflows/design-parity-reusable.yml`](https://github.com/yschimke/design-parity/blob/main/.github/workflows/design-parity-reusable.yml)
  — the full input list, documented inline.
