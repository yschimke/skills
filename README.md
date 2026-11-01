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
whose marketplace vendors these skills for Claude Code and Codex.

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
  Wi-Fi and Bluetooth conditions, Wear tiles and ambient mode, a paired or
  agent-played Wearable Data Layer, and restart and live reload while
  iterating on an app).
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

The CLI, Gradle plugin, renderer, and local daemon MCP server live in
[yschimke/compose-ai-tools]; the preview server behind `compose-preview
serve` — including its own catalog MCP endpoint — lives in
[yschimke/compose-preview-server]; the VS Code extension lives in
[yschimke/compose-preview-vscode]. This repo is content-only.

[yschimke/compose-preview-server]: https://github.com/yschimke/compose-preview-server
[yschimke/compose-preview-vscode]: https://github.com/yschimke/compose-preview-vscode

### Common routes

| You want to… | Read, in order |
|---|---|
| See a composable without Android Studio | `compose-preview` |
| Reach a gated `serve` deployment as an agent | `compose-preview` → [server-access.md](skills/compose-preview/references/server-access.md) |
| Review a UI PR | `compose-preview-review` |
| Have CI post before/after diffs on every PR | `compose-preview-ci` |
| …and the repo takes **fork** PRs | `compose-preview-ci` → [fork-prs.md](skills/compose-preview-ci/references/fork-prs.md) |
| Build or change a screen with no checkout, and get Kotlin out | `compose-ui-builder` (start at its core creation loop) |
| Work on a design a designer is editing right now | `compose-ui-builder` → its comment and `await_design` loop |

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
