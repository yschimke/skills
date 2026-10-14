# MCP servers: local daemon and hosted catalog

The one reference for wiring compose-preview into an MCP-aware agent host. The
first section says which of the two servers you want; the rest of this file is
the **local** one. The hosted one's tools and grant flow are in
[`catalog-mcp.md`](./catalog-mcp.md). Contributor detail is in compose-ai-tools'
[`mcp/README.md`](https://github.com/yschimke/compose-ai-tools/blob/main/mcp/README.md).

## Which MCP server

There are **two** compose-preview MCP servers, and they are not the same thing.
Most confusion is local instructions aimed at the hosted server, or the reverse.

| | **Local daemon MCP** (this file) | **Hosted catalog MCP** ([catalog-mcp.md](./catalog-mcp.md)) |
| --- | --- | --- |
| What it renders | *your* project's `@Preview`s, on your machine | published library catalogs (Material 3, Wear M3, …) and UI Builder designs |
| Launched as | `compose-preview mcp serve`, over stdio, by your agent host | Streamable HTTP, `POST https://preview.coo.ee/mcp` (or another `compose-preview serve` host's `/mcp`) |
| Tools | `render_preview`, `render_matrix`, `find_previews_for_file`, … | `catalog_*` and `ui_builder_*` |
| Needs a checkout | yes | no |
| Credential | none: it is your machine | a scoped grant, always ([server-access.md](./server-access.md)) |
| Can register projects, watch files, rebuild | yes | no |
| Ships from | [`compose-ai-tools`](https://github.com/yschimke/compose-ai-tools) CLI | [`compose-preview-server`](https://github.com/yschimke/compose-preview-server) |

Both can be connected at once; their tool names do not collide. If you have the
repo, the local server is cheaper and more capable. If you have only a server
URL, or the person named a library component, use the hosted one.

### The hosted URL: `https://preview.coo.ee/mcp`, once

The public hosted server's MCP URL is **`https://preview.coo.ee/mcp`**. Configure
that one URL and nothing else.

- **`https://ui.coo.ee/mcp` is an alias of the same server process**, with the
  same tools. It is not a second service. **Never configure both**: the client
  lists every `catalog_*` and `ui_builder_*` tool twice, and because stored
  access tokens are keyed by origin, each URL needs its own approval.
- If a client already has `ui.coo.ee/mcp`, **replace** that entry with
  `preview.coo.ee/mcp` rather than adding a second one.
- Browser links on `ui.coo.ee` (the start page, a UI Builder design page) are
  web pages, not MCP configuration, and are fine to share as they are.

The `compose-catalogs` plugin from
[compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins#install)
already wires this URL. To add it by hand, per-host commands are in its
[host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md).
People new to the UI Builder start at <https://ui.coo.ee/start>.

## Troubleshooting first — when NOT to act

Before reaching for `mcp install`, killing a daemon, or restarting the host,
run:

```bash
compose-preview mcp doctor
```

The doctor names the corrective action (or "no action needed") for every
common stale state. Treat its output as authoritative; do not run
`mcp install` to "refresh" without a doctor finding that asks for it.

In particular:

- **Do not delete `build/classes/...` or `build/intermediates/...`.** Some
  agent loops have been observed reaching for `rm -rf` (or `./gradlew clean`)
  when a render looks stale. Don't. The sanctioned escape hatch is the
  `force` field on `render_preview`:
  ```json
  { "uri": "compose-preview://...", "force": { "reason": "edit to Foo.kt didn't reflect" } }
  ```
  It forwards `fileChanged({kind:"classpath"})` to every replica before
  rendering, dropping the daemon's user classloader — same effect as
  invalidating the bytecode, without touching `build/`. Every use bumps a
  `forces.used` counter and is logged. **Report each use** on
  [issue #924](https://github.com/yschimke/compose-ai-tools/issues/924)
  with the URI, reason, and the edit that didn't land — those reports are
  how the freshness logic gets fixed.
- **Do not re-run `mcp install`** to recover from a perceived hang, a stale
  render, or a dependency bump. `install` is a one-time bootstrap; the only
  conditions that warrant re-running it are the ones `mcp doctor` flags as
  `run-mcp-install` (descriptor missing, schema mismatch, launcher path
  broken, host config drifted).
- **Do not kill or restart the daemon JVM.** When the classpath changes
  (dependency bump, plugin upgrade, build script edit) the daemon detects it
  via fingerprint, emits `classpathDirty`, and exits within
  `daemon.classpathDirtyGraceMs` (default 2 s). The MCP supervisor respawns
  it automatically and clients see `notifications/resources/list_changed`.
  Manual restarts race the supervisor and produce duplicate spawns.
- **Do not kill the MCP server.** On stdin EOF it tears down every
  supervised daemon cleanly. If you killed it mid-session, the host will
  reconnect on the next tool call; you do not need to re-`install`.
- **Source edits don't need a restart either.** Call the `notify_file_changed`
  MCP tool (or just trigger a render) — the daemon's classloader-swap fast
  path picks up bytecode changes without rebooting.

## When to read this

You want any of:

- An agent that can re-render a `@Preview` on demand and **read the PNG inline**
  without spawning Gradle per call.
- **Push notifications** when a render finishes (no polling) — for a chat-style
  loop where the user edits source and the agent reacts.
- **Multi-workspace fan-out** — one MCP server serving previews from multiple
  projects, or two worktrees of the same repo at once (the bread-and-butter of
  PR review; see [`compose-preview-review/references/mcp-review.md`](../../compose-preview-review/references/mcp-review.md)).

If you just want a one-shot render or a CI diff comment, the CLI
(`compose-preview show --json`) is simpler and has the same render engine
behind it. Reach for MCP when the loop is long-lived.

## Setup

The `compose-preview` CLI bundles the local MCP server: no second download, no
manual classpath. Install the CLI first ([setup.md](./setup.md)), then, from the
project root:

```bash
compose-preview mcp install   # prepares every plugin-applied module, registers with each detected host
compose-preview mcp doctor    # verifies per-module state (descriptor present, enabled=true)
```

Use **one** registration route. The `compose-preview` plugin from
[compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins#install)
registers this server itself (and its `compose-catalogs` plugin wires the hosted
one); with it installed, don't also let `mcp install` register hosts. Two
registrations of the same server give you two copies of every tool. Which hosts
`mcp install` detects, the flags that force or skip one, and where each entry is
written are in the
[host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#registering-the-local-mcp-server).

Every host entry is global: `<stable launcher> mcp serve`, with no `--project`
(the server finds the project from the client's roots or working directory, and
defaults to the current Gradle root). The launcher is the stable absolute path,
such as `~/.local/bin/compose-preview`, never a versioned
`compose-preview-<version>/bin/` directory that the next upgrade deletes.
`compose-preview mcp register` registers hosts without touching Gradle.

If a host fails to start the server with `ENOENT` on a
`.../compose-preview-<version>/bin/compose-preview` path, or every session is
pinned to one project, run `compose-preview update` (it runs
`compose-preview mcp repair`), or `compose-preview mcp repair` directly.

Beyond host registration, `mcp install` does three things behind the scenes:

1. Runs `composePreviewDaemonStart` for every module that applies the plugin,
   so each `<module>/build/compose-previews/daemon-launch.json` exists.
2. Patches each descriptor's `enabled` flag to `true`. (The Gradle DSL knob
   `composePreview.daemon { enabled = true }` is intentionally
   not propagated via `-P`, so the on-disk patch is the canonical way to flip
   it from outside the build script.)
3. Runs `composePreviewDiscover` so `previews.json` sits alongside.

`mcp doctor` reads the descriptors back without mutating, and exits non-zero
if any module's descriptor is missing or has `enabled: false`. Use it from a
SessionStart hook, CI, or a watchdog.

`mcp install` is a one-time bootstrap: see
[Troubleshooting](#troubleshooting-first--when-not-to-act) before re-running it.

## What an attached agent sees

Once the host is wired, the agent gets a stable resource catalogue:

- Each `@Preview` becomes one resource:
  `compose-preview://<workspaceId>/<encodedModulePath>/<previewFqn>`.
- `resources/list` enumerates every preview every supervised daemon knows.
- `resources/read` triggers a render and returns the PNG inline (base64
  `image/png`).
- `resources/subscribe(uri)` pushes `notifications/resources/updated` whenever
  that one preview re-renders.
- `notifications/resources/list_changed` fires when the discovery set or the
  workspace set mutates.

Tool calls (see [`mcp/README.md` § Tool reference](https://github.com/yschimke/compose-ai-tools/blob/main/mcp/README.md#tool-reference)
for the full table) cover the rest:

- `register_project`, `unregister_project`, `list_projects` — manage
  workspaces at runtime.
- `watch(workspaceId, module?, fqnGlob?)` — area-of-interest registration.
  The supervisor expands the watch into a URI set and forwards it to the
  daemon as `setVisible` / `setFocus`, so render queue prioritisation
  matches what the agent is looking at.
- `notify_file_changed(workspaceId, path, kind?)` — tell the daemon that the
  source on disk changed. Use after editing source files outside the host's
  view (e.g. the agent invoked the Edit tool from a different process). The
  daemon's classloader-swap fast path picks up bytecode changes without a
  full reboot.
- `render_preview(uri, overrides?, observe?, crop?, force?)` — render
  bypassing the in-memory render cache. Use `overrides` to flip device,
  locale, fontScale, uiMode, orientation, or density per call without editing
  the `@Preview` annotation. `observe` (`semantics` default / `hash` /
  `png` for pixels on demand — issue #1787)
  and `crop` (one element's rectangle by `ref`/`testTag`/`role`+`text` or
  explicit pixel bounds) are the token-frugal knobs — see
  [`references/agent-loop.md`](./agent-loop.md). `force = { reason }` is the
  sanctioned escape hatch for stale renders — see the "do not delete
  `build/classes/`" note above. `inline: false` returns an absolute `pngPath`,
  dimensions, SHA-256, duration and session-scoped `changed` instead of an
  inline observation; it overrides `observe` and cannot be combined with
  `crop`. Clients that read files should pass it and read `pngPath` only when
  they need to look.
- `find_previews_for_file(path, workspaceId?)` — maps a source path to preview
  URIs. No `workspaceId` searches all workspaces; an empty array means no
  previews. Do not reconstruct a URI from a Kotlin name.
- `render_matrix`, `diff_semantics`, `record_preview` — the Playwright-style
  interaction/regression tools (matrix sweep, pixel-free semantics diff,
  record-to-Compose-UI-test). Covered in
  [`references/agent-loop.md`](./agent-loop.md).
- `history_list` / `history_diff` — proxy the daemon's history feature for
  comparing rendered output across runs.
- `list_data_products` / `get_preview_data` / `subscribe_preview_data` —
  fetch structured per-render data (a11y findings, layout tree, recomposition
  heat-map, …) alongside the PNG. See
  [`references/data-products.md`](./data-products.md) for the kind catalogue.

### Draft viewer, prompts, and fallbacks

**Requires** a compose-preview-server release after v3.74.0 containing #1126
and #1130 (viewer/resources) and #1128 (prompts, variant choice), and — for
local file lookup/path results — a `compose-preview` CLI distribution that
ships compose-preview-server#1124 after compose-ai-tools#5583's split. None is
released yet. **Until then**, treat every item in this section as absent and
use inline renders, CLI `pngPath`s and chat-listed choices. Even after release,
use only what the local `tools/list` / `prompts/list` advertises.

The viewer and action rules match the remote
[viewer contract](./catalog-mcp.md#draft-viewer-and-interactive-capability-fallbacks):
a viewer association is not a `resource_link`, fallbacks stay complete, and
model context does not prove an action ran.

On the local native profile, `preview-file` (required `path`) and
`migrate-wear-m3` (no arguments) return text instructions, not executed
workflows. The first uses `find_previews_for_file`; the second still defers API
choices to the official Wear Compose M3 skill. Without prompt discovery, follow
the same typed steps.

The only form elicitation is `render_matrix` with `choose: true`; otherwise its
labelled choices are text. Local stdio is credential-free and has no access-
grant flow; the remote URL/code fallback is documented only in
[`catalog-mcp.md`](./catalog-mcp.md#draft-viewer-and-interactive-capability-fallbacks).

## Multi-workspace and worktrees

`WorkspaceId.derive(rootProjectName, path)` is
`<rootProjectName>-<8-hex-chars-of-sha256(canonical-path)>`. The hash is
always present, so two worktrees of the same repo at different paths get
distinct ids by construction — not just distinct names.

Daemons are owned per `(workspaceId, modulePath)`. Two worktrees of the
same module run two independent daemon JVMs against their own `build/`
output. No PNG or cache cross-contamination.

For PR-review-style flows (base + head worktrees, render both, diff client-side)
see the dedicated [`compose-preview-review/references/mcp-review.md`](../../compose-preview-review/references/mcp-review.md).

## Lifecycle and operational notes

- **Cold start.** Robolectric daemon: ~5–10 s. Desktop daemon: ~600 ms.
  `watch` spawns asynchronously; the host's reader thread doesn't block.
- **One server, N clients.** A single MCP server JVM can serve N agents over
  N stdio connections. Daemons are shared across sessions when they target
  the same `(workspace, module)`, so two agents reading the same preview
  both benefit from one warm sandbox.
- **`classpathDirty`.** When a daemon's classpath fingerprint changes (e.g.
  dependency bump), it emits `classpathDirty` and exits. The supervisor
  drops the dying daemon and respawns; clients see
  `notifications/resources/list_changed`.
- **Disconnect.** On stdin EOF the server tears down every supervised daemon
  cleanly (`shutdown` + `exit`, drain wait) before exiting itself.
- **Cloud sandboxes.** The MCP server runs out of the CLI's launcher with no
  extra steps; see [`references/agent-cloud.md`](./agent-cloud.md).

## See also

- [`mcp/README.md`](https://github.com/yschimke/compose-ai-tools/blob/main/mcp/README.md)
  — full tool reference, URI scheme details, end-to-end smoke script.
- [`docs/daemon/MCP.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/daemon/MCP.md)
  — protocol-level design (subscriptions, notifications, capability
  negotiation).
- [`docs/daemon/PROTOCOL.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/daemon/PROTOCOL.md)
  — daemon JSON-RPC wire format the MCP shim translates from.
- [`compose-preview-review/references/mcp-review.md`](../../compose-preview-review/references/mcp-review.md)
  — agent-driven PR review using two MCP workspaces (base + head).

## Evidence rules (moved from SKILL.md)

- After changing Compose UI, render the affected preview and **look at the
  resulting image on the surface where the person will judge it**. Use the
  typed MCP render tool when available, or the CLI and its reported `pngPath`;
  then open that image with the host's image viewer. Source, semantics, hashes,
  and a successful build are useful checks, but none of them proves what the
  UI looks like.
- Showable evidence is part of the result. Keep the returned image or file path
  so the person can inspect the same render. If the harness cannot display the
  render, say which surface is unavailable and why; do not describe an inferred
  visual result as something you saw.
- Prefer typed MCP tools and their published input/output schemas. Use a
  dedicated validation tool when the server exposes one. Do not hand-edit
  design or render-manifest JSON as a substitute for a typed operation; if a
  required typed or validation capability is absent, name that gap plainly.
