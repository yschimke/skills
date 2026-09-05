---
name: figma-catalog-import
description: Import a code-derived design-artifact catalog (from compose-design-catalog) into a Figma file as authoritative renders — grouped, with a11y greenlines, spacing redlines, a token→variable collection, and a design-map.json correspondence. Use when taking a published design-artifacts/<system> bundle into Figma. Decides the import case first (code-led vs design-led × new vs existing file), never delete-and-rebuilds, and reconciles in place keyed by componentId. Pairs with compose-design-catalog.
---

# Figma catalog import

Take a published **design-artifact catalog** — the `design-artifacts/<system>`
bundle that [`compose-design-catalog`](../compose-design-catalog/SKILL.md)
produces (`catalog.json` + DTCG tokens + `images/` + `wireframes/`) — and import
it into **Figma** as authoritative, code-derived renders.

This is the **import hop** — the **Figma destination adapter**. It consumes
either arranger's output: a whole-system bundle from **compose-design-catalog**
(a `design-artifacts/<system>` branch or a `compose-preview serve` host) *or* a
curated render set from **compose-preview-design-board**. Both arrangers delegate
the Figma side here rather than duplicating it, because Figma is the one *heavy*
destination (a plugin, in-place reconcile, a `design-map.json` correspondence);
Claude Design is a light HTML/PNG drop-in that stays in those skills.

## Code is the source of truth

The catalog is rendered from real component code, so it is correct by
construction — padding, type, colour, corner radius, touch targets are what the
components actually resolve, not what a spec claims. **Figma is a *view* of the
code, never the authority.** Published Figma kits are seed/reference only. This
stance is what makes the import safe to re-run: the render always wins, so a
re-import is a refresh, not a negotiation.

## Decide the case FIRST — before writing anything to Figma

Two axes decide everything. **State the case out loud before you touch the
file.** Getting this wrong can clobber a designer's work, which is the one
unrecoverable mistake here.

### Axis 1 — who owns the source of truth (`.design-parity.json`)

Read the consumer repo's committed **`.design-parity.json`** (the
`@design-parity/policy` parity direction, `auto → code-led | design-led`):

- **code-led** — code is truth. The importer **owns** the Figma catalog: it
  builds and refreshes it directly.
- **design-led** — Figma is truth. Renders are imported **only as a comparison
  reference** and **must not** replace or restructure designer-owned content
  without explicit confirmation, even on the first import.
- **`auto` unresolved / no file** — treat as **design-led** (safe default:
  never clobber a designer).

### Axis 2 — is the target file new/empty or an existing designer file

`get_metadata(fileKey)` with no `nodeId` lists top-level pages; drill into a page
to see whether it already holds designer frames (frames **without** a
`designParity` stamp) vs. only prior importer output.

### The four cases

|  | **New / empty file** | **Existing designer file** |
| --- | --- | --- |
| **code-led** | **Build** the full catalog and **own** it. Straight import. | **Reconcile** by `componentId`: update matched nodes in place, add new, tag removed `stale`; **never touch un-stamped nodes.** No delete-and-rebuild. |
| **design-led** | Import renders **only** into a `Code renders (reference)` page. Never pre-build designer structure. | Same reference-only page, **plus a first-touch confirmation gate**: surface a diff and get explicit confirmation before writing into the file. Renders are comparison-only; the designer's frames stay authoritative. |

If you cannot determine the direction, **stop and ask** — do not guess toward
writing.

## Identity, not position — the rule that makes re-import safe

Every node the importer creates is stamped with
`setSharedPluginData("designParity", …)`:

| key | value |
| --- | --- |
| `role` | `catalog-root` / `page` / `group` / `card` / `image` / `title` / `caption` / `chips` / `link` |
| `componentId` | the catalog `componentId` (on `card` + `image`) |
| `system` | the design-system id (on the root/pages) |

**Re-import is a reconcile keyed by `componentId`, never by position:**

- **match found** → update the render fill on the *same* image node + refresh
  caption/chip/link text. The card keeps its position, size, and any designer
  edits.
- **new in catalog** → add a card into its group/page.
- **gone from catalog** → tag it `stale`; don't delete.
- **no `designParity` stamp** → a designer's own content; **never touched.**

Bootstrapping older boards: the reconcile also matches by layer name
(`node.name === componentId`), so pre-stamp boards self-heal on the first run.

> **Never delete-and-rebuild.** The v1 runbook cleared the page and rebuilt from
> scratch; that regenerates every node id and destroys anything a designer added.
> Reconcile-in-place is the only re-import path. If you find yourself about to
> delete all top-level frames, stop.

## Two ways to import — prefer the plugin

### A. The `@design-parity/figma-plugin` (preferred, durable)

The [`@design-parity/figma-plugin`](https://github.com/yschimke/design-parity/tree/main/packages/figma-plugin)
is the maintained path. Easiest install: download the prebuilt
`design-parity-figma-plugin.zip` from the
[latest design-parity release](https://github.com/yschimke/design-parity/releases/latest)
(or the `figma-plugin-bundle` workflow artifact), unzip, and in the Figma
**desktop** app *Plugins → Development → Import plugin from manifest…* → the
unzipped `manifest.json`. No `npm`, no publish. (Build from source —
`npm run build:plugin --workspace @design-parity/figma-plugin` — only when
iterating on the plugin itself.)

**The dialog is four designer tasks**, not feature tabs: **Add components**,
**Manage library**, **Customize live**, **Handoff to code**. The catalog source
sits above all of them, so switching tasks never drops the loaded system;
server, render axes, and import policy hide behind contextual disclosures.

**Pick a catalog.** The plugin ships a small registry (Compose M3, RemoteCompose
M3, Wear M3, each pointing at its `design-artifacts/<system>` branch);
**Catalog options → Register source** adds your own by the raw root of a bundle
(the folder holding `catalog.json` — don't append `/catalog.json`); the host must
be in the manifest's `allowedDomains`. **Catalog options → Load local folder…**
reads a local `design-artifacts` directory with **no server or network** — a
freshly generated catalog drops in with zero setup. Only **Customize live** needs
a `compose-preview serve` host; browsing and inserting published renders never
does.

Then bring the system onto the canvas:

- **Add components** (one component) — a grouped, searchable picker; pick variant
  + the data-driven dimensions the catalog actually carries (theme / size /
  props, plus the i18n axes `locale` / `direction` / `fontScale` when it renders
  them). **Add selected component** places it as a **PNG** (the shipping raster)
  or an **SVG** (the editable `compose/figma-svg` design vector — scales crisply,
  falls back to the wireframe when no vector is baked). **Add all variants**
  places the whole component as a **native component set**, one editable
  per-variant SVG `COMPONENT` per render, named with native variant properties.
- **Manage library → Import or refresh the library** (whole catalog) — the
  sticker-sheet flow. Pick **ideal render + a11y greenlines** or **layout
  wireframe + spacing redlines** and a Mode, then Import. It lays out a
  `<system>` board (or the structured pages below on a code-led catalog), plus a
  **Figma variable collection** from the DTCG tokens (light/dark → modes) and a
  **`design-map.json`** correspondence scaffold (each `componentId` → the node it
  placed) to commit into the consumer repo.

**The SVG import is Figma-native where that's lossless** — pills/circles become
rectangles with editable corner radii, fills/strokes/radii/padding/gaps bind to a
local variable collection from the catalog palette, symbolic type roles become
local Text Styles, background-backed groups become frames, clear rows/columns
become Auto Layout, and the root becomes a main component where Figma permits.
Freeform/overlapping artwork and elliptical or non-uniform corners stay paths —
promoting them would change the visual.

**Upgrading a legacy import is a first-class flow, not a re-import.** With the
matching catalog loaded, point **Manage library → Upgrade existing mapped
layers** at the committed `design-map.json` and press **Upgrade mapped layers**:
the map (not layer-name guessing) selects the old PNG/basic-SVG roots and
replaces each with the same editable component set a fresh insert would build,
keeping canvas position, rotation, parent order, and name. Stale, cross-file,
ambiguous, already-current, and unsupported mappings are reported and left alone,
and a component with existing instances is skipped so instance overrides can't
break. Replacements change node ids, so copy the returned correspondence document
back over `design-map.json`.

The plan is deterministic (`buildImportPlan` is pure and unit-tested); the Figma
glue only executes it. The plugin also runs the reverse **design → code**
direction — **Handoff to code → Create handoff from selection** reads a selected
frame into a GitHub-issue body + `spec.json` (with design-parity's a11y/i18n
acceptance contract) without writing code.

### B. The Figma-MCP runbook (fallback, agent session)

When the plugin can't be loaded, drive it by hand with the Figma MCP
(`upload_assets` + `use_figma`). The step-by-step — prep with
`scripts/figma-import-prep.mjs`, upload renders, lay out the board — is the
[`FIGMA_IMPORT.md`](https://github.com/yschimke/design-parity/blob/main/docs/design-artifacts/FIGMA_IMPORT.md)
runbook in design-parity. Load the `figma-use` skill before any `use_figma`
call. Environment prerequisites bite in order: Figma connector present
(`mcp__Figma__whoami` succeeds), `mcp.figma.com` egress allowed (uploads POST
there — an environment's egress policy may block that host, so probe it, don't
assume by cloud-vs-local), and there is **no** URL→image path inside `use_figma`
(every image goes through `upload_assets`). Even in the runbook, **reconcile — do
not rebuild.**

### The SVG-seed path — the placed SVG MUST be self-contained

Both paths can place the baked **`figma/<slug>.svg`** design vector
(`compose/figma-svg`) as *editable shapes* via `figma.createNodeFromSvg` — the
plugin's *Insert as SVG* / `placeCatalogSvg`, or a bare `use_figma` call. This
avoids `upload_assets`/`mcp.figma.com` entirely, so it's the seed path of choice
when raster upload is blocked. But `createNodeFromSvg` has **no filesystem and no
`fetch`**, so it can't resolve a relative raster href: a hybrid sticker's
`<image href="<slug>.figma-raster/<node>.png">` is **silently dropped** — no
error, just an empty gap in an otherwise-complete node (verified on
`device-nocontacts.svg`). The SVG must be self-contained (every raster inlined as
a `data:` URI) *before* it is placed.

- **Plugin path — handled.** The UI thread (the only realm with `fetch`) pulls
  the crops and rewrites the hrefs via
  [`svgRaster.ts`](https://github.com/yschimke/design-parity/blob/main/packages/figma-plugin/src/svgRaster.ts)
  (`svgRasterHrefs` → `inlineSvgRasters`), so `placeCatalogSvg` gets a
  self-contained SVG.
- **Runbook path — you must pre-inline.** `use_figma` has no `fetch`, so obtain a
  self-contained SVG *before* embedding it in the `code` string. Easiest:
  **`compose-preview serve` already returns inlined SVGs** — the server
  ([yschimke/compose-preview-server](https://github.com/yschimke/compose-preview-server))
  replaces every `figma-raster/<node>.png` href on its `.svg` render route with a
  `data:` URI
  ([`inlineFigmaRasters`](https://github.com/yschimke/compose-ai-tools/blob/main/render-host/src/main/kotlin/ee/schimke/composeai/cli/serve/ServeFigmaSvg.kt),
  wired on both the daemon `ServeRenderHost` and the static `ServeBundleHost` /
  `ServeCatalogStore` paths, with a `..`/absolute traversal guard) — so fetch the
  served `.svg` (outside `use_figma`) and embed that. Only when you can't run
  serve — reading files straight off the static `design-artifacts/*` branch — do
  the same inlining locally over the SVG + its sibling `.figma-raster/` dir.
  **Never commit inlined SVGs** — external hrefs keep the `design-artifacts/*`
  diffs clean and rasters dedup'd; inlining is a *transport* step, not a storage
  one.

**Mind the 50k `use_figma` `code` cap** — it counts the embedded SVG text.
Mostly-vector screens fit comfortably; inlined rasters add ~⅓ base64 on top, so a
raster-heavy sticker can exceed the cap and must be placed in pieces — the vector
SVG in one cap-safe `createNodeFromSvg`, then each raster as its own image node
positioned from its `<image>` coords (byte-splitting the markup doesn't work, and
stateless `use_figma` calls can't reassemble a fragmented string). The plugin
sidesteps the cap (its UI fetches bytes rather than embedding them). Note the
**inlining** is already handled server-side (`compose-preview serve`, above), but
the **chunking is not** — serve returns the whole inlined SVG in one response — so
cap-splitting a raster-heavy sticker stays an agent-runbook concern.

## Structured pages (shipped) — a code-led import isn't one flat sheet

When a code-led catalog carries theme foundations and/or a screen graph
(`catalog.json`'s `screens: [{ id, title?, related }]`), the whole-catalog
import lays out **multiple pages instead of one sticker sheet**, each its own
reconcile **scope** (so a re-import refreshes each independently):

- **`Themes / Tokens`** — the theme-foundation showcases plus the native Figma
  **variable collection** (light/dark modes from the DTCG tokens).
- **One page per main screen** — leads with a `Figma spec` frame (`role=spec`,
  seeded once from code, then designer-owned — the reconcile never touches it),
  with the screen's card and its related secondaries/dialogs below. Each is the
  **three-lane diff**: **Figma spec · wireframe · code render** — the wireframe
  is the baked `wireframes/<slug>.svg` placed as a **true vector** node
  (spacing redlines), the code render is the `capture` PNG (a11y greenlines).
- **`Components`** — everything else as the library: each component a native
  Figma **component set** (`state=…, theme=…, size=…` variant properties).

A catalog with neither themes nor `screens` — and any design-led import — stays
a single flat page. The remaining gap (design-parity's `FIGMA_IMPORT_V2.md`,
v3): the renderer fanning out the full `state × breakpoint` matrix so the sets
carry every cell, not just default + light/dark.

### Per-screen page layout — a Section per state, variant rows for the blessed state

Within a screen's page, don't drop every render in one horizontal row — it
sprawls off-canvas and reads as noise (a whole catalog in one strip is as wide as
the sum of every sticker). Lay it out **spatially with Figma Sections** (titled,
bordered `createSection` containers) stacked vertically:

- **One Section per major state** — e.g. Device → *Loading*, *No contacts*,
  *Many contacts*, *Low battery*, *Connecting*, *Failed*, *Cached*. Each state
  its own bordered, titled section, so the page reads top-to-bottom as the
  screen's state machine.
- **The blessed (canonical/populated) state's section carries three labelled
  variant rows**; every other state shows just its small-phone default:
  - **Size**: small phone · large phone · small tablet landscape.
  - **Locale** (small phone): en · ar · ja · de — proves RTL (`ar`) and CJK
    (`ja`) reflow and German (`de`) expansion on the real screen, not just a
    component.
  - **Theme** (small phone): each blessed theme (MeshCore light/dark, Material 3
    light/dark).

Sections supply the borders/titles designers expect, and the single-mega-row
width problem dissolves once sections stack vertically and each variant row wraps.

**This needs the catalog to fan the matrix out — it does not today.** The current
`meshcore-mobile` catalog bakes **state only**: one render per `Group/State`
componentId (`Device/Loading`, `Device/ManyContacts`, …) at a single size, locale
`en`, and default theme, with `screens: null` and no `size`/`locale`/`theme`
dimension fields. To populate the layout above, the consumer's `catalog.spec.json`
+ renderer must emit, per screen: the blessed state across `size` ∈ {small-phone,
large-phone, small-tablet-landscape}, across `locale` ∈ {en, ar, ja, de} at
small-phone, and across the blessed `theme`s at small-phone — plus each other
state at small-phone — and expose `state`/`size`/`locale`/`theme` as **catalog
dimensions** (with a `screens` graph) so the importer can group by state into
sections and lay the blessed state's rows by dimension. This is the concrete
shape of the `state × breakpoint` matrix gap above (`FIGMA_IMPORT_V2.md` v3),
extended with locale and theme axes. The render/catalog work lands in the
consumer repo; the importer only reads the dimensions and builds the Sections.

The **size** axis of that matrix is the part the catalog spec can already
express: a `breakpoints` table plus per-entry `select`, or
`@CatalogComponent(perBreakpoint = true)` on the annotation, gives a card per
breakpoint off one multipreview — see
[`compose-design-catalog`](../compose-design-catalog/SKILL.md#breakpoints-one-card-or-a-card-per-size).
Locale and theme still need the consumer's render matrix.

## File registry

| System | Delivery branch | Figma file |
| --- | --- | --- |
| meshcore-mobile | `design-artifacts/meshcore-mobile` | `gYzowY4cQ7rNr2gYoco1M6` |
| homeassistant-remotecompose | `design-artifacts/homeassistant-remotecompose` | `y9mCRmIAatmv8PMwKuSxm0` |
| cadence | `design-artifacts/cadence` | _(pending first import)_ |

Before a re-import, compare the delivery branch HEAD sha against the last
imported sha (recorded in the catalog root's provenance sub-line); skip the
system if unchanged.

## Checklist

- [ ] Read `.design-parity.json` → resolved direction (default design-led).
- [ ] `get_metadata` the target → new/empty vs existing designer content.
- [ ] Stated the case (one of the four cells) before writing.
- [ ] Delivery branch sha differs from last import (else skip).
- [ ] Imported via the plugin (or the MCP runbook as fallback), **reconciling
      by `componentId`** — no delete-and-rebuild, un-stamped nodes untouched.
- [ ] SVG-seed path: placed a **self-contained** SVG (rasters inlined as `data:`
      URIs); pre-inlined in the runbook since `use_figma` has no `fetch`; watched
      the 50k `code` cap (chunk raster-heavy stickers). Never committed the
      inlined SVG.
- [ ] design-led first-touch: surfaced a diff and got confirmation.
- [ ] Emitted / refreshed `design-map.json`; offered it for the consumer repo.

## Source & cross-repo

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/figma-catalog-import/`. The importer (plugin + runbook + the v1/v2
specs) lives in
[github.com/yschimke/design-parity](https://github.com/yschimke/design-parity)
under `packages/figma-plugin` and `docs/design-artifacts/`; the renderer and
`compose-preview` CLI that produce the bundle ship from
[github.com/yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).
Keep the design-parity links stable.
