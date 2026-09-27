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

With the local MCP server attached (compose-preview-server 3.78.0+), one call
is enough. **Do not explore first.** No `list_projects`, `status`, grepping
source, or running Gradle before the first render; the server registers the
workspace itself (MCP roots or cwd).

1. **Render.** `render_preview` with `preview: "<FunctionName>"` (the function
   name, or an FQN suffix like `home.HomeScreenPreview`). If it returns
   `otherMatches`, those are the other variants; pick one and render again only
   if the person asked about it.
2. **Look.** Open the image yourself. Clients that read files should pass
   `inline=false`: the result is JSON `{uri, pngPath, widthPx, heightPx, sha256}`,
   and you read `pngPath` with your file reader, so you see what the person sees. Describe only what you
   saw. If you can't view images here, say so plainly. Don't infer.
3. **Reply** with what the render shows and keep `pngPath` so the person can
   open the same image.

**After a source edit**, call `render_preview` again. `notify_file_changed` is
optional. **If the result says it is stale**, make exactly one more call with
`force: {"reason": "<why>"}`. **Never** run `./gradlew`, `clean`, or delete
`build/` dirs to chase a render; if a forced render is still wrong, read
[mcp.md § Troubleshooting](./references/mcp.md#troubleshooting-first--when-not-to-act)
(start with `compose-preview mcp doctor`).

**Cheaper looks.** `observe` defaults to semantics (a cheap text tree). Pass
`observe=png` for pixels and `observe=hash` for "did it change?" sweeps across
many previews. Add `details: ["a11y", "layout"]` for accessibility findings or
the layout tree alongside the render.

**No MCP tool?** Use the CLI: `compose-preview show --json --filter <Name>`,
then read the entry's `pngPath`. Stale: `--force=<reason>`, once. See
[cli.md](./references/cli.md).

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
