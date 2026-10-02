# CLI and Gradle tasks

Moved from `SKILL.md`. **Agents with the MCP server attached should render with
`render_preview` instead** (see the core loop in [SKILL.md](../SKILL.md)); the CLI
is for shells without MCP, scripting, and CI. Never run `./gradlew`, `clean`, or
delete `build/` to chase a stale render — use `--force=<reason>` once.

## What ships

- A Gradle plugin (`ee.schimke.composeai.preview`) that discovers `@Preview`
  annotations from compiled classes and registers rendering tasks.
- A `compose-preview` CLI that drives the Gradle build via the Tooling API
  and surfaces rendered PNG paths (`--version`, `doctor`, `update`).
- A VS Code extension (see [vscode.md](./vscode.md)).

## CLI

The CLI auto-detects the Gradle project root (walks up for `gradlew`) and, by
default, every module that has the plugin applied.

```
compose-preview <command> [options]

Commands:
  show     Discover + render previews; print id, path, sha256, changed flag
  list     List discovered previews
  render   Render previews; with --output copies a single match to disk
  a11y     Render previews and print ATF accessibility findings
  extensions run a11y-annotated-preview.render
           One-shot a11y hierarchy + ATF + annotated overlay render
  doctor   Verify Java 17+ + project compatibility (run before Setup)
  rc       Remote Compose JSON codec, offline (compile | dump | header).
           `rc dump <doc.rc>` makes a captured .rc readable and diffable;
           `rc compile <doc.json>` builds one from AndroidX's authoring
           JSON. The two dialects are NOT inverses — see
           references/remote-compose.md before assuming a round trip.

Options:
  --module <name>      Target a single module (default: auto-detect)
  --variant <variant>  Android build variant (default: debug)
  --filter <pattern>   Case-insensitive substring match on preview id.
                       Narrows what Gradle renders, not just what prints
  --id <exact>         Exact match on preview id. Also narrows the render
  --json               Emit JSON (show, list)
  --output <path>      Copy matched preview PNG to this path (render)
  --progress           Print per-task milestone/heartbeat lines to stderr
  --verbose, -v        Full Gradle build output (implies --progress)
  --timeout <seconds>  Gradle build timeout (default: 300)
  --force=<reason>     Sanctioned escape hatch for stale renders: passes
                       --rerun-tasks to Gradle. Does NOT run :clean and
                       does NOT touch build/classes/. Logs the reason and
                       points at issue #924 — please report.
```

OSC 9;4 terminal progress (native taskbar/tab progress bar) is on by default
in a TTY and auto-disables when stdout is piped. Textual progress lines are
opt-in via `--progress`.

Exit codes: `0` success, `1` build failure, `2` render failure, `3` no previews.

`--json` output per entry includes the full `PreviewParams` (device, widthDp,
heightDp, fontScale, uiMode, …), the absolute `pngPath`, the `sha256` of
the PNG bytes, and a `changed` boolean computed against the previous
invocation. State is persisted per-module under
`<module>/build/compose-previews/.cli-state.json` and gets wiped by
`./gradlew clean`.

### The `counts` block, and what "no PNG" means

`show --json` wraps the rows in a versioned envelope whose `counts` block
summarises the run, so an agent can decide what to read without walking every
entry:

```json
"counts": { "total": 37, "changed": 1, "unchanged": 33, "missing": 1, "skipped": 2 }
```

The four buckets **partition** `total` — every preview is in exactly one, and
`changed + unchanged + missing + skipped == total`. What each one means:

| Bucket | Meaning |
|--------|---------|
| `changed` | At least one capture's `sha256` differs from the previous run. These are the PNGs worth reading. |
| `unchanged` | Rendered, and pixel-identical to last time. |
| `missing` | **No PNG, and that is a render failure** — the set `--missing-renders` gates on. Worth investigating. |
| `skipped` | No PNG, and the miss is *expected*: every absent capture is declared `optional`, or the preview is a kind that never emits a PNG (an `@XrSubspacePreview` composite). Not a failure. |

The same distinction shows up in the text output's per-row tags, so don't read
a bare `[no PNG]` off every empty row:

```
MainActivity (activity__MainActivity) [no PNG]
RedirectUriReceiverActivity (activity__RedirectUriReceiverActivity) [no PNG, optional]
SpatialPanelPreview (p.SpatialPanelPreview) [no PNG, by design]
```

Only `[no PNG]` is a failure, and it marks exactly the previews the
"Render task completed but produced no PNG for N of M preview(s)" summary
enumerates underneath. A `[no PNG, optional]` row is a best-effort capture that
was never guaranteed to render — a non-launcher activity that needs intent
extras discovery can't guess, a desktop `@ColorCatalog` sheet — so treat it as
information, not as something to fix. Per capture, the `optional` boolean on
each entry in `captures[]` carries the same fact in the JSON.

`skipped` and the qualified tags arrived together; a CLI bundle predating them
tags every empty row `[no PNG]` and emits no `skipped` key, and its buckets do
not add up to `total`. Check `compose-preview --version` before relying on a
residual computed from `counts`.

## Iterating on a design

`list` → edit → `show --json` → view the PNGs whose `changed: true`. Gradle
caching means re-renders only redo what changed; the `changed` flag lets
agents skip opening PNGs that did not move. Always view the PNG after a UI
change on the surface where the person will judge it. If that surface is not
available to the current harness, say so explicitly; do not assume the change
looks correct.

### Render only the preview you're iterating on

`--filter` / `--id` narrow **what Gradle renders**, not just what gets
printed. Asking for one preview used to render the whole module — measured at
317s against 3s on the CLI's own 64-preview sample — so this is the flag to
reach for when working on a single screen, rather than `--force` or deleting
`renders/` by hand.

```sh
compose-preview show --json --filter HomeScreen
```

What a narrowed run does to everything else:

- **Previews outside the request keep whatever PNG the previous run left on
  disk**; on a clean tree they simply have none. `show` scopes its counts to
  the request for that reason, so don't read a smaller total as previews
  having disappeared.
- **Change detection is unaffected.** A narrowed run carries the skipped
  previews' shas forward, so a later full render doesn't report them all as
  `changed`.
- **A filtered render is deliberately not build-cacheable**, so it can't
  poison a clean checkout — and because the filter is a task input, an
  unfiltered run afterwards re-renders everything.
- **`render --bundle` still renders the full module by design.** A bundle
  omits previews that have no PNG, so a narrowed bundle would ship exactly
  the one preview you asked for and nothing else.

For a long-lived **interaction** loop — clicking/typing by semantic ref
(not pixels), checking "did it change?" without reading a PNG, and diffing
semantics instead of pixels — see the Playwright-style, token-frugal
[references/agent-loop.md](./agent-loop.md).

### Don't spell render filenames by hand — read them from the manifest

A rendered file is named `<readable>-<digest>.<ext>`:

```
renders/ActivityListPreview_Devices_Large_Round-4f9c2a17.png
        └──────────── readable ──────────────┘ └ digest ┘
```

`<readable>` is the function name plus any `@Preview(name = …)` variant, with
non-alphanumeric runs collapsed to `_`. `<digest>` is 8 hex characters derived
from the preview id. It is what makes the name unique and stable: adding or
renaming any *other* preview never renames this one, and two previews can never
land on the same file — including on case-insensitive filesystems, and including
names that differ only in punctuation.

The practical consequence: **you cannot reconstruct a filename from a preview
id, and you shouldn't try.** Read `renderOutput` off the preview in
`previews.json` (or the `show --json` output), which is authoritative. Structural
suffixes are appended after the digest — `…-4f9c2a17_SCROLL_top.png`,
`…-4f9c2a17_PARAM_4.png` — so a glob on the readable prefix also works when you
just need "every capture of this preview".

Preview **ids** are unaffected and keep their full FQN
(`com.example.PreviewsKt.HomeScreenPreview`) — `--filter` / `--id`, history
folders and CLI state all still key by id.

## Vector (SVG) output, not just PNGs

The renderer can export a preview as **scalable vector art** as well as a
raster: `compose/semantics-wireframe` (a schematic structural wireframe) and
`compose/figma-svg` (a **layered, editable** design-fidelity SVG — each
composable a named `<g id>` layer, with real fills/strokes, editable text, and
token bindings). Reach for these when the target scales to arbitrary sizes or
must land as named layers in a design tool rather than flat pixels — they are
what the design-catalog/Figma skills import as crisp vectors. See
[references/data-products.md § SVG vector output](./data-products.md).

## Gradle tasks

Applied to each module that declares the plugin:

| Task | Purpose |
|------|---------|
| `:<module>:composePreviewDiscover` | Scan compiled classes, emit `build/compose-previews/previews.json`. |
| `:<module>:composePreviewRenderAll` | Discover + render every `@Preview` to PNG under `build/compose-previews/`. |
| `:<module>:composePreviewDiscoverAndroidResources` | Walk `res/drawable*` + `res/mipmap*`, parse `AndroidManifest.xml`, emit `build/compose-previews/resources.json`. See [references/resource-previews.md](./resource-previews.md). |
| `:<module>:composePreviewRenderAndroidResources` | Render every discovered XML drawable / mipmap to PNG / GIF under `build/compose-previews/renders/resources/`. |

All Gradle-cacheable with strict configuration caching — unchanged inputs
produce no re-work.

## Running other Gradle builds (use build-brief)

`compose-preview` is the right tool for **rendering previews** — prefer it
whenever the goal is to see a composable. For any **other** Gradle work an
agent needs to run directly (`build`, `assemble`, `test`,
`connectedCheck`, a custom task), reach for
[build-brief](https://github.com/static-var/build-brief) (`bb`) instead of
raw `./gradlew`. It wraps `gradle`/`./gradlew`, preserves the exit code,
keeps the full raw log on disk, and trims terminal output to failed
tasks/tests, warnings, build-scan URLs, and final status — typically a
90%+ token reduction on noisy builds.

```sh
# Install once (Linux/macOS); self-contained Go binary, no JDK of its own.
curl -fsSL https://bb.staticvar.dev/install.sh | bash

build-brief test
build-brief ./gradlew assembleDebug
build-brief gradle build
```

Guidance for agents: **prefer `compose-preview` for previews**; use
`build-brief` whenever you'd otherwise invoke Gradle directly so the build
output stays cheap to read. See
[references/agent-cloud.md](./agent-cloud.md) for the cloud
install/allowlist details.
