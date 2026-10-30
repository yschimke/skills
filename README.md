# Skills

**Start here:** <https://yschimke.github.io/compose-ai-tools/> for the CLI and your project's previews;
<https://ui.coo.ee/start> for designing screens with an agent in the UI Builder.

Skills for rendering and reviewing [Jetpack Compose] and [Compose
Multiplatform] UI from agent workflows. They pair with the
`compose-preview` CLI and Gradle plugin published from
[yschimke/compose-ai-tools] — the CLI does the rendering, these skills
tell the agent how to drive it.

These are the generic skills, written to work in any agent host. The
per-harness integrations (plugin manifests, MCP wiring, hooks and setup) live
in [yschimke/compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins),
whose single marketplace also installs these skill bundles for Claude Code and
Codex.

[Jetpack Compose]: https://developer.android.com/jetpack/compose
[Compose Multiplatform]: https://www.jetbrains.com/compose-multiplatform/
[yschimke/compose-ai-tools]: https://github.com/yschimke/compose-ai-tools

## Install

```sh
npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
```

That installs the two default skills; the `compose-preview` skill's bundled
stub downloads the CLI on first use. Every other route (the no-Node `curl`
installer, plugin marketplaces), the optional skills, installer flags and
updating are in **[setup.md](skills/compose-preview/references/setup.md)**.
Wiring MCP, including which of the two servers you want and the one hosted URL
(`https://preview.coo.ee/mcp`), is in
**[mcp.md](skills/compose-preview/references/mcp.md)**. Per-harness wiring lives in
[compose-agent-plugins' host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md).

### Bundles

`plugins/` holds three bundles generated from `skills/`, so a host can install
the default pair without the rest:

| Bundle | Skills |
|---|---|
| `compose-skills` | `compose-preview`, `compose-ui-builder` (the default pair) |
| `compose-review-skills` | `compose-preview-review`, `compose-preview-ci`, `design-parity-review` |
| `compose-design-skills` | `compose-preview-design-board`, `compose-design-catalog`, `figma-catalog-import` |

The root `yschimke-skills` plugin carries all eight. Install either it or the
bundles, never both, or each skill appears twice.

## Skills

- [`compose-preview`](skills/compose-preview/SKILL.md) — render
  `@Preview` composables to PNG outside Android Studio: Android (Jetpack
  Compose via Robolectric) and Compose Multiplatform Desktop
  (`ImageComposeScene` + Skia). Covers capture modes, multi-preview
  annotations, paused-clock animations, accessibility checks, display filters,
  Wear UI, resource previews, a token-frugal agent loop (semantic refs,
  `observe`/`diff_semantics`, crop, record-to-test, typed failure kinds),
  editable **SVG** export, cloud sandboxes, requesting scoped access to a
  gated preview server, and running a whole APK without an emulator
  (`compose-preview launch` and the MCP `simulator_*` tools: driving an app,
  adb equivalents, foldables, multiple displays, home-screen widgets, network,
  Wi-Fi and Bluetooth conditions, Wear tiles and ambient mode, and a paired or
  agent-played Wearable Data Layer).
- [`compose-preview-review`](skills/compose-preview-review/SKILL.md) —
  review pull requests that change Compose UI by rendering `@Preview`
  composables on base and head and diffing them. Pairs with
  `compose-preview`; covers agent-authored PRs, local review
  workflows, mention-triggered CI agent sessions, and
  triaging flaky/unstable previews.
- [`compose-preview-ci`](skills/compose-preview-ci/SKILL.md) — stand up
  the GitHub Actions that render previews and post before/after diff
  comments: the `compose-preview/main` baselines branch, the unified
  `apply` action, and the **two-stage render/publish split** that is the
  only way a **fork** PR can get a diff comment (a single-job workflow
  fails silently there). Also covers CLI/plugin version skew, migrating
  off the four legacy actions, and making runs cheap — parallel pipeline
  jobs, change-scoped rendering, A/B variant comparison.
- [`compose-preview-design-board`](skills/compose-preview-design-board/SKILL.md)
  — assemble rendered `@Preview` PNGs into a single self-contained HTML
  design board (categories, groups, captions, layout) for import into
  Claude Design and other design tools. Pairs with `compose-preview`;
  turns a set of renders into one coherent brief rather than loose
  screenshots.
- [`compose-design-catalog`](skills/compose-design-catalog/SKILL.md) —
  generate an importable design-artifact **sticker sheet** for a whole
  Compose component system (Compose M3, Wear Compose M3, Glimmer,
  Glance/Wear widgets): each component in its primary modes, in two
  variants (ideal render + bordered layout), with extracted design
  tokens and accessibility greenlines, laid out for Figma / Stitch /
  Claude Design import, and served at `preview.coo.ee/<system>/`. Covers
  authoring and **validating** the `catalog.spec.json` inventory
  (`init-catalog-spec` / `validate-catalog-spec` + its JSON schema) before
  rendering. Code-led — the published Figma kits are seed only. Pairs with
  `compose-preview` and `compose-preview-design-board`.
- [`compose-ui-builder`](skills/compose-ui-builder/SKILL.md) — **author** a
  Compose screen or Wear widget over MCP against a `compose-preview serve`
  deployment, with no checkout: create a design, insert and edit nodes in the
  catalog's own vocabulary, and export the Kotlin, PNG or SVG. Covers the
  capability grant (`ui-builder-read/write/export`, not a scope), known-good
  starter documents, the component/slot/enum tables from `list_catalogs`, which
  components the exporter refuses, running a **local** session with no host
  (`ui-builder --no-project`, `--agent-grant-capabilities`, the two MCP
  surfaces), the reference overlay, and working with a person through comment
  threads and progress links.
- [`figma-catalog-import`](skills/figma-catalog-import/SKILL.md) — import
  a published `design-artifacts/<system>` catalog (from
  `compose-design-catalog`) into a **Figma** file as authoritative,
  code-derived renders: grouped, with a11y greenlines, spacing redlines,
  a token→variable collection, and a `design-map.json` correspondence.
  Decides the import case first (code-led vs design-led × new vs existing
  file), never delete-and-rebuilds, and reconciles in place keyed by
  `componentId`. Prefers the `@design-parity/figma-plugin`; documents the
  Figma-MCP runbook as fallback. Pairs with `compose-design-catalog`.
- [`design-parity-review`](skills/design-parity-review/SKILL.md) — the
  **design → code** direction: prove a UI pull request matches its
  intended design by diffing the rendered candidate against a Figma /
  Stitch / Claude Design reference and posting a parity verdict.
  Covers the committed direction policy, `design-map.json`
  correspondence, the **reference cache** that makes a parity run cost
  zero Figma calls (and why skipping it silently reports on a quarter of
  a catalog), sharding an exhaustive run, and round-tripping both
  directions on one project including opt-in Code-to-Canvas push-back.
  Drives [`design-parity`](https://github.com/yschimke/design-parity).

The CLI, Gradle plugin, renderer, and local daemon MCP server live in
[yschimke/compose-ai-tools]; the preview server behind `compose-preview
serve` — including its own catalog MCP endpoint — lives in
[yschimke/compose-preview-server]; the parity bot and catalog exporter
live in [yschimke/design-parity]; the VS Code extension lives in
[yschimke/compose-preview-vscode]. This repo is content-only.

[yschimke/design-parity]: https://github.com/yschimke/design-parity
[yschimke/compose-preview-server]: https://github.com/yschimke/compose-preview-server
[yschimke/compose-preview-vscode]: https://github.com/yschimke/compose-preview-vscode

### How these relate

Two stages — **render**, then **arrange & deliver**. `compose-preview` is the
shared foundation; the rest split by *what you're arranging* (a curated subset
vs a whole system) and *where it lands*:

```
render              arrange                        deliver
──────              ───────                        ───────
compose-preview ─┬─ compose-preview-review ──────→ a PR base/head diff
                 │    └─ compose-preview-ci ─────→ …the same, posted by CI
                 │       (incl. the two-stage
                 │        split for fork PRs)
                 │
                 ├─ compose-preview-design-board ─┐  (curated subset → HTML)
                 │                                 ├─→ Claude Design  (light HTML/PNG
                 └─ compose-design-catalog ───────┤                    drop-in, in-skill)
                    (whole system → bundle)        └─→ Figma → figma-catalog-import
                                                            (the one heavy destination:
                                                             plugin + in-place reconcile
                                                             + design-map correspondence)

                          ◀── design-parity-review ──── Figma / Stitch / Claude Design
                              (the return leg: is the code at parity with the design?)
```

- **board vs catalog** — `design-board` arranges a *curated subset* of renders
  for a feature/PR into one HTML brief; `compose-design-catalog` catalogs a
  *whole component system* into a durable, tool-neutral bundle. Different
  granularity, same next step.
- **Claude Design vs Figma** — Claude Design is a light drop-in (open the HTML /
  upload the PNGs), so it stays a *step inside* board/catalog. Figma is heavy (a
  plugin, reconcile-by-`componentId`, a `design-map.json`), so it's factored out
  into **`figma-catalog-import`** — the single Figma delegate for *both*
  arrangers, never duplicated in either.
- **review vs ci** — `compose-preview-review` is about *reading* a diff (as a
  human or an agent); `compose-preview-ci` is about *standing up the pipeline*
  that produces it. Different task, different trigger, so they're separate.
- **the two directions** — everything above the return leg is **code → design**
  (the code is authored, the design artifact is generated). `design-parity-review`
  is **design → code**: the design is the reference and the code is checked
  against it. Which one is canonical is a committed decision (`.design-parity.json`),
  not a per-run choice — and a project running both should read
  [round-trip.md](skills/design-parity-review/references/round-trip.md) before
  wiring the second one.
- **authoring is a different axis** — everything in that diagram starts from
  code you already have. **`compose-ui-builder`** starts from nothing: a design
  is authored in the builder's own catalog vocabulary, on a server, with no
  checkout, and *produces* the Kotlin. It feeds the same destinations (its PNG
  and SVG exports are a design board's or a parity run's input) but its input is
  a person's intent rather than a `@Preview`.

### Common routes

| You want to… | Read, in order |
|---|---|
| See a composable without Android Studio | `compose-preview` |
| Reach a gated `serve` deployment as an agent | `compose-preview` → [server-access.md](skills/compose-preview/references/server-access.md) |
| Review a UI PR | `compose-preview-review` |
| Have CI post before/after diffs on every PR | `compose-preview-ci` |
| …and the repo takes **fork** PRs | `compose-preview-ci` → [fork-prs.md](skills/compose-preview-ci/references/fork-prs.md) |
| Get an app's screens in front of a designer, once | `compose-preview` → `compose-preview-design-board` |
| Publish a component system into Figma, refreshed on every change | `compose-preview` → `compose-design-catalog` → `figma-catalog-import` |
| Check a PR against its Figma design | `design-parity-review` (wire the reference cache **before** the run) |
| Build or change a screen with no checkout, and get Kotlin out | `compose-ui-builder` (start at its core creation loop) |
| Work on a design a designer is editing right now | `compose-ui-builder` → its comment and `await_design` loop |
| Run both directions on one project | `design-parity-review` → [round-trip.md](skills/design-parity-review/references/round-trip.md) |

## Contributing

Skills live at `skills/<skill-name>/SKILL.md`, flat (no language or
topic nesting). The `name:` in the SKILL.md frontmatter must match the
directory name. See [AGENTS.md](AGENTS.md) for the full contributor
contract.

## License

[Apache 2.0](LICENSE)

Audit results follow the same chat summary and evidence-link convention in every
host. App-capable viewers can show measured render details; UI Builder can show
saved guideline reviews in its Issues panel. See the
[presentation checklist](skills/compose-preview/references/design-guidelines.md#show-the-review-and-offer-another-run).

## Repository merge policy

Repository settings and required checks are managed by
[yschimke/renovate-config](https://github.com/yschimke/renovate-config/tree/main/repo-policy).
Pull requests use Conventional Commit titles and squash merges. Run
`scripts/install-git-hooks.sh` to enable the same attribution checks locally.
