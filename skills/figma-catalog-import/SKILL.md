---
name: figma-catalog-import
description: Import a code-derived design-artifact catalog (from compose-design-catalog) into a Figma file as authoritative renders — grouped, with a11y greenlines, spacing redlines, a token→variable collection, and a design-map.json correspondence. Use when taking a published design-artifacts/<system> bundle into Figma. Decides the import case first (code-led vs design-led × new vs existing file), never delete-and-rebuilds, and reconciles in place keyed by componentId. Pairs with compose-design-catalog.
---

# Figma catalog import

Take a published **design-artifact catalog** — the `design-artifacts/<system>`
bundle that [`compose-design-catalog`](../compose-design-catalog/SKILL.md)
produces (`catalog.json` + DTCG tokens + `images/` + `wireframes/`) — and import
it into **Figma** as authoritative, code-derived renders.

This is the **import hop**. `compose-design-catalog` is the *produce* hop; this
skill is what happens on the Figma side. It assumes a bundle already exists on a
`design-artifacts/<system>` branch (or a `compose-preview serve` host).

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
is the maintained path. Build it (`npm run build:plugin --workspace
@design-parity/figma-plugin`), *Plugins → Development → Import plugin from
manifest…*, then paste the raw root of a `design-artifacts/<system>` branch,
e.g.

```
https://raw.githubusercontent.com/yschimke/design-parity/design-artifacts/compose-m3
```

Pick a variant and Import. It fetches the manifest, DTCG tokens, and every PNG,
then lays out a `<system> — Catalog` page with:

- the **ideal render + a11y greenlines** OR the **layout wireframe + spacing
  redlines** (UI toggle — each variant gets its natural overlay);
- a **Figma variable collection** projected from the DTCG tokens (light/dark →
  Figma modes);
- a **`design-map.json`** correspondence scaffold (each `componentId` → the node
  it placed) to copy and commit into the consumer repo, where design-parity's
  resolver consumes it.

The plan is deterministic (`buildImportPlan` is pure and unit-tested); the
Figma glue only executes it.

### B. The Figma-MCP runbook (fallback, agent session)

When the plugin can't be loaded, drive it by hand with the Figma MCP
(`upload_assets` + `use_figma`). The step-by-step — prep with
`scripts/figma-import-prep.mjs`, upload renders, lay out the board — is the
[`FIGMA_IMPORT.md`](https://github.com/yschimke/design-parity/blob/main/docs/design-artifacts/FIGMA_IMPORT.md)
runbook in design-parity. Load the `figma-use` skill before any `use_figma`
call. Environment prerequisites bite in order: Figma connector present
(`mcp__Figma__whoami` succeeds), `mcp.figma.com` egress allowed (uploads POST
there), and there is **no** URL→image path inside `use_figma` (every image goes
through `upload_assets`). Even in the runbook, **reconcile — do not rebuild.**

## The per-screen diff section (the direction — v2)

The flat sticker sheet is v1. The target is **one page per main screen**, each
page a top-to-bottom **diff section**:

1. **Figma spec on top** — the design intent. Seeded from code on first import,
   then designer-owned in design-led mode. Shown across **breakpoint variants**
   (e.g. Wear: small round `< 227dp` ≈192dp vs large round `≥ 227dp` ≈227dp;
   Compose M3: compact / medium / expanded).
2. **Comparisons below** — one row per `state × breakpoint`, three lanes:

   | Lane | Source | Role |
   | --- | --- | --- |
   | **a) Figma** | designer-owned frame (seeded from code) | design intent / source of truth in design-led |
   | **b) SVG from code** | `compose/semantics-wireframe` (vector) | **structural** truth — geometry, pairs with the redline overlay |
   | **c) exact PNG from code** | `compose-preview` `capture` PNG | **pixel** truth — what the code renders, pairs with the greenline overlay |

3. The screen's **related secondary screens and dialogs** follow on the same
   page, ordered by the app's primary navigation.

Both overlays already exist in the plugin; this section arranges them per-screen
and per-breakpoint. Two things this still needs (tracked in design-parity's
`FIGMA_IMPORT_V2.md`): a **screen-graph** field in `catalog.spec.json` (which
entries are main screens + their related secondaries) and the **SVG lane** as a
first-class per-screen import beside the PNG.

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
