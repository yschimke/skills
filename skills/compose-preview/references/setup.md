# Setup: install, update, and apply the plugin

The one install reference for the `compose-preview` CLI and these skills.
People setting up for the first time: **start at <https://yschimke.github.io/compose-ai-tools/>**.
Agents: only read this when `compose-preview` is actually missing; if a render
tool is attached, render first.

## Check first

```sh
compose-preview --version && compose-preview doctor
```

If that works you're done. Don't re-run an installer between previews: it is
idempotent for same-version runs but still does network probes. `doctor`
verifies Java 17+ on `PATH` (JDK 21/25 are fine; the renderer is compiled to
JDK 17 bytecode) and prints the exact command to fix `PATH` if needed.

## Install

Take the first route that applies:

1. **The skill is on disk, the CLI isn't.** Run the stub bundled with this
   skill. Its first run downloads the real CLI, links
   `~/.local/bin/compose-preview`, adds `~/.local/bin` to bash/zsh/fish startup
   files, and re-execs into the CLI. Open a new shell afterwards.

   ```sh
   bash "$SKILL_DIR/scripts/compose-preview" --version
   ```

   `$SKILL_DIR` is this skill's directory, e.g. `~/.agents/skills/compose-preview/`.
   Where each agent host keeps installed skills is in the
   [host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#skill-install-locations).
2. **Nothing installed (default).** Install the skill content with the
   [skills CLI](https://skills.sh), into `~/.agents/skills/` with per-agent
   links, then run the stub:

   ```sh
   npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
   ~/.agents/skills/compose-preview/scripts/compose-preview --version
   ```
3. **No Node.** The canonical installer puts the CLI and the same two default
   skills (with per-host links for Claude Code and Codex under
   `~/.agents/skills/`) in place in one step:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash
   ```

A **plugin marketplace** (Claude Code, Codex, Gemini, …) is the alternative to
all three: [compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins#install)
installs these skills plus the MCP servers and host wiring, and its stub
downloads the CLI on first use. Pick one route per host; two give you every
skill twice.

### Which skills

The default is two skills: `compose-preview` (render, inspect, CLI and MCP) and
`compose-ui-builder` (author designs over MCP). Every installed skill's
description loads into each agent session, so the rest are opt-in:
`compose-preview-review`, `compose-preview-ci`, `compose-preview-design-board`,
`compose-design-catalog`, `figma-catalog-import`, `design-parity-review`.

- skills CLI: add another `--skill <name>`, or drop the `--skill` flags to
  pick from the list.
- installer: `… | bash -s -- --skills compose-preview-review,compose-preview-ci`,
  or `--all-skills` for every skill.

### Installer options

Pass these after `bash -s --` (for example `… | bash -s -- --no-modify-path`).
The full list, including the override environment variables, is in the header
of [`scripts/install.sh`](https://github.com/yschimke/skills/blob/main/scripts/install.sh).

| Option | Effect |
| --- | --- |
| `1.79.0` (a bare version) | Pin a CLI version instead of the latest release. |
| `--skills a,b` / `--all-skills` | Add skills to the default pair / install every skill. |
| `--cli-only` | Skip skill content (already on disk via a plugin or npx); the stub passes this. |
| `--with-skills` | Refresh skill content even when another tool installed it. |
| `--cli-home DIR` | Unpack the CLI under `DIR` (also `COMPOSE_PREVIEW_HOME`). |
| `--no-modify-path` | Leave shell startup files alone (also `MODIFY_PATH=0`). |
| `--android-sdk`, `--jdk 17,21` | Also provision an Android SDK / JDKs; see [agent-cloud.md](./agent-cloud.md#generic-setup-script-cloud-bootstrap). |

The installer adds `~/.local/bin` to shell startup files only when it isn't
already on `PATH` and no startup file already mentions it.

## Update

- CLI (and `PATH`): `compose-preview update`. `compose-preview update
  --no-modify-path` leaves startup files alone; older CLIs whose `update`
  doesn't accept the flag take `MODIFY_PATH=0 compose-preview update`.
- npx-installed skills: `npx skills update`.
- Re-running the curl installer also upgrades.

## MCP

The CLI bundles the local MCP server. Registering it with your agent host
(`compose-preview mcp install`), troubleshooting it (`compose-preview mcp
doctor` first, never re-install or kill the daemon to "refresh"), and the
**hosted** catalog server's single URL are all in [mcp.md](./mcp.md).

## Apply the Gradle plugin

The plugin is on Maven Central; most projects already have `mavenCentral()`
in their plugin repositories, so no credentials or extra registry config.
The full human-facing configuration reference is the
[compose-ai-tools site](https://yschimke.github.io/compose-ai-tools/).

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

`sdkVersion` auto-detects from `android.compileSdk` when unset, but the render
range is narrower than the compile range: **SDK > 35 requires JDK 21+**. On a
project that compiles against a newer SDK (37 is current for the Android
samples) the build fails at configuration time with
`sdkVersion = N is outside the supported range`. Pin it explicitly, or run the
build on JDK 21+.

### Zero-Code Integration (Alternative)

You can apply the plugin dynamically without modifying the project's source code by using a Gradle init script. This is useful for agents operating in environments where they shouldn't or cannot modify the build files directly.

> **VS Code users:** the [`Compose Preview` extension](https://github.com/yschimke/compose-preview-vscode) already passes a bundled init script via `--init-script` on every Gradle invocation it makes, so its renders pick up Android / Compose projects with no extra setup. The instructions below are for CLI and CI flows that go through `./gradlew` directly.

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
