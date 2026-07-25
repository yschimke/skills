---
name: compose-design-catalog
description: Generate an importable design-artifact sticker sheet for a whole Compose component system (Compose M3, Wear Compose M3, Glimmer, Glance/Wear widgets). Use when you want a code-derived component catalog — each component in its primary modes, in two variants (ideal render + bordered layout), with extracted design tokens and accessibility greenlines — laid out for import into Figma, Google Stitch, or Claude Design. Pairs with the compose-preview and compose-preview-design-board skills.
---

# Compose Design Catalog

Render a Compose **component system** and export it as an importable **sticker
sheet**: every component in its primary modes, in two variants (the `ideal`
render and a `layout` render that borders every composable), with the system's
design tokens and an accessibility **greenline** layer extracted automatically
from the render — not transcribed from a spec.

This skill is the system-wide, sticker-sheet sibling of
**compose-preview-design-board** (which arranges an arbitrary set of renders
into one HTML brief). It assumes the **compose-preview** skill is installed —
that skill owns the renderer, CLI, and Gradle plugin. Check first with
`compose-preview --version`; if missing, run the bootstrap installer:

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/compose-ai-tools/main/scripts/install.sh \
  | bash
```

## Code is the source of truth

This pipeline is **code-led**. Every value on the sheet — padding, corner
radius, type, colour, touch-target size, `maxLines` / overflow — comes from the
renderer's own data products, so the catalog is correct by construction.
Published design kits (the Material 3 / Wear OS / Glimmer / Widget Figma kits)
are **seed/reference only**: use them for the component inventory and for naming
parity, never as authority. A kit/render divergence is a bug in the kit.

## When to use this skill

- You want a designer-ready catalog of a component library (yours, or a system
  like Material 3) generated from the code, refreshable on every change.
- You want the two-variant treatment — an `ideal` render *and* a bordered
  `layout` render — plus tokens and a11y annotations, in one bundle.
- You want artifacts that import into Figma / Stitch / Claude Design, on a
  branch a designer can pull from.

For *one-off* sets of renders → **compose-preview-design-board**. For *rendering*
or *reviewing* → **compose-preview** / **compose-preview-review**.

## Prerequisite: a catalog module

`@Preview` discovery is local-module only, so the components must be authored as
`@Preview` functions in a Gradle module that depends on the target library
(`androidx.compose.material3`, `androidx.wear.compose.material3`,
`androidx.xr.glimmer:glimmer`, `androidx.glance`, …). Author **one `@Preview`
per component × primary mode**, padded, with the breakpoints the system's kit
documents (e.g. `compact` / `medium` / `expanded` for M3; small/large round for
Wear). See the `samples/design-catalog-*` modules in
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).

### Cataloguing an existing app (the cheap path)

A dedicated catalog module is right when you are documenting a *component
library*. When you are cataloguing an **app that already has `@Preview`
functions**, don't author a parallel set — point the spec at the previews that
are already there. Adoption is then a plugin line plus `catalog.spec.json`,
with **no change to UI code**, and the sheet stays honest because it renders the
same previews the team already maintains.

The [compose-samples catalogs](https://github.com/yschimke/compose-samples/tree/agent/preview-catalogs)
are built this way: JetNews covers 22 of its 23 existing previews without
touching a single composable.

Two rules make this work well:

- **Group by feature, not by widget.** The value of a sample/app catalog is
  showing what the app is *for* — adaptive postures, the states of a screen, an
  RTL mirror — so `groups`/`section` should follow that, not alphabetical
  component names.
- **Put catalog-only fixtures in `src/debug`.** Anything you *do* need to add
  (motion fixtures, a composed feature shot) belongs in the debug source set:
  the plugin renders the `debug` variant, so they are discovered like any other
  preview, but they never reach a release build.

## Declare & validate the spec (`catalog.spec.json`)

The catalog's inventory, grouping, captions, sections and per-component variants
are declared in a hand-authored **`catalog.spec.json`** committed next to the
module. Each component's `preview` **must equal an exact `@Preview` function
name** — a mistyped or renamed name renders nothing and surfaces only as a late
"missing" entry at the *end* of the (long) render. Its shape is documented by
[`scripts/design-artifacts/catalog.spec.schema.json`](https://github.com/yschimke/compose-ai-tools/blob/main/scripts/design-artifacts/catalog.spec.schema.json)
(reference it via `$schema` for editor validation).

Two build-free helpers in compose-ai-tools' `scripts/design-artifacts/` scan the
module's Kotlin source directly — no Gradle build, no render — so you author and
check the spec before spending a render:

```sh
# Scaffold a starter spec from the module's @Preview functions (one flat
# "Components" group; caption and regroup from there):
node scripts/design-artifacts/init-catalog-spec.mjs \
  --module :app --system my-system --title "My System" --out catalog.spec.json

# Resolve every `preview` (component + variant) against the discovered functions,
# with typo suggestions, structural checks, and coverage gaps. Exits non-zero on
# errors, so it runs as the pre-flight in design-artifacts.yml before the render:
node scripts/design-artifacts/validate-catalog-spec.mjs --spec catalog.spec.json
```

### Breakpoints: one card, or a card per size

A multipreview (`@WearPreviewDevices`, a local `@CatalogWearBreakpoints`) renders
one function at several device sizes, and the join keys on **function name** — so
by default they all fold into one entry carrying one image per size, tagged from
the spec's `breakpoints` table:

```jsonc
"breakpoints": [
  { "size": "smallRound", "device": "id:wearos_small_round", "widthDp": 192 },
  { "size": "largeRound", "device": "id:wearos_large_round", "widthDp": 227 }
]
```

Declare each by `device` (matched first) *and* `widthDp` (the fallback): a width
is a fingerprint two devices can share, and an undeclared device falls back to
the generic Material width class, making two renders indistinguishable on that
axis — the export warns when it sees one. A Wear catalog that declares no
`breakpoints` inherits the standard round table.

When you want a **card per breakpoint** — its own id and caption — use `select`
rather than splitting the `@Preview` in the module (splitting costs the
multipreview's other axes, e.g. `@WearPreviewFontScales`):

```jsonc
{ "componentId": "Home/SmallRound", "preview": "HomeListViewPreview",
  "select": { "size": "smallRound" }, "caption": "Home — small round." },
{ "componentId": "Home/LargeRound", "preview": "HomeListViewPreview",
  "select": { "size": "largeRound" }, "caption": "Home — large round." }
```

Two entries may share one `preview` as long as each selects a different value. An
**annotation-led** inventory says the same thing in code with
`@CatalogComponent(id = "Layout/List", perBreakpoint = true)`, which yields
`Layout/List/smallRound`, `Layout/List/largeRound`, … — one per breakpoint the
function actually rendered at, in `breakpoints` order. It's a flag, not a list:
the multipreview below it already decides the devices, so the names come from the
renders. One breakpoint keeps the plain id; none resolved keeps the component
whole and warns. Adopting `perBreakpoint` on a published catalog **moves those
sticker URLs**, which is why it's opt-in — the preview server already
disambiguates merely *colliding* card labels on its own. A spec entry always
overrides the annotation. Full rules:
[`docs/design/DESIGN_CATALOGS.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/design/DESIGN_CATALOGS.md).

Discovery recognises `@Preview` and any `annotation class` meta-annotated with it
(`@CatalogModes`, `@CatalogTemplate`, …); pass `--preview-annotation <Name>` for a
multipreview annotation imported from another module. The authoritative check
stays the render + completeness gate — this is the fast local/CI pre-flight.

> **Wear catalogs always need this flag.** Wear previews are conventionally
> annotated `@WearPreviewDevices` / `@WearPreviewFontScales` / `@WearPreviewLargeRound`,
> which live in `androidx.wear.compose.ui.tooling.preview` — an external
> artifact the source scan cannot see. Without the flags the validator reports
> **`discovered 0 @Preview function(s)`** and fails every entry, which reads
> like a broken spec rather than a missing flag:
>
> ```sh
> node validate-catalog-spec.mjs --spec catalog.wear.spec.json \
>   --preview-annotation WearPreviewDevices \
>   --preview-annotation WearPreviewFontScales
> ```
>
> Record the required flags in the spec's `$comment` so the next run doesn't
> rediscover this. The same applies to any app-defined multipreview annotation
> declared in a different module from the previews that use it.

## Workflow

1. **Render the system with its data products.** Ask the renderer for the
   captures plus the wireframe, theme, semantics, and a11y products:

   ```sh
   compose-preview show --module samples:design-catalog-m3 \
     --with-extension a11y,theme,semantics,semantics-wireframe --json \
     > /tmp/m3-show.json
   ```

   - `capture` PNGs → the `ideal` variant.
   - `compose/semantics-wireframe` (PNG/SVG) → the `layout` variant (bordered).
   - `compose/theme` → the token set (`colorScheme` + `typography` + `shapes`).
   - `compose/semantics` v6 → per-node bounds, padding, `textOverflow`
     (`maxLines` / `lineCount` / `truncated`).
   - `a11y/atf` + `a11y/touchTargets` → the greenline findings.

2. **Build and write the catalog.** The maintained path is the
   `generate-design-catalog.mjs` driver: it renders to a portable bundle with
   `compose-preview bundle pack --with-semantics`, joins it to `catalog.spec.json`
   (matching each component's `preview` to the rendered function name), and writes
   the importable bundle. This is exactly what `design-artifacts.yml` runs:

   ```sh
   compose-preview bundle pack --module samples:design-catalog-m3 --with-semantics \
     -o build/m3-bundle.png
   node scripts/design-artifacts/generate-design-catalog.mjs \
     --spec catalog.spec.json --renders build/m3-bundle.png --out out/ \
     --renderer "$(compose-preview --version | head -1)"
   ```

   Under the hood the driver feeds the render's data products through
   `@design-parity/candidate`'s mappers (`nativeFindings`,
   `semanticsToSemanticTree`, `composeThemeToTokens`) into
   `@design-parity/catalog-export`. To build a catalog **without** a spec file
   (e.g. a custom pipeline), call that library directly:

   ```ts
   import { buildCatalog, writeCatalog } from "@design-parity/catalog-export";

   const catalog = buildCatalog(
     { system: "compose-m3", title: "Compose Material 3",
       library: ["androidx.compose.material3:material3"],
       renderer: "compose-preview 0.17.2" },
     sources, // one ComponentSource per component (ideal+layout images, tokens,
              // semantics, findings) from the mappers above
   );

   await writeCatalog(catalog, ".design-artifacts/compose-m3", {
     sourceRoot: "build/compose-previews",
   });
   ```

3. **Import.** The bundle is tool-neutral first, Figma second:

   ```
   catalog.json            # index: components, both variants, greenlines, optional screen graph
   tokens.dtcg.json        # W3C DTCG token set — Figma Variables / Tokens Studio / Style Dictionary / Claude Design
   figma-variables.json    # Figma variable-collection projection (light/dark as modes)
   images/<component>/<variant>__<state>[__theme][__size].png
   wireframes/<component>.svg  # baked structural vector — placed as a true vector node on Figma import
   ```

   - **Claude Design / Stitch** — import the PNGs + `catalog.json`; the DTCG file
     seeds tokens. Pair with **compose-preview-design-board** to wrap the same
     renders as a browsable HTML brief.
   - **Figma** — import `tokens.dtcg.json` via a DTCG/Tokens-Studio plugin, or
     create variables from `figma-variables.json`; place the variant PNGs as the
     sticker-sheet frames. The maintained path for this is the
     **figma-catalog-import** skill (the import-hop sibling of this one): it
     drives the `@design-parity/figma-plugin`, decides the import case
     (code-led vs design-led × new vs existing file), and reconciles in place
     instead of delete-and-rebuild. Declaring a screen graph in the catalog
     spec (`screens: [{ id, title?, related }]`) turns a code-led import into
     structured per-screen diff pages rather than one flat sheet.

4. **Deliver on a per-system branch.** Force-push the generated `out/` to a clean
   `design-artifacts/<system>` branch (`design-artifacts/compose-m3`,
   `.../wear-m3`, `.../glimmer`, `.../glance-wear`) — the surface a designer pulls
   from, and what the public preview server (`preview.coo.ee`) fetches and serves
   at `/<system>/`. Regenerate on component changes so the sheet never drifts;
   `design-artifacts.yml` in compose-ai-tools (and in a consumer app repo) does
   this on a schedule.

## Source

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/compose-design-catalog/`. The export library
(`@design-parity/catalog-export`) lives in
[yschimke/design-parity](https://github.com/yschimke/design-parity); the
renderer/CLI in
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).
