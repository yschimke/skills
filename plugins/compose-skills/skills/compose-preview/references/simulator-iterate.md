# Iterating on an app in the simulator: restart, update, live reload

The edit-run loop half of [simulator.md](./simulator.md): getting a change into a running
simulator without ending the session, and running the simulator as a device that adb and Android
Studio see. Upstream reference:
[Restart and update](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#restart-and-update),
[Live reload](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#live-reload)
and [As a device](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#as-a-device-adb-and-android-studio).

All of it is newer than CLI v2.75.0, and the MCP tools are newer than compose-preview-mcp v4.12.0:
check `compose-preview launch --help` and `tools/list` before relying on one.

| You have | Use | Takes |
| --- | --- | --- |
| the app's Gradle project, and an edit to its Kotlin, Java or resources | `launch --project <dir>`, then `reload` (or `--live`) | seconds for code; a cold restart for resources |
| a rebuilt APK | `update {apk}` | seconds when that APK is in the conversion cache, else only its changed classes convert |
| a need for a fresh process: statics, singletons, cold start, with the app's data | `restart` | about 4 to 6 s with `--standby`, 7 to 11 s without |
| a need for a clean install | `restart {"keepData":false}` | as `restart` |
| a tool that only talks adb (Android Studio, a test runner, a script) | `launch --adb` | |

All three keep the session, the simulator id and the client's connection. None keeps UI state:
the app comes back at its launcher activity, as after `adb install -r`.

## Iterate on an app: live reload

The loop for "edit the code, see it running". Launch from the app's Gradle build instead of an
APK, edit sources, and `reload`:

```sh
compose-preview launch --project ~/src/myapp --control stdio            # module app, variant debug
compose-preview launch --project ~/src/myapp --module mobile --variant demoDebug --control stdio
compose-preview launch --project ~/src/myapp --live --control stdio     # reload on every save
```

```
→ {"cmd":"tap","text":"Garden"}                    # get to the screen you are changing
   (edit EmptyGarden.kt, save)
→ {"cmd":"reload"}
← {"ok":true,"result":{"mode":"classes","build":{"ok":true,"ms":3400,…},"classesChanged":[…],…}}
→ {"cmd":"tap","text":"Garden"}                    # the app restarted: navigate back
→ {"cmd":"screenshot","path":"/tmp/garden.png"}
```

Over MCP:

```
simulator_launch     {"project":"/abs/path/myapp","module":"app","variant":"debug"}
   (edit, save)
simulator_reload     {}
simulator_command    {"cmd":"tap","text":"Garden"}
simulator_screenshot {"path":"/tmp/garden.png"}
```

- With no APK given, the CLI builds one first (`apk` is optional on `simulator_launch` with
  `project`). `--project` turns `--standby` on, so each reload takes over a prepared JVM.
- `reload` compiles the module through Gradle (Kotlin, KSP or kapt, and aapt2's resource link; no
  dexing or packaging), overlays the classes that changed since launch, and restarts the app on
  them with its data kept. A three-line composable edit came back in about 6 s.
- The reply's `mode` says what happened: `classes`, `resources` (a layout, string or drawable
  changed), `apk` (a rebuilt APK was needed), or `unchanged`. `build` carries `ok`, `ms`, `tasks`
  and `errors`.
- **A compile error is the command's error**, with the compiler's `e:` lines, and the running app
  is left alone. Fix and `reload` again.
- `--live` (MCP `live: true`) reloads after every edit to a module's `src/`, once edits settle
  for 400 ms; each arrives as a `reload` event. `--gradle-arg` (repeatable; MCP `gradleArgs`)
  passes build arguments such as `--max-workers=2`.
- `{"cmd":"reload","full":true}` (MCP `simulator_reload {"full":true}`) runs `assemble<Variant>`
  and `update`s to the APK. Use it for assets, native libraries, a module outside the project
  directory or in an included build, or when an overlay misbehaves.

Limits:

- **UI state is lost.** The back stack, scroll positions and anything not on disk go; the app
  starts at its launcher activity. Script the navigation back to the screen, or deep-link to it
  with `startActivity`. This is not Compose hot reload.
- **Debug, unshrunk variants only.** R8 renames classes, so a release build cannot be overlaid.
- **A resource change is a cold restart.** The standby JVM holds the old resources, so a string or
  layout edit takes about twice as long as a code edit (about 11 s against 6 s).
- **Core library desugaring.** An app that uses it must not change a class's `java.time` signatures
  against classes that did not change; `full` if in doubt.
- **`--pair`**: `reload` and `--live` are the phone's; `--project` builds the phone app.
- `--project` cannot be combined with `--adb`.

## Restart and update

`launch --control stdio` keeps the simulator JVM behind a supervisor in the CLI, so the app can be
replaced in place:

| Command | MCP | Does |
| --- | --- | --- |
| `restart` {`keepData`? (true)} | `simulator_restart {device?, keepData?}` | the app again in a fresh JVM: a new process, so statics and singletons really reset; files, databases, preferences and external storage are kept unless `keepData: false` |
| `update` {`apk`, `keepData`? (true)} | `simulator_update {apk, device?, keepData?}` | another APK, usually a rebuild, as `adb install -r`; keeping data needs the same package |
| `snapshotData` {`to`} | | copies the app's data and external storage to `to/data` and `to/external` (what `restart` keeps) |

With `"device":"watch"` in a `--pair` session, either replaces the watch's simulator instead.
Each answers with the new `info` and its timings (`snapshotMs`, `stopMs`, `startMs`, `totalMs`,
and `startup`: `jvmMs`, `sandboxMs`, `applicationMs`, `firstActivityMs`); `update` adds
`conversion` (`cached`, `ms`). Every launch also sends a `conversion` event before `ready`.

**`--standby`** (MCP `standby: true`; the default with `--project`) keeps a second JVM prepared up
to the app's own code, which the next `restart` or `reload` takes over: about 4 to 6 s instead of 7
to 11 s. It costs about 400 MB while it waits. A launch with no APK and `--adb` reject it.

Use `restart` to test cold-start behavior with existing data (a migration, a restored session, a
first-run flag in preferences), and `update` when you built the APK yourself and only want the new
code running. `forceStop` / `clearData` are only partial (one process; the `Application` lives on):
`restart` is the clean version of both.

## As a device: `--adb`

`compose-preview launch` with no APK boots the device itself: the phone's home screen, or with
`--form-factor wear` the watch face, nothing installed. `--adb` makes that a device adb and Android
Studio list, as they list an emulator:

```sh
compose-preview launch --adb                        # emulator-5554, a phone, nothing installed
compose-preview launch --adb --form-factor wear     # a watch
compose-preview launch --adb app.apk                # app.apk installed, not started

adb install app-debug.apk                           # replaces the running simulator with this app
adb shell am start -n com.example/.MainActivity
adb exec-out screencap -p > screen.png
```

`adb install` / `uninstall` (including Studio's session installs) stop the simulator and boot one
on the new package, installed but not started, with the adb connection kept. `adb shell` maps onto
the [adb equivalents](./simulator.md#adb-equivalents); Studio finds the emulator gRPC endpoint and
draws the screen in Running Devices. Use it when the tool driving the app speaks only adb. For an
agent, `--control stdio` is still the richer channel.

Limits: one app at a time (a second install replaces the first), the base APK of a split install
only, no `--pair`, second display or `--project`, no debugging (`jdwp`), no `adb reverse` /
`forward`, and no watch faces or complications. Android Studio itself is untested upstream.
