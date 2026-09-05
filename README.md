# Skills

Skills for rendering and reviewing [Jetpack Compose] and [Compose
Multiplatform] UI from agent workflows. They pair with the
`compose-preview` CLI and Gradle plugin published from
[yschimke/compose-ai-tools] — the CLI does the rendering, these skills
tell the agent how to drive it.

[Jetpack Compose]: https://developer.android.com/jetpack/compose
[Compose Multiplatform]: https://www.jetbrains.com/compose-multiplatform/
[yschimke/compose-ai-tools]: https://github.com/yschimke/compose-ai-tools

## Install

Three install paths — all of them end up with a working `compose-preview`
CLI on `$PATH`. The two skill-marketplace paths ship a self-bootstrapping
stub at `skills/compose-preview/scripts/compose-preview`; the first time
that stub is invoked it runs the canonical installer (`--cli-only`) and
re-execs into the real CLI.

**Curl the installer directly** (gets the CLI + every skill bundle below +
per-host symlinks for Claude Code and Codex into `~/.agents/skills/` in one
shot):

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh \
  | bash
```

**Install as a Claude Code plugin** — drops the skill content (including
the bootstrap stub) into `~/.claude/plugins/`:

```
/plugin marketplace add yschimke/skills
/plugin install yschimke-skills@yschimke-skills
```

**Or via the [skills CLI](https://skills.sh):**

```
npx skills add yschimke/skills
```

With the two marketplace paths, the CLI download happens on first
invocation of the stub — there's no separate "now install the CLI" step.

## Skills

- [`compose-preview`](skills/compose-preview/SKILL.md) — render
  `@Preview` composables to PNG outside Android Studio. Covers Android
  (Jetpack Compose via Robolectric) and Compose Multiplatform Desktop
  (`ImageComposeScene` + Skia), with design notes on capture modes,
  multi-preview annotations, paused-clock animations, accessibility
  checks, display filters, Wear UI, resource previews, a Playwright-style
  token-frugal agent loop (semantic-ref targeting on Desktop + Android,
  `observe`/`diff_semantics`, `render_preview crop`, record-to-test, typed
  render-failure kinds), editable **SVG vector** export (`compose/figma-svg` +
  wireframe), cloud sandbox setup, how to ask a human for temporary,
  scoped access to a gated preview server rather than for its own token, and the
  **remote catalog MCP** that access buys you — a served catalog's
  `list_previews` / `render_preview` / `list_devices` / `history_*` surface,
  distinct from the local daemon MCP.
- [`compose-preview-review`](skills/compose-preview-review/SKILL.md) —
  review pull requests that change Compose UI by rendering `@Preview`
  composables on base and head and diffing them. Pairs with
  `compose-preview`; covers agent-authored PRs, local review
  workflows, mention-triggered CI agent sessions (`claude.yml`), and
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
  rendering, including the `locales` axis for a bilingual sheet and the `themes`
  inventory for an imported project that cannot declare its own palettes. Code-led — the published Figma kits are seed only. Pairs with
  `compose-preview` and `compose-preview-design-board`.
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

The CLI, Gradle plugin, renderer, local MCP server, and VS Code extension
live in [yschimke/compose-ai-tools]; the **preview server** behind
`compose-preview serve` — catalog hosting, live render sessions, the browser
viewer, and the remote catalog MCP — lives in
[yschimke/compose-preview-server]; the parity bot and catalog exporter
live in [yschimke/design-parity]. This repo is content-only.

[yschimke/design-parity]: https://github.com/yschimke/design-parity
[yschimke/compose-preview-server]: https://github.com/yschimke/compose-preview-server

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
- **the two directions** — everything above the dashed leg is **code → design**
  (the code is authored, the design artifact is generated). `design-parity-review`
  is **design → code**: the design is the reference and the code is checked
  against it. Which one is canonical is a committed decision (`.design-parity.json`),
  not a per-run choice — and a project running both should read
  [round-trip.md](skills/design-parity-review/references/round-trip.md) before
  wiring the second one.

### Common routes

| You want to… | Read, in order |
|---|---|
| See a composable without Android Studio | `compose-preview` |
| Reach a gated `serve` deployment as an agent | `compose-preview` → [server-access.md](skills/compose-preview/references/server-access.md) |
| Drive a **remote** preview server's catalog over MCP | `compose-preview` → [catalog-mcp.md](skills/compose-preview/references/catalog-mcp.md) |
| Review a UI PR | `compose-preview-review` |
| Have CI post before/after diffs on every PR | `compose-preview-ci` |
| …and the repo takes **fork** PRs | `compose-preview-ci` → [fork-prs.md](skills/compose-preview-ci/references/fork-prs.md) |
| Get an app's screens in front of a designer, once | `compose-preview` → `compose-preview-design-board` |
| Publish a component system into Figma, refreshed on every change | `compose-preview` → `compose-design-catalog` → `figma-catalog-import` |
| Check a PR against its Figma design | `design-parity-review` (wire the reference cache **before** the run) |
| Run both directions on one project | `design-parity-review` → [round-trip.md](skills/design-parity-review/references/round-trip.md) |

## Contributing

Skills live at `skills/<skill-name>/SKILL.md`, flat (no language or
topic nesting). The `name:` in the SKILL.md frontmatter must match the
directory name. See [AGENTS.md](AGENTS.md) for the full contributor
contract.

## License

[Apache 2.0](LICENSE)

[plugins]: https://docs.claude.com/en/docs/claude-code/plugins
