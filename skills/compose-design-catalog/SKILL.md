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

2. **Build and write the catalog.** Feed the products through
   `@design-parity/candidate`'s mappers (`nativeFindings`,
   `semanticsToSemanticTree`, `composeThemeToTokens`) into
   `@design-parity/catalog-export`:

   ```ts
   import { buildCatalog, writeCatalog } from "@design-parity/catalog-export";

   const catalog = buildCatalog(
     { system: "compose-m3", title: "Compose Material 3",
       library: ["androidx.compose.material3:material3"],
       renderer: "compose-preview 0.16.2" },
     sources, // one ComponentSource per component (ideal+layout images, tokens,
              // semantics, findings) from the mappers above
   );

   await writeCatalog(catalog, ".design-artifacts/compose-m3", {
     sourceRoot: "build/compose-previews",
   });
   ```

3. **Import.** The bundle is tool-neutral first, Figma second:

   ```
   catalog.json            # index: components, both variants, greenlines
   tokens.dtcg.json        # W3C DTCG token set — Figma Variables / Tokens Studio / Style Dictionary / Claude Design
   figma-variables.json    # Figma variable-collection projection (light/dark as modes)
   images/<component>/<variant>__<state>[__theme][__size].png
   ```

   - **Claude Design / Stitch** — import the PNGs + `catalog.json`; the DTCG file
     seeds tokens. Pair with **compose-preview-design-board** to wrap the same
     renders as a browsable HTML brief.
   - **Figma** — import `tokens.dtcg.json` via a DTCG/Tokens-Studio plugin, or
     create variables from `figma-variables.json`; place the variant PNGs as the
     sticker-sheet frames.

4. **Deliver on a per-system branch.** Commit the bundle to a
   `design-artifacts/<system>` branch (`design-artifacts/compose-m3`,
   `.../wear-m3`, `.../glimmer`, `.../glance-wear`) — the surface a designer
   pulls from. Regenerate on component changes so the sheet never drifts.

## Source

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/compose-design-catalog/`. The export library
(`@design-parity/catalog-export`) lives in
[yschimke/design-parity](https://github.com/yschimke/design-parity); the
renderer/CLI in
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).
