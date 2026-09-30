---
name: compose-preview
description: Render a Jetpack Compose or Compose Multiplatform @Preview to PNG in one call (MCP render_preview, or the compose-preview CLI) and look at it. Use to verify UI changes, iterate on designs, and compare before/after.
---

# Compose Preview

Render `@Preview` composables to PNG without Android Studio (Android via
Robolectric, CMP Desktop via Skia). CLI, Gradle plugin and renderers ship from
[compose-ai-tools](https://github.com/yschimke/compose-ai-tools); the MCP server
from [compose-preview-server](https://github.com/yschimke/compose-preview-server).

## Render first

With the local MCP server attached (compose-preview-server 3.78.0+), its
`initialize` instructions say how to call it: `render_preview
preview=<FunctionName>`, no exploring or registering first, no hand-built
mocks. Follow them. This skill adds the budget: a routine render is at most
three tool calls, with no base64 in the reply and images only when you need to
see them.

1. **Render.** If your client reads local files (Claude Code, Codex, Gemini
   CLI, OpenCode, Antigravity), pass `inline=false`. The result is `pngPath`,
   `sha256`, dimensions and `changed`, with no image tokens. If it lists
   `otherMatches`, render one only if the person asked about it.
2. **Look only when you need to.** Read `pngPath` with your file reader
   before you describe or judge the UI; that is what the person sees. Skip the
   read when `changed` or `sha256` already answers the question, such as
   "did my edit land?". Describe only what you saw. If you can't view images
   here, say so plainly.
3. **Reply** briefly, with `pngPath` so the person can open the same image.

**Sweeps use hashes.** For more than one render (variants, devices, font
scales, locales, a before/after check), pass `observe=hash` or use
`render_matrix`, which returns per-cell hashes. Fetch pixels only for the
final screen or the cells whose hash moved.

**Hand multi-render reviews to `design-reviewer`.** If a `design-reviewer`
subagent is available (the compose-ag-plugin plugins ship one), delegate
accessibility, font-scale, round-device and other matrix checks to it so the
images stay out of your context, and relay its verdict and paths. Without one,
run the sweep yourself with hashes.

**After a source edit**, call `render_preview` again. `notify_file_changed` is
optional. **If the result says it is stale**, make exactly one more call with
`force: {"reason": "<why>"}`. **Never** run `./gradlew`, `clean`, or delete
`build/` dirs to chase a render; if a forced render is still wrong, read
[mcp.md § Troubleshooting](./references/mcp.md#troubleshooting-first--when-not-to-act)
(start with `compose-preview mcp doctor`).

**Details on request.** Add `details: ["a11y", "layout"]` only when the
person asks about accessibility or layout. `observe=png` returns inline pixels
for clients that can't read files.

**No MCP tool?** Use the CLI: `compose-preview show --json --filter <Name>`,
then read the entry's `pngPath`. Stale: `--force=<reason>`, once. See
[cli.md](./references/cli.md). On either path, only output from the render
tools is a render: never a hand-built HTML, CSS or SVG mock. Report a failed
render with its error.

**Not previewable** (takes a ViewModel or injected service)? Propose extracting
a stateless inner composable and preview that
([state-hoisting.md](./references/state-hoisting.md)).

## Install / update (only if missing)

Check with `compose-preview --version`. Install the skills and CLI:

```sh
npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
# No Node:
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash
```

Update with `compose-preview update` (skills: `npx skills update`). Plugin
setup, MCP registration, and the Gradle init script are in
[setup.md](./references/setup.md).

## Reference index

Read only what the task needs.

| Topic | Read |
|---|---|
| Install, update, apply the Gradle plugin, `mcp install`, zero-code init script | [setup.md](./references/setup.md) |
| CLI commands, `--filter`/`--id`/`--force`, `counts` buckets, render filenames, SVG output, Gradle tasks, `build-brief` for non-preview builds | [cli.md](./references/cli.md) |
| Local MCP server: tools, history (`history_list`/`history_diff`), multi-workspace, **troubleshooting** | [mcp.md](./references/mcp.md) |
| Interaction loop: semantic refs, `observe` modes, `diff_semantics`, crop, `render_matrix` (variants/matrix), record → test, failure `kind`s | [agent-loop.md](./references/agent-loop.md) |
| Accessibility (ATF, `compose-preview a11y`) | [a11y.md](./references/a11y.md) |
| Per-render data (a11y, layout, recomposition, SVG) | [data-products.md](./references/data-products.md) |
| Multi-preview, GIFs, `@SettledPreview`, scrolling captures | [capture-modes.md](./references/capture-modes.md) |
| Wear Compose UI / Wear Tiles | [wear-ui.md](./references/wear-ui.md), [wear-tiles.md](./references/wear-tiles.md) |
| CMP `:shared` modules | [cmp-shared.md](./references/cmp-shared.md) |
| Android XML drawables / icons | [resource-previews.md](./references/resource-previews.md) |
| Runtime permissions per render | [runtime-permissions.md](./references/runtime-permissions.md) |
| Editable override knobs | [override-knobs.md](./references/override-knobs.md) |
| Display filters | [display-filters.md](./references/display-filters.md) |
| Remote Compose, `compose-preview rc` | [remote-compose.md](./references/remote-compose.md) |
| Remote catalog MCP (`serve`, no checkout) | [catalog-mcp.md](./references/catalog-mcp.md) |
| Gated server access (`compose-preview auth request`) | [server-access.md](./references/server-access.md) |
| Agent allowlists, staging PNGs | [permissions.md](./references/permissions.md) |
| Cloud sandboxes (Claude Code, Codex) | [agent-cloud.md](./references/agent-cloud.md), [claude-cloud.md](./references/claude-cloud.md) |
| VS Code extension (humans) | [vscode.md](./references/vscode.md) |

**CI and PR review** live in opt-in sibling skills:
[compose-preview-ci](../compose-preview-ci/SKILL.md) (baselines, PR-comment
Actions) and [compose-preview-review](../compose-preview-review/SKILL.md)
(base vs. head render and diff). Add one with
`npx skills add yschimke/skills --global --yes --skill <name>`.
