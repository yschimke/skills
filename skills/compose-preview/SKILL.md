---
name: compose-preview
description: Render Compose @Preview functions to PNG outside Android Studio. Use this to verify UI changes, iterate on designs, and compare before/after states across Android (Jetpack Compose) and Compose Multiplatform Desktop projects.
---

# Compose Preview

Render `@Preview` composables to PNG images without launching Android Studio.
Works on both Android (Jetpack Compose via Robolectric) and Compose Multiplatform
Desktop (via `ImageComposeScene` + Skia).

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/compose-preview/`. The CLI, Gradle plugin, and renderer ship from
[github.com/yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools);
this skill documents how an agent drives them.

Run `compose-preview --version` to see the installed CLI bundle, `compose-preview doctor`
to compare against the latest release (warns when the local copy trails), and
`compose-preview update` to re-run the bootstrap installer.

## What this skill provides

- A Gradle plugin (`ee.schimke.composeai.preview`) that discovers `@Preview`
  annotations from compiled classes and registers rendering tasks.
- A `compose-preview` CLI that drives the Gradle build via the Tooling API
  and surfaces rendered PNG paths.
- A VS Code extension with a preview panel, CodeLens and hover actions on
  `@Preview` functions, and commands for rendering all or a single file.

## Gradle tasks

Applied to each module that declares the plugin:

| Task | Purpose |
|------|---------|
| `:<module>:composePreviewDiscover` | Scan compiled classes, emit `build/compose-previews/previews.json`. |
| `:<module>:composePreviewRenderAll` | Discover + render every `@Preview` to PNG under `build/compose-previews/`. |
| `:<module>:composePreviewDiscoverAndroidResources` | Walk `res/drawable*` + `res/mipmap*`, parse `AndroidManifest.xml`, emit `build/compose-previews/resources.json`. See [references/resource-previews.md](./references/resource-previews.md). |
| `:<module>:composePreviewRenderAndroidResources` | Render every discovered XML drawable / mipmap to PNG / GIF under `build/compose-previews/renders/resources/`. |

All Gradle-cacheable with strict configuration caching — unchanged inputs
produce no re-work.

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

Options:
  --module <name>      Target a single module (default: auto-detect)
  --variant <variant>  Android build variant (default: debug)
  --filter <pattern>   Case-insensitive substring match on preview id
  --id <exact>         Exact match on preview id
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

## Iterating on a design

`list` → edit → `show --json` → read the PNGs whose `changed: true`. Gradle
caching means re-renders only redo what changed; the `changed` flag lets
agents skip reading PNGs that didn't move. Always read the PNG after a UI
change — don't assume the change looks correct.

## Designing composables for previewability

`@Preview` only calls composables with zero arguments (or all-default), so
anything taking a `ViewModel`, repository, or DI-injected service can't be
previewed directly. Apply **state hoisting**: split each screen into a
stateful wrapper (wires runtime deps) and a stateless inner composable that
takes state + callbacks. Preview the stateless layer with hand-rolled
fixtures.

**Agent guidance:** if asked to iterate on a composable that accepts a
ViewModel or injected dependency, first propose extracting a stateless
inner composable and preview that. The one-time extraction unlocks the
fast `compose-preview` iteration loop for every future change on that
screen. See [references/state-hoisting.md](./references/state-hoisting.md) for
the pattern with code.

## Setup

The plugin is on Maven Central — most projects already have `mavenCentral()`
in their plugin repositories, so no credentials or extra registry config.

**Agents: check first, install only when missing.** Run
`compose-preview --version && compose-preview doctor` to see whether the CLI
is already available — if it is, you're done. Don't blindly re-run the
installer between previews; the script is idempotent for same-version runs
but still does network probes.

If `compose-preview` isn't on `$PATH`, this skill ships a self-bootstrapping
stub. Invoking it once downloads the real CLI and re-execs:

```sh
bash "$SKILL_DIR/scripts/compose-preview" --version
```

(replace `$SKILL_DIR` with the absolute path to this skill bundle, e.g.
`~/.claude/plugins/yschimke-skills/skills/compose-preview/` or
`~/.claude/skills/compose-preview/`). Subsequent invocations of
`compose-preview` find the installed CLI on `$PATH` and skip the
bootstrap.

To install (or upgrade) explicitly, point any consumer at the canonical
installer:

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh \
  | bash
compose-preview doctor
```

Re-running the same command upgrades to the latest release; pin a specific
version by appending it (`… | bash -s -- 0.10.8`).

`doctor` verifies Java 17+ on `PATH` (JDK 21/25 are fine — the renderer is
compiled to JDK 17 bytecode). If the install path isn't on `PATH`, the
script prints the exact command to add it.

From a Compose project root, install the MCP server descriptors:

```sh
compose-preview mcp install                  # auto-detects Antigravity
compose-preview mcp install --antigravity    # force the Antigravity config write
```

`mcp install` is a one-time bootstrap. If a render misbehaves, do **not**
re-run it and do **not** kill the daemon — run `compose-preview mcp doctor`
first and follow the verdict it prints. The supervisor respawns daemons
automatically on classpath changes. See
[references/mcp.md § Troubleshooting](./references/mcp.md#troubleshooting-first--when-not-to-act).

Apply the plugin in `<module>/build.gradle.kts` (replace the version with
the latest from
[compose-ai-tools releases](https://github.com/yschimke/compose-ai-tools/releases/latest)):

```kotlin
plugins {
    id("ee.schimke.composeai.preview") version "<latest>"
}

composePreview {
    variant.set("debug")   // Android build variant (default: "debug")
    sdkVersion.set(35)     // Robolectric SDK version (default: 35)
    enabled.set(true)      // set false to skip task registration
}
```

### Zero-Code Integration (Alternative)

You can apply the plugin dynamically without modifying the project's source code by using a Gradle init script. This is useful for agents operating in environments where they shouldn't or cannot modify the build files directly.

> **VS Code users:** the [`Compose Preview` extension](https://github.com/yschimke/compose-ai-tools/tree/main/vscode-extension) already passes a bundled init script via `--init-script` on every Gradle invocation it makes, so its renders pick up Android / Compose projects with no extra setup. The instructions below are for CLI and CI flows that go through `./gradlew` directly.

Create a file named `~/.gradle/init.d/compose-ai-tools.gradle` with the following content:

```groovy
allprojects {
    buildscript {
        repositories {
            gradlePluginPortal()
            mavenCentral()
        }
        dependencies {
            classpath "ee.schimke.composeai.preview:ee.schimke.composeai.preview.gradle.plugin:latest.release"
        }
    }

    afterEvaluate { project ->
        if (System.getenv("COMPOSE_AI_TOOLS") == "true") {
            if (project.plugins.hasPlugin("com.android.application")) {
                if (!project.plugins.hasPlugin("ee.schimke.composeai.preview")) {
                    project.pluginManager.apply("ee.schimke.composeai.preview")
                    println "Applied ee.schimke.composeai.preview to ${project.name} via init script"
                }
            }
        }
    }
}
```

To enable it, set the environment variable:
```sh
export COMPOSE_AI_TOOLS=true
```

CMP Desktop projects additionally need
`implementation(compose.components.uiToolingPreview)` — the bundled `@Preview`
annotation has `SOURCE` retention and is invisible to classpath scanning
otherwise.

The Android variant relies on Robolectric with native graphics; the plugin
takes care of the relevant test/tooling dependencies. Agents MUST NOT run
internal tasks like `collectPreviewInfo` — they're wired by the plugin itself.

## Reference docs

Loaded on demand. Read only what the current task needs.

| Path | When to read |
|---|---|
| [references/permissions.md](./references/permissions.md) | Setting up agent allowlists; staging PNGs outside `build/`. |
| [references/runtime-permissions.md](./references/runtime-permissions.md) | Pinning Android runtime permissions per render via `renderNow.overrides.permissions`; reading the `compose/permissions` data product. |
| [references/state-hoisting.md](./references/state-hoisting.md) | Full state-hoisting pattern with code examples. |
| [references/capture-modes.md](./references/capture-modes.md) | Multi-preview annotations, `@AnimatedPreview` GIFs, MCP scripted recordings, paused-clock snapshots, scrolling captures. |
| [references/a11y.md](./references/a11y.md) | ATF accessibility checks (`compose-preview a11y`). |
| [references/data-products.md](./references/data-products.md) | Structured per-render data (a11y findings + hierarchy, layout tree, recomposition heat-map, …) via MCP tools and on-disk Gradle output. |
| [references/mcp.md](./references/mcp.md) | Driving compose-preview from an MCP-aware agent host (push notifications, multi-workspace, in-process server bundled in the CLI). |
| [references/cmp-shared.md](./references/cmp-shared.md) | Compose Multiplatform `:shared` modules (`commonMain` previews via Desktop pipeline). |
| [references/resource-previews.md](./references/resource-previews.md) | Android XML resources (`<vector>`, `<animated-vector>`, `<adaptive-icon>`). |
| [references/wear-ui.md](./references/wear-ui.md) | Wear OS Material 3 Expressive design. |
| [references/wear-tiles.md](./references/wear-tiles.md) | Wear Tiles (protolayout, not Compose). |
| [references/remote-compose.md](./references/remote-compose.md) | Remote Compose dialect + `RemoteDocument`. |
| [references/agent-cloud.md](./references/agent-cloud.md) | Running compose-preview in Claude Code cloud sandboxes (allowlist, JDK, install paths). |
| [references/vscode.md](./references/vscode.md) | VS Code extension (humans, not agents). |

## Related skill

PR-review and CI workflows live in the sibling
[**compose-preview-review** skill](../compose-preview-review/SKILL.md):
authoring agent-opened PRs, reviewing UI PRs locally (base + head render,
diff, text comment), and wiring `compose-preview/main` baselines +
PR-comment GitHub Actions. The bootstrap installer
([`scripts/install.sh`](https://raw.githubusercontent.com/yschimke/compose-ai-tools/main/scripts/install.sh))
sets up both skills together.
