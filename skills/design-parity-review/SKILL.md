---
name: design-parity-review
description: Prove a Compose UI pull request matches its intended design by diffing the rendered code (candidate) against a Figma / Stitch / Claude Design reference and posting a parity verdict. Use when asked to check a PR against a design, wire up a design-parity bot, set up the committed reference cache so runs make zero Figma calls, shard an exhaustive catalog check across parallel jobs, map code components to design nodes via design-map.json or Code Connect, or push code renders back onto the Figma canvas. This is the design→code direction; for code→design catalogs see compose-design-catalog and figma-catalog-import.
---

# Design parity — reviewing code against its design

`design-parity` is a tool-neutral bot that proves a UI pull request is at
**parity** with its intended design. On a UI PR it:

1. resolves **which design reference** matches the changed component,
2. renders the new code — the **candidate** — via `compose-preview`,
3. **diffs** candidate vs reference (visual + semantic + token),
4. posts a **verdict** in the PR — e.g. *"implements Figma `Button/Primary`;
   padding 12dp vs spec 16dp; dark-theme contrast fails AA."*

The candidate side is the upstream `compose-preview` renderer (the
[compose-preview](../compose-preview/SKILL.md) skill). What design-parity
owns is the **reference side** and the **correspondence layer** that decides
which design maps to which code.

## Source

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/design-parity-review/`. The tool ships from
[yschimke/design-parity](https://github.com/yschimke/design-parity) and on npm
as [`design-parity`](https://www.npmjs.com/package/design-parity) — run it with
`npx design-parity …`, no checkout needed. That repo's
[`docs/README.md`](https://github.com/yschimke/design-parity/blob/main/docs/README.md)
indexes the full contracts; when it disagrees with this skill, it wins.

## Which direction is this?

The two directions are different tools and it is worth being explicit,
because picking the wrong one wastes a lot of setup:

| You want | Direction | Skill |
|---|---|---|
| "Does this PR's code match the Figma design?" | **design → code** | **this skill** |
| "Publish our component system into Figma as a sticker sheet" | **code → design** | [compose-design-catalog](../compose-design-catalog/SKILL.md) → [figma-catalog-import](../figma-catalog-import/SKILL.md) |
| "Is the rendered UI different from last commit?" | neither — no design involved | [compose-preview-review](../compose-preview-review/SKILL.md) |

**Round-tripping** — running both directions on one project — is supported
and covered in [references/round-trip.md](./references/round-trip.md). Read
the direction policy section below first: which side is canonical is a
committed decision, not a per-run choice.

## Set-up order

Do these in order. Each step is useless without the one before it.

### 1. Decide the direction (`.design-parity.json`)

Parity has a **committed direction**. It decides who wins when the two sides
disagree, and therefore whether a failing check blocks the PR.

```json
{
  "$schema": "https://github.com/yschimke/design-parity/raw/main/packages/policy/schema/parity-config.schema.json",
  "direction": "code-led"
}
```

- `design-led` — the design is canonical. A parity failure **blocks**.
  Right for a team with a maintained design system.
- `code-led` — the code is canonical; the design is a reference that may
  lag. Findings are reported but don't block. Also the precondition for
  pushing code renders *back* onto the canvas.
- `auto` — resolved deterministically by `@design-parity/policy` from the
  repo's maturity.

### 2. Map code to design (`design-map.json`)

Correspondence is resolved in this order: **Code Connect** (Figma only) →
committed **`design-map.json`** → **name convention** with a low-confidence
flag. Anything but the first two is a guess; prefer to commit the map.

```json
{
  "components": [
    { "code": "ui/Button.kt#PrimaryButton", "source": "figma",
      "ref": "figma:AbCdEf123456/1:42" },
    { "code": "ui/Card.kt#OfferCard", "source": "claude-design",
      "ref": "design/reference/offer-card.html" },
    { "code": "ui/Device.kt#DeviceScreen", "source": "figma",
      "ref": [
        { "ref": "figma:AbCdEf123456/10:2", "state": "default" },
        { "ref": "figma:AbCdEf123456/10:8", "state": "error" },
        { "ref": "figma:AbCdEf123456/10:9", "theme": "dark" }
      ] }
  ]
}
```

One code handle can bind to **several** design nodes keyed by `state` /
`theme`. `npx design-parity reverse figma:AbCdEf/1:42` answers the opposite
question — which code implements this design node — for sources without Code
Connect.

If a repo has **no** committed `design-map.json`, the action posts a one-time
notice pointing at the interactive bootstrap (`design-parity-bootstrap`)
rather than guessing the mapping at run time, and never blocks. Don't
hand-author a map for a project that hasn't run bootstrap — bootstrap also
materialises tokens and tuned check thresholds.

### 3. Pick a reference source

| Source | Auth | Notes |
|---|---|---|
| `claude-design` | none | Commit the HTML export per screen; rasterized headlessly. Fully offline and deterministic — **best fit for a first adoption**. |
| `figma` | `FIGMA_TOKEN` | REST + Code Connect. The only source with automatic correspondence. Rate-limited — see the cache below. |
| `stitch` | yes | `stitch:<projectId>/<screenId>` (two parts; a single-part ref is rejected). Needs the SDK and a headless Chrome. |
| `bundle` | none | A committed directory or `.zip` of reference PNGs + `manifest.json`. No design-tool API at all. |

### 4. Render candidates

Parity asserts **candidate render ≈ what ships**, so render on a target that
represents the shipped UI. For Compose Multiplatform, the Desktop/JVM target
renders with **no Android emulator** — the cheapest path, and the reason CMP
is the recommended way to try the tool.

Two traps specific to this step:

- **Theme.** CMP apps usually theme via `MaterialTheme` / a
  `CompositionLocal`, so the Android night-mode `uiMode` is unset and the
  candidate gets no `theme` — which then fails to pair with a `theme`-tagged
  reference. Theme is derived in precedence order: an explicit `theme` hint
  on the preview (set this when theming via a `CompositionLocal`), then the
  Android `uiMode`, then the preview id's **trailing** `_Dark`/`_Light`/
  `Night` token (only the last token, so `Home_LightOn` is not mistaken for
  light).
- **Semantics.** Make sure the bundle carries the semantics blob (a11y tree
  + resolved fg/bg colours + typography). With it, the full a11y/i18n +
  contrast + token checks run; without it they degrade silently to
  visual/structural-only.

Platform-specific UI (Android-only APIs, `actual` impls, Android resources)
won't match a Desktop render. Render those on Android, or lift the screen's
composable into `commonMain`.

### 5. Wire the reference cache — before you wire the run

**Do this before the parity workflow, not after.** Skipping it is the single
most damaging mistake in a real adoption.

A run that fetches every reference live pays the full reference cost on every
commit, against a **per-token** rate limiter. Observed on a 77-component
catalog: 18 components produced a verdict and 59 reported
`figma: rate limited (429)` — and a run covering a quarter of the catalog
looked exactly like one covering all of it, with a *different* quarter each
run.

The fix is to split the two sides by cadence. See
[references/reference-cache.md](./references/reference-cache.md).

### 6. Wire the parity run

`.github/workflows/design-parity.yml`, calling the reusable workflow — see
[references/ci.md](./references/ci.md) for the sharded/exhaustive setup and
the standalone action form.

## Reading a verdict

Findings are ordered by what actually matters, not by pixel count:
**a11y + i18n first, then tokens, then pixels.** A 3px shift with passing
contrast is a lower-priority finding than a dark-theme contrast failure that
diffs to almost nothing.

On a `push` to the development branch the action publishes browsable
artifacts to a permanent `design-parity/<dev-branch>` branch: a landing
`index.html`, each component's self-contained `report.html` triptych
(reference | candidate | diff), a machine-readable `verdict.json`, and — when
the run exposes design-system tokens — the aggregated DTCG table at
`tokens/design-system.tokens.json`.

History accrues automatically: each run re-parents on the branch tip (a
linear chain, fast-forward push, no force), and because `report.html` is
deterministic a run that doesn't change a screen touches no file and adds no
commit noise. The history therefore shows exactly the runs where a screen's
code or mock actually moved.

## Reference docs

| Path | When to read |
|---|---|
| [references/reference-cache.md](./references/reference-cache.md) | Importing the design side on its own schedule into a committed cache so the parity run makes **zero** Figma calls. Why the coupled version silently reported on a quarter of a catalog. |
| [references/ci.md](./references/ci.md) | The two reusable workflows (import + run), scoping the render, and sharding an exhaustive check across N jobs. |
| [references/round-trip.md](./references/round-trip.md) | Running both directions on one project: catalog export out to Figma, parity checks back in, and the opt-in Code-to-Canvas push-back. What must agree between them. |

## Related

- [**compose-preview**](../compose-preview/SKILL.md) — the candidate
  renderer.
- [**compose-design-catalog**](../compose-design-catalog/SKILL.md) /
  [**figma-catalog-import**](../figma-catalog-import/SKILL.md) — the
  code→design direction.
- [**compose-preview-ci**](../compose-preview-ci/SKILL.md) — the sibling CI
  surface for plain preview diffs (no design reference involved).
