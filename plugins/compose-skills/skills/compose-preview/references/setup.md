# Setup: install, update, and apply the plugin

Moved from `SKILL.md`. Only read this when `compose-preview` or the MCP server
is actually missing — if a render tool is attached, render first.

## Install / update at a glance

- Skills + CLI (default): `npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder`,
  then `~/.agents/skills/compose-preview/scripts/compose-preview --version`.
- No Node: `curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash`.
- Update: `compose-preview update` (CLI + PATH); `npx skills update` (npx-installed skills).
- Check: `compose-preview --version && compose-preview doctor`.

## Setup

The plugin is on Maven Central — most projects already have `mavenCentral()`
in their plugin repositories, so no credentials or extra registry config.

**Agents: check first, install only when missing.** Run
`compose-preview --version && compose-preview doctor` to see whether the CLI
is already available — if it is, you're done. Don't blindly re-run the
installer between previews; the script is idempotent for same-version runs
but still does network probes.

If `compose-preview` isn't on `$PATH`, install it in this order:

1. **Run the stub bundled with this skill** (preferred — no Node needed). Its
   first run downloads the real CLI, links `~/.local/bin/compose-preview`,
   adds `~/.local/bin` to bash/zsh/fish startup files, and re-execs:

   ```sh
   bash "$SKILL_DIR/scripts/compose-preview" --version
   ```

   (`$SKILL_DIR` is the absolute path to this skill bundle, e.g.
   `~/.agents/skills/compose-preview/` or
   `~/.claude/plugins/yschimke-skills/skills/compose-preview/`.)
2. **No bundle on disk?** Install the skills with the
   [skills CLI](https://skills.sh), then run the stub:

   ```sh
   npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
   ~/.agents/skills/compose-preview/scripts/compose-preview --version
   ```
3. **No Node?** Use the canonical installer (CLI + the default skills in one
   step; `--all-skills` for every skill;
   add `-s -- --no-modify-path` to leave shell startup files alone):

   ```sh
   curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash
   ```

Then `compose-preview doctor`. A new shell picks up `~/.local/bin`. To update:
`compose-preview update` for the CLI (and PATH), `npx skills update` for
npx-installed skills; re-running the curl installer also upgrades (pin a
version with `… | bash -s -- 1.79.0`). The installer only touches shell
startup files when `~/.local/bin` isn't already on `PATH` and no startup file
mentions it; to opt out entirely, run `compose-preview update --no-modify-path`
(older CLIs: `MODIFY_PATH=0 compose-preview update`; curl installer:
`… | bash -s -- --no-modify-path`).

`doctor` verifies Java 17+ on `PATH` (JDK 21/25 are fine — the renderer is
compiled to JDK 17 bytecode). If the install path isn't on `PATH`, the
script prints the exact command to add it.

From a Compose project root, install the MCP server descriptors:

```sh
compose-preview mcp install                  # auto-detects Antigravity
compose-preview mcp install --antigravity    # force the Antigravity config write
```

On Antigravity, Claude Code or Codex, the
[`compose-ag-plugin`](https://github.com/yschimke/compose-ag-plugin#install)
plugins are an alternative to `mcp install`. `compose-preview` wires this MCP
server, and `compose-catalogs` wires the hosted catalog and UI Builder. The
install commands for each harness are in this repo's
[README](https://github.com/yschimke/skills#per-harness-plugins). Use one route
or the other, not both: two registrations of the same server give you two copies
of every tool.

`mcp install` is a one-time bootstrap. If a render misbehaves, do **not**
re-run it and do **not** kill the daemon — run `compose-preview mcp doctor`
first and follow the verdict it prints. The supervisor respawns daemons
automatically on classpath changes. See
[references/mcp.md § Troubleshooting](./mcp.md#troubleshooting-first--when-not-to-act).

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
