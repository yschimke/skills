# Running a whole app: `compose-preview launch` (the APK simulator)

`compose-preview launch <app.apk>` runs an Android APK in Robolectric's simulator: a desktop
window showing the app, or, with `--control stdio`, a JSON-lines channel an agent drives. No
emulator, no device, no `adb`. The full reference (the protocol, every argument, how the dex
conversion works) is compose-ai-tools'
[`docs/SIMULATOR.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md);
this page is the agent's subset.

**Availability.** `launch` is on compose-ai-tools `main` and ships in the next CLI release after
v2.74.1; the `simulator_*` MCP tools ship in the next
[compose-preview-mcp](https://github.com/yschimke/compose-preview-mcp) release after v4.12.0.
Until then, check `compose-preview launch --help` before relying on it.

## When to use it, and when not

Reach for `launch` when the question is about the **running app**, not one composable:
navigation between screens, a flow across activities, deep links, services and broadcasts,
runtime-permission branches as the app really asks for them, foldable postures, a Wear app on a
round display, or "does this APK start at all". For one composable's look, a `@Preview` render
([SKILL.md](../SKILL.md)) is cheaper, deterministic and needs no APK.

What it cannot do (condensed from upstream's Constraints):

- **No native code** (`.so`), **no Google Play services** (Maps, billing, Wear Data Layer report
  `SERVICE_INVALID`), **no GPU content** (`SurfaceView`, `TextureView`, video, camera, GL).
- **One process, one task.** `am force-stop` / `pm clear` are partial: the `Application` and its
  singletons live on. For a truly clean start, quit and launch again.
- **No system UI**: share sheets, settings screens and other system-only intents arrive as an
  `error` event. No home screen, launcher or app widgets; on Wear no watch face, tiles carousel or
  ambient mode (a tile service is reachable only through `bindService`).
- **No bindings to other packages**; split APKs and App Bundles must be merged into one APK first.
- **Fidelity**: Robolectric's native graphics, close to a device but not pixel-identical. Stack
  traces show `Unknown Source` for app frames.
- **XR** runs in Home Space only (2D fallbacks; no `Subspace` or 3D). **Glimmer** has no touchpad
  or input focus, so focus-driven navigation does not work.

## Quick start

```sh
compose-preview launch app-debug.apk                               # a window, mouse and keyboard
compose-preview launch app-debug.apk --control stdio               # a window an agent drives
compose-preview launch app-debug.apk --control stdio --headless    # the agent, no window
compose-preview launch app-debug.apk --prepare                     # convert and cache only
```

The first launch of an APK converts its dex to JVM classes (tens of seconds, about 40 s for a
large app), cached by the APK's content; a warm launch reaches its first frame in about 7 s.
`--prepare` does the conversion ahead of time and prints the cached classes jar.

With `--control stdio` the window stays up so a person can watch: each tap is drawn as a ring,
each swipe as a trail, and the command along the bottom. That overlay is never in the agent's
screenshots. `--hide-agent` turns it off; `--headless` drops the window (the default when there is
no display, as in CI or a cloud sandbox).

Other flags: `--form-factor phone|wear|glimmer|xr`, `--device <preset>`, `--display <spec>`
(repeatable), `--qualifiers <q>`, `--font-scale <f>`, `--sdk <n>` (default 35), `--jar <path>`,
`--no-providers`, `--java <jdk>`, `--verbose`.

## Driving it over MCP

The local MCP server (`compose-preview mcp serve`; see [mcp.md](./mcp.md#apps-in-the-simulator-simulator_)) wraps
`launch --control stdio` in four tools:

| Tool | Does |
| --- | --- |
| `simulator_launch` `{apk, headless?, showAgent?, qualifiers?, fontScale?, sdk?, java?}` | starts one and waits for `ready`: a simulator id, the package, display size, first activity |
| `simulator_command` `{simulator?, cmd, …}` | one control command, arguments beside `cmd`; returns `result` plus the `events` since the last call |
| `simulator_screenshot` `{simulator?, path?}` | the display as an image; with `path`, written to disk instead of inlined |
| `simulator_stop` `{simulator?}` | ends it; every simulator also ends with the server |

`simulator` is optional while only one runs. A worked flow:

```
simulator_launch     {"apk":"/abs/path/app-debug.apk"}
simulator_command    {"cmd":"find","textContains":"settings"}
simulator_command    {"cmd":"tap","text":"Settings"}
simulator_command    {"cmd":"hierarchy","flat":true}         # what is on screen now, as text
simulator_screenshot {"path":"/tmp/settings.png"}            # then read the file
simulator_stop       {}
```

Prefer `find` / `hierarchy` (text) over screenshots to locate things; take a screenshot only to
judge how something looks. `simulator_command`'s `cmd` list covers the interaction, component,
permission and `shell` commands; the display, fold, form-factor and multi-display commands below
are not in it yet. Reach them through `shell` where an adb line exists (`wm size`, `wm density`,
`cmd uimode night yes`), or drive `launch --control stdio` directly.

## Driving it over stdio

Each stdin line is one JSON command, each stdout line one JSON object; the app's own output goes
to stderr. **Closing stdin ends the simulator**, so keep it open (a pipe or FIFO you hold, a
coprocess) and wait for the `ready` event before sending anything.

```
← {"event":"ready","info":{...}}
→ {"id":1,"cmd":"find","textContains":"now playing"}
← {"id":1,"ok":true,"result":[{...}]}
→ {"id":2,"cmd":"tap","text":"Open Now Playing"}
← {"event":"activity","state":"resumed","activity":"com.example.NowPlayingActivity",...}
← {"id":2,"ok":true,"result":{"x":183.5,"y":348,"node":{...}}}
→ {"id":3,"cmd":"screenshot","path":"/tmp/now-playing.png"}
← {"id":3,"ok":true,"result":{"width":540,"height":960,"path":"/tmp/now-playing.png"}}
→ {"id":4,"cmd":"quit"}
```

Replies are `{"id","ok":true,"result"}` or `{"id","ok":false,"error"}`; an exception the app
throws while handling a command becomes an error reply and the simulator keeps running. Events
arrive unasked: `ready`, `activity` (`resumed` / `newIntent` / `destroyed` / `empty`), `service`,
`providers`, `permissions`, `display`, `log` (while `logcat` follows), and `error` for an intent
nothing handles. Commands run in order; UI-changing ones answer after `settleMs` of simulated time
(default 250, any command takes it), so a `tap` then a `screenshot` sees the result.

**Selectors** (for `find`, `tap`, `longPress`): `text` / `desc` (exact), `textContains` /
`descContains` (case-insensitive), `resourceId` (a Compose `testTag` once the app sets
`testTagsAsResourceId`), `cls` (class-name suffix), `clickable`; plus `index` to pick among
matches. **Intents**: `{action, data, type, package, component, categories, flags, extras}`;
`component` takes `.Cls` or `pkg/cls`, `flags` names like `"CLEAR_TOP"`.

## Commands

| Family | Commands |
| --- | --- |
| Look | `screenshot` {`path`?, `display`?, `square`?}, `hierarchy` {`flat`?, `path`?}, `find` {selector}, `info`, `ping` |
| Input | `tap` {x,y \| selector}, `longPress`, `swipe` {x1,y1,x2,y2, `durationMs`?, `holdMs`?}, `key` {`BACK` / `ENTER` / code / array}, `back`, `text`, `rotary` (Wear crown), `wait` {`ms`} |
| Activities | `launch`, `finish`, `activities` (the back stack), `startActivity` {intent, `forceStop`?}, `forceStop`, `clearData` |
| Services, broadcasts | `startService` / `stopService`, `bindService` / `unbindService`, `services`, `broadcast` {intent} |
| Providers, data | `query` {uri, …}, `content` {op, uri, values?}, `settings` {op, namespace, key}, `files` {op, path}, `logcat` {op}, `getprop`, `package` / `packages`, `components` |
| Notifications | `notifications` (what the app posted) |
| Permissions | `permissions` {`policy`?: `grant`/`deny`, `grant`?, `deny`?, `reset`?} |
| adb | `shell` {`command`: an adb shell line} |
| Display, device | `qualifiers` {`+night`, `+fr-rFR`}, `resize`, `device`, `rotate`, `posture`, `fontScale`, `display`, `battery`, `location`, `timezone` |
| Displays | `displays` {`action`: list / add / remove / change} |
| End | `quit` |

**Runtime permissions** are answered with no dialog: granted by default, as a user tapping
"Allow". `{"cmd":"permissions","policy":"deny"}` refuses every later request;
`{"cmd":"permissions","deny":["android.permission.CAMERA"]}` refuses (and revokes) named ones, and
`grant` the reverse. Each request the app makes is reported as a `permissions` event. There is no
"don't ask again".

## adb equivalents

`{"cmd":"shell","command":"am start -a android.intent.action.VIEW -d https://…"}` runs the control
command an `adb shell` line means; a leading `adb [-s serial] shell` is dropped. One command per
line: pipes, `;` and `&&` are refused (a trailing `> file` on `screencap`, `uiautomator dump` and
`run-as … cat` is fine). The reply is `{command, result}`, JSON rather than adb's text.

| adb | Simulator |
| --- | --- |
| `am start` (`-a -d -n -f --es --ez --ei …`, `-S`, `--display <id>`) | `startActivity` |
| `am start-service` / `stopservice`, `am broadcast` | `startService` / `stopService`, `broadcast` |
| `am force-stop`, `pm clear` | `forceStop`, `clearData` (partial: one process) |
| `am stack list`, `dumpsys activity`, `dumpsys notification` | `activities`, `services`, `notifications` |
| `pm grant` / `revoke` / `reset-permissions` | `permissions` |
| `pm list packages` / `pm path` / `pm dump` | `packages` / `package` |
| `input tap` / `swipe` / `text` / `keyevent` / `draganddrop` (`-d <id>`) | `tap` / `swipe` / `text` / `key` / `swipe` with `holdMs` |
| `settings get` / `put` / `delete` | `settings` (`system font_scale`, `global animator_duration_scale` and a few others are applied) |
| `content query` / `insert` / `update` / `delete` | `content` |
| `cmd uimode night yes` / `no` | `qualifiers` `+night` / `+notnight` |
| `wm size` / `wm density` | `display` |
| `logcat -d -c -s -t -e` | `logcat` |
| `screencap -p [file]` (`-d <id>`), `uiautomator dump` | `screenshot`, `hierarchy` (JSON, not XML) |
| `run-as <pkg> ls` / `cat` / `rm` / `mkdir`, `adb pull` / `push` | `files` |
| `getprop`, `monkey -p <pkg> 1` | `getprop`, `launch` |

Device paths map to host directories, returned as `hostPath`: relative and `/data/data/<pkg>/…`
are the app's data dir, `/sdcard/…` its external storage. Not supported: `install` /
`uninstall`, `am instrument`, profiling, `dumpsys meminfo` / `gfxinfo`, `reboot`, `intent:` URIs,
other packages' paths.

## Form factors

`launch` reads the APK's manifest and dex for the device it targets; `--form-factor` overrides the
detection, `--qualifiers` the display.

| Form factor | Detected by | Display | Extra input |
| --- | --- | --- | --- |
| phone | anything else | `w360dp-h640dp-hdpi` | |
| wear | required `android.hardware.type.watch` feature | 454×454 round (`wearos_large_round`) | `rotary` |
| glimmer | an `xr_projected` activity, or code using `androidx.xr.glimmer` | `w960dp-h720dp-land-mdpi` glasses display | |
| xr | `android.software.xr.api.*` feature, or `androidx.xr.compose` / `scenecore` | `w1024dp-h720dp-land-mdpi` Home Space panel | |

- **Wear.** `isScreenRound()` and the `watch` UI mode read as on a watch. `screenshot` is cropped
  to the circle, transparent outside it (`"square":true` keeps the corners). `rotary`
  {`delta`? (-1 scrolls down), `count`?, `intervalMs`?} turns the crown, which is what
  `ScalingLazyColumn` / `TransformingLazyColumn` scroll on; the scroll animates, so `wait` a second
  before the screenshot. For single-screen checks, [wear-ui.md](./wear-ui.md) previews are still
  cheaper.
- **Glimmer.** The app's projected activity starts instead of its phone launcher. Cards answer
  `tap`; focus navigation does not work (no touchpad).
- **XR.** Home Space: spatial UI composes its 2D fallback (an `Orbiter` renders inline).

## Devices and folds

The emulator's extended controls. Each is a real configuration change: the top activity gets
`onConfigurationChanged` if its manifest `configChanges` covers it, and is recreated otherwise.
Each reply is the `display` object.

| Command | Arguments |
| --- | --- |
| `device` | `value`: `phone` (411×891dp), `foldable` (673×841dp, flat vertical fold), `foldable-folded`, `tablet` (1280×800dp), `desktop` (1920×1080dp); also `launch --device <preset>` |
| `resize` | `widthDp`, `heightDp`, `density`?, `posture`? |
| `rotate` | `value`?: `0` / `90` / `180` / `270`, `portrait`, `landscape` (default a quarter turn) |
| `posture` | `value`: `none`, `flat`, `half-opened`, `book`, `tabletop`; `orientation`?; `hingeDp`? (a hinge band, not a fold) |
| `fontScale` | `value` |
| `display` | none to read; `size` (`WxH` px or `reset`), `density` |
| `battery` | `level`?, `plugged`? (`ac` / `usb` / `wireless` / `none`), `powerSave`? |
| `location` | `lat`, `lng`, `accuracy`?, … (platform `LocationManager` only, not the fused provider) |
| `timezone` | `value` (`Asia/Tokyo`) |

Folds reach the app through **Jetpack WindowManager**, as on a device: `WindowInfoTracker` reports
one `FoldingFeature` across the middle of the window, so `currentWindowAdaptiveInfo()` sees the
posture (`isTabletop`) and hinges, and Material 3 adaptive scaffolds react. A typical foldable
check: `device foldable`, screenshot, `posture tabletop`, screenshot, `device foldable-folded`,
screenshot. Activity embedding and rear-display window areas report unsupported.

## Multiple displays

An app can present on a second screen, as a phone with a TV or monitor attached does.
`launch --display 1280x720@mdpi,name=TV` (repeatable; `type=` `external` / `virtual` / `rear`)
connects one before start, and `displays` manages them while running:

```
→ {"cmd":"displays","action":"add","name":"TV","widthDp":960,"heightDp":540,"density":"mdpi"}
← {"event":"display","state":"added","display":{"id":1,"name":"TV","type":"external",...}}
→ {"cmd":"startActivity","intent":{"component":".SecondActivity"},"display":1}
→ {"cmd":"tap","textContains":"play","display":1}
→ {"cmd":"screenshot","display":"all","path":"/tmp/shot.png"}   # shot.png, shot-display1.png
→ {"cmd":"displays","action":"remove","display":1}
```

The app hears `DisplayListener` callbacks; `external` and `virtual` displays are presentation
displays, so an `android.app.Presentation` draws there. Input, `hierarchy`, `find` and `finish`
take `display` (default display otherwise). An activity started on a display (by the app's
`ActivityOptions.setLaunchDisplayId`, or `startActivity` / `launch` with `display`) gets that
display's configuration; removing the display finishes its activities.

## Gotchas

- **Java 21.** The simulator JVM needs Java 21+ even though the CLI runs on 17. Pass `--java <jdk>`
  or set `COMPOSE_PREVIEW_SIMULATOR_JAVA` (for the MCP server, in its environment). It also needs
  an Android SDK platform's `android.jar`: `ANDROID_HOME`, or `local.properties` `sdk.dir`.
- **First run is slow.** The dex conversion takes tens of seconds per new APK build, and the first
  use of an SDK level downloads Robolectric's `android-all`. Run `--prepare` ahead if a timeout
  matters; later launches hit the cache.
- **Keep stdin open until `ready`.** EOF on stdin ends the simulator, so `echo '{…}' | compose-preview
  launch …` exits before the app starts. Hold the pipe open and read stdout for `ready` first.
- **Use a debug APK.** A debug build works best; that is what was tested (Now in Android's demo
  flavor, Confetti with `--sdk 36`).
- **Network** is the host's: requests go out through the host JVM, its proxy and trust store.
