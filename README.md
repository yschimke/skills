# Skills

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

**Default: the [skills CLI](https://skills.sh).** Install the skill content,
then run the bundled `compose-preview` stub once to get the CLI:

```sh
npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
~/.agents/skills/compose-preview/scripts/compose-preview --version   # first run installs the CLI and puts it on PATH
```

`npx skills add` installs the skill content only, into `~/.agents/skills/`
with per-agent links. The stub at `skills/compose-preview/scripts/compose-preview`
runs the canonical installer with `--cli-only` on its first run: it downloads
the CLI, links `~/.local/bin/compose-preview`, adds `~/.local/bin` to your
bash/zsh/fish startup files, and re-execs into the real CLI. Open a new
terminal afterwards. To update: `compose-preview update` updates the CLI (and
PATH), and `npx skills update` updates the skills.

The default is two skills: `compose-preview` (render, inspect, CLI and MCP)
and `compose-ui-builder` (author designs over MCP). Every installed skill's
description loads into each agent session, so the rest are opt-in. Add them
by name with another `--skill` (for example `--skill compose-preview-review
--skill compose-preview-ci`), or drop the `--skill` flags to pick from the
list. The other skills: `compose-preview-review`, `compose-preview-ci`,
`compose-preview-design-board`, `compose-design-catalog`,
`figma-catalog-import`, `design-parity-review`.

**Fallback: curl the installer** — when there's no Node, or you want the CLI
and the same two default skills (with per-host links for Claude Code and
Codex under `~/.agents/skills/`) in one step. Add skills with
`bash -s -- --skills compose-preview-review,compose-preview-ci`, or take them
all with `bash -s -- --all-skills`:

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash
```

The installer adds `~/.local/bin` to your shell startup files only when it
isn't already on `PATH` and no startup file already mentions it. Pass
`--no-modify-path` (`… | bash -s -- --no-modify-path`, or
`compose-preview update --no-modify-path`) to leave them alone entirely;
`MODIFY_PATH=0` in the environment does the same, including for older CLIs
whose `update` doesn't accept the flag.

**Alternative: a Claude Code or Codex plugin marketplace** — see
[Per-harness plugins](#per-harness-plugins) below, which also adds the MCP
servers and harness wiring. The plugin ships the same bootstrap stub, so the
CLI download happens on its first invocation.

### Per-harness plugins

These skills cover *how* to drive the tools. Installing them into a particular
agent host, together with the MCP servers, hooks and setup that host needs, is
documented in one place:
[`yschimke/compose-agent-plugins`'s README](https://github.com/yschimke/compose-agent-plugins#readme).

The skills are grouped into three bundles under `plugins/`, generated from
`skills/`, so a host can install the default pair without the rest:

| Bundle | Skills |
|---|---|
| `compose-skills` | `compose-preview`, `compose-ui-builder` (the default pair) |
| `compose-review-skills` | `compose-preview-review`, `compose-preview-ci`, `design-parity-review` |
| `compose-design-skills` | `compose-preview-design-board`, `compose-design-catalog`, `figma-catalog-import` |

The root `yschimke-skills` plugin carries all eight. Install either it or the
bundles, never both, or each skill appears twice.

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
  wireframe), cloud sandbox setup, and how to ask a human for temporary,
  scoped access to a gated preview server rather than for its own token.
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
  catalog's own vocabulary, and export the Kotlin, PNG or SVG. Carries the
  things a session would otherwise spend its first hour discovering — the
  capability grant (`ui-builder-read/write/export`, not a scope), known-good
  starter documents, the component/slot/enum tables extracted from the 70 KB
  `list_catalogs` call, which components the *exporter* refuses even though the
  document accepts them, and which calls are cheap. Running a **local**
  session with no host at all is its own section (`ui-builder --no-project`, the
  `--agent-grant-capabilities` ceiling that decides whether MCP works, and the
  two MCP surfaces' different tool names). Also covers the browser's
  persistent reference overlay (overlay/difference/split/boxes), progress links
  and bounded comment waits, sharing a design with a person, and the comment
  threads that make an agent a participant rather than a batch job.
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
- **the two directions** — everything above the dashed leg is **code → design**
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
| Build or change a screen with no checkout, and get Kotlin out | `compose-ui-builder` (start at its five-call quickstart) |
| Work on a design a designer is editing right now | `compose-ui-builder` → its comment and `await_design` loop |
| Run both directions on one project | `design-parity-review` → [round-trip.md](skills/design-parity-review/references/round-trip.md) |

## Contributing

Skills live at `skills/<skill-name>/SKILL.md`, flat (no language or
topic nesting). The `name:` in the SKILL.md frontmatter must match the
directory name. See [AGENTS.md](AGENTS.md) for the full contributor
contract.

## License

[Apache 2.0](LICENSE)

[plugins]: https://docs.claude.com/en/docs/claude-code/plugins
