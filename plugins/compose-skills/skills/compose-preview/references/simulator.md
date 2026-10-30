# Running a whole app: `compose-preview launch` (the APK simulator)

`compose-preview launch <app.apk>` runs an Android APK in Robolectric's simulator: a desktop
window showing the app, or, with `--control stdio`, a JSON-lines channel an agent drives. No
emulator, no device, no `adb`. The full reference (the protocol, every argument, how the dex
conversion works) is compose-ai-tools'
[`docs/SIMULATOR.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md);
this page is the agent's subset. Two companion pages cover the larger areas:

- [simulator-wear.md](./simulator-wear.md): a Wear OS app with its watch face, tiles and
  notifications, ambient mode and screen power, a paired phone and watch, and the agent playing
  the Wearable Data Layer peer.
- [simulator-network.md](./simulator-network.md): offline, cellular, captive and VPN modes with
  the app's real traffic gated, Wi-Fi requests, and Bluetooth / BLE peripherals and GATT.
- [simulator-iterate.md](./simulator-iterate.md): the edit-run loop. `restart` and `update` in
  place, live reload from the app's Gradle project (`--project`, `reload`, `--live`), and
  `--adb`, the simulator as a device adb and Android Studio see.

**Availability.** `launch` ships in CLI v2.75.0 with the commands below, adb equivalents, form
factors, folds, multiple displays and `--pair`. The home screen (`--launcher`), the Wear system
UI, `--network` and the radios, `--data-layer agent`, Wear ambient mode, `--fingerprint`,
`--max-heap`, `--play-services`, the `ask` permission policy, `companion`, `restart` / `update` /
`--standby`, live reload (`--project`, `reload`, `--live`) and `--adb` are on compose-ai-tools
`main` and ship in the next CLI release after v2.75.0. The `simulator_*` MCP tools ship in the next
[compose-preview-mcp](https://github.com/yschimke/compose-preview-mcp) release after v4.12.0. `simulator_adb`, and `adb` / `formFactor` on `simulator_launch`, also need
the CLI release that carries the `--adb` device event (compose-ai-tools #6313).
Check `compose-preview launch --help` before relying on a flag.

## When to use it, and when not

Reach for `launch` when the question is about the **running app**, not one composable:
navigation between screens, a flow across activities, deep links, services and broadcasts,
runtime-permission branches as the app really asks for them, foldable postures, a Wear app on a
round display, or "does this APK start at all". For one composable's look, a `@Preview` render
([SKILL.md](../SKILL.md)) is cheaper, deterministic and needs no APK.

| You want to check | Launch with | Then |
| --- | --- | --- |
| a screen flow, deep link, permission branch | `--control stdio` | `tap`, `startActivity`, `permissions` (below) |
| a foldable, tablet or second display | `--device foldable`, `--display …` | `posture`, `rotate`, `displays` ([below](#devices-and-folds)) |
| app widgets, shortcuts, leaving and returning | `--launcher` (`--widget <provider>`) | `home`, `widget`, `shortcuts` ([below](#home-screen-and-widgets)) |
| the offline banner, a metered-only sync, a slow API | `--network offline` / `cellular` | `network` ([simulator-network.md](./simulator-network.md)) |
| a BLE scan, GATT exchange, Wi-Fi connect request | `--control stdio` | `bluetooth`, `wifi` ([simulator-network.md](./simulator-network.md)) |
| a Wear app's tiles, notifications, ambient UI | `--launcher`, `--tile <service>` | `tiles`, `notification`, `ambient` ([simulator-wear.md](./simulator-wear.md)) |
| phone ↔ watch sync, both apps | `phone.apk --pair wear.apk` | `"device":"watch"` ([simulator-wear.md](./simulator-wear.md#a-paired-phone-and-watch)) |
| one side of the sync, with scripted peer data | `--data-layer agent` | `dataLayer` actions ([simulator-wear.md](./simulator-wear.md#the-agent-as-the-peer)) |
| a permission's deny, rationale or "don't ask again" path | `--control stdio` | `permissions {policy:"ask"}`, then `answer` ([below](#runtime-permissions)) |
| the app's "Play services missing / outdated" path | `--play-services none` / `outdated` | `playServices` ([below](#google-play-services)) |
| a code or resource edit, running | `--project <dir>` | `reload`, or `--live` ([simulator-iterate.md](./simulator-iterate.md#iterate-on-an-app-live-reload)) |
| a cold start with existing data, a rebuilt APK | `--control stdio` | `restart`, `update` ([simulator-iterate.md](./simulator-iterate.md#restart-and-update)) |
| an adb-only tool or Android Studio against it | `--adb` | `adb install`, `adb shell` ([simulator-iterate.md](./simulator-iterate.md#as-a-device---adb)) |

What it cannot do (condensed from upstream's Constraints):

- **No native code** (`.so`), **no Google Play services APIs** beyond the Wearable Data Layer.
  Play services is reported installed ([below](#google-play-services)), but Maps, billing and the
  fused location provider report `API_UNAVAILABLE`; the Data Layer is simulated only under `--pair`
  or `--data-layer agent`. **No GPU content** (`SurfaceView`, `TextureView`, video, camera, GL).
- **One process, one task.** `am force-stop` / `pm clear` are partial: the `Application` and its
  singletons live on. For a truly clean start, `restart` (with `"keepData":false` for a clean
  install; [simulator-iterate.md](./simulator-iterate.md#restart-and-update)).
- **Little system UI**: share sheets and other system-only intents arrive as an `error` event;
  the Wi-Fi and Bluetooth dialogs and settings panels are answered for you. A home screen and
  widgets exist only with `--launcher`; on Wear, the face is a demo face (no Watch Face Format, no
  complications).
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
compose-preview launch app-debug.apk --launcher                    # over a home screen, with widgets
compose-preview launch app-debug.apk --network offline             # start with no network
compose-preview launch phone.apk --pair wear.apk --control stdio   # a phone and its watch, paired
compose-preview launch wear.apk --data-layer agent --control stdio # the agent plays the phone
compose-preview launch --project ~/src/myapp --live --control stdio # build, then reload on save
compose-preview launch --adb                                       # a device adb and Studio see
```

The first launch of an APK converts its dex to JVM classes (tens of seconds, about 40 s for a
large app), cached by the APK's content; a warm launch reaches its first frame in about 7 s.
A rebuild of the same APK path reconverts only the classes that changed. `--prepare` does the
conversion ahead of time and prints the cached classes jar.

With `--control stdio` the window stays up so a person can watch: each tap is drawn as a ring,
each swipe as a trail, and the command along the bottom. That overlay is never in the agent's
screenshots. `--hide-agent` turns it off; `--headless` drops the window (the default when there is
no display, as in CI or a cloud sandbox).

Other flags: `--form-factor phone|wear|glimmer|xr`, `--device <preset>`, `--display <spec>`
(repeatable), `--qualifiers <q>`, `--font-scale <f>`, `--sdk <n>` (default 35), `--jar <path>`,
`--no-providers`, `--java <jdk>`, `--verbose`; and, newer: `--network <mode>[,airplane]`,
`--launcher`, `--widget <provider>`, `--tile <service>`, `--pair <wear.apk>`,
`--pair-qualifiers <q>`, `--data-layer agent`, `--fingerprint <f>` (replaces `Build.FINGERPRINT`'s
`robolectric`, which some apps check to skip real work), `--max-heap <size>` (each simulator
JVM's `-Xmx`, e.g. `1g`), `--play-services <state>`, `--standby`, `--adb`, and `--project <dir>`
with `--module`, `--variant`, `--live`, `--gradle-arg` ([simulator-iterate.md](./simulator-iterate.md)).

## Driving it over MCP

The local MCP server (`compose-preview mcp serve`; see [mcp.md](./mcp.md#apps-in-the-simulator-simulator_)) wraps
`launch --control stdio` in nine tools:

| Tool | Does |
| --- | --- |
| `simulator_launch` `{apk, headless?, showAgent?, qualifiers?, fontScale?, sdk?, java?, network?, dataLayer?, fingerprint?, playServices?, pair?, pairQualifiers?, standby?, project?, module?, variant?, live?, gradleArgs?, adb?, formFactor?}` | starts one and waits for `ready`: a simulator id, the package, display size, first activity; with `adb`, the `device` (serial, ports) too |
| `simulator_command` `{simulator?, device?, cmd, …}` | one control command, arguments beside `cmd`; returns `result` plus the `events` since the last call |
| `simulator_screenshot` `{simulator?, device?, path?}` | the display as an image; with `path`, written to disk instead of inlined |
| `simulator_logs` `{simulator?, device?, contains?, lines?}` | the latest lines it logged (the app's logcat, Robolectric, stack traces), plus the events since the last call |
| `simulator_restart` `{simulator?, device?, keepData?}`, `simulator_update` `{apk, device?, keepData?}` | the app in a fresh JVM, its data kept ([simulator-iterate.md](./simulator-iterate.md#restart-and-update)) |
| `simulator_reload` `{simulator?, full?, keepData?}` | with `project`: compile the edit and restart on the changed classes ([simulator-iterate.md](./simulator-iterate.md#iterate-on-an-app-live-reload)) |
| `simulator_adb` `{simulator?, args \| command, output?, timeoutMs?}` | with `adb`: runs the SDK's `adb -s <serial>` against it; `exitCode`, `stdout` (or bytes written to `output`), `stderr`, events ([simulator-iterate.md](./simulator-iterate.md#over-mcp-simulator_adb)) |
| `simulator_stop` `{simulator?}` | ends it; every simulator also ends with the server |

`network` takes the same value as `--network` (`"offline"`, `"cellular,airplane"`),
`"dataLayer":"agent"` makes you the app's Data Layer peer, and `pair` (a Wear APK) runs a paired
phone and watch under one id: `device: "watch"` addresses the watch, and `simulator_logs` with
`device` keeps one side's lines. `simulator` is optional while only one runs. A worked flow:

```
simulator_launch     {"apk":"/abs/path/app-debug.apk"}
simulator_command    {"cmd":"find","textContains":"settings"}
simulator_command    {"cmd":"tap","text":"Settings"}
simulator_command    {"cmd":"hierarchy","flat":true}         # what is on screen now, as text
simulator_command    {"cmd":"network","mode":"offline"}      # does the app show its offline state?
simulator_screenshot {"path":"/tmp/settings.png"}            # then read the file
simulator_stop       {}
```

Prefer `find` / `hierarchy` (text) over screenshots to locate things; take a screenshot only to
judge how something looks. `simulator_command`'s `cmd` list covers the interaction, component,
permission, `shell`, `display`, `network` / `wifi` / `bluetooth`, `dataLayer` and screen-power
(`screen`, `ambient`, `tilt`, `wake`, `palm`, `sleep`), `companion` and `playServices`
commands. Not in it yet: `rotary`, the fold and device commands (`device`, `resize`, `rotate`,
`posture`, `fontScale`, `displays`, `battery`, `location`, `timezone`), the home-screen and Wear
system UI commands, and the `--launcher`, `--device`, `--display` and `--max-heap` launch
options. Reach them
through `shell` where an adb line exists (`wm size`, `wm density`, `cmd uimode night yes`,
`input keyevent KEYCODE_POWER`), or drive `launch --control stdio` directly.

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
arrive unasked: `ready`, `activity` (`resumed` / `newIntent` / `destroyed` / `stopped` /
`empty`), `service`, `providers`, `permissions`, `notification`, `display`, `log` (while
`logcat` follows), `error` for an intent nothing handles, and the newer `screen`, `datalayer`,
`wifiRequest`, `bluetoothRequest`, `bleScan`, `gatt`, `systemUi`, `companion`, `conversion`,
`reload` (with `--live`), and with `--launcher` `home`,
`widget`, `shortcut` (phone) or `surface`, `tile` (watch). Commands run in order; UI-changing
ones answer after `settleMs` of simulated time (default 250, any command takes it), so a `tap`
then a `screenshot` sees the result.

**Selectors** (for `find`, `tap`, `longPress`): `text` / `desc` (exact), `textContains` /
`descContains` (case-insensitive), `resourceId` (a Compose `testTag` once the app sets
`testTagsAsResourceId`), `cls` (class-name suffix), `clickable`; plus `index` to pick among
matches. **Intents**: `{action, data, type, package, component, categories, flags, extras}`;
`component` takes `.Cls` or `pkg/cls`, `flags` names like `"CLEAR_TOP"`.

## Commands

| Family | Commands |
| --- | --- |
| Look | `screenshot` {`path`?, `display`?, `square`?}, `hierarchy` {`flat`?, `path`?}, `find` {selector}, `info`, `ping` |
| Input | `tap` {x,y \| selector}, `longPress`, `swipe` {x1,y1,x2,y2, `durationMs`?, `holdMs`?}, `key` {`BACK` / `ENTER` / `POWER` / code / array}, `back` (reply `via`: below), `text`, `rotary` (Wear crown), `wait` {`ms`} |
| Activities | `launch`, `finish`, `activities` (the back stack), `startActivity` {intent, `forceStop`?}, `forceStop`, `clearData` |
| Services, broadcasts | `startService` / `stopService`, `bindService` / `unbindService`, `services`, `broadcast` {intent} |
| Providers, data | `query` {uri, …}, `content` {op, uri, values?}, `settings` {op, namespace, key}, `files` {op, path}, `logcat` {op}, `getprop`, `package` / `packages`, `components` |
| Notifications | `notifications` (what the app posted), `notification` {key, op: tap / action / reply / dismiss / snooze} |
| Permissions | `permissions` {`policy`?: `grant`/`deny`/`ask`, `grant`?, `deny`?, `answer`?, `requestId`?, `reset`?} ([below](#runtime-permissions)) |
| Companion devices | `companion` {`policy`?: `accept`/`reject`/`ask`, `answer`?, `requestId`?, `address`?, `disassociate`?} ([simulator-wear.md](./simulator-wear.md#companion-devices)) |
| Play services | `playServices` {`state`?: `installed`/`none`/`outdated`/`disabled`/`invalid`} ([below](#google-play-services)) |
| Restart, reload | `restart` {`keepData`?}, `update` {`apk`, `keepData`?}, `reload` {`full`?, `keepData`?}, `snapshotData` {`to`} ([simulator-iterate.md](./simulator-iterate.md)) |
| adb | `shell` {`command`: an adb shell line} |
| Display, device | `qualifiers` {`+night`, `+fr-rFR`}, `resize`, `device`, `rotate`, `posture`, `fontScale`, `display`, `battery`, `location`, `timezone` |
| Displays | `displays` {`action`: list / add / remove / change} |
| Network, radios | `network` {mode, wifi, data, airplane, latencyMs, kbps, block, …}, `wifi` {op}, `bluetooth` {op}: [simulator-network.md](./simulator-network.md) |
| Screen power | `screen` {state}, `ambient`, `tilt` / `wake`, `palm` / `sleep`: [simulator-wear.md](./simulator-wear.md#ambient-mode-and-screen-power) |
| Data Layer | `dataLayer` {action, …} with `--pair` or `--data-layer agent`: [simulator-wear.md](./simulator-wear.md) |
| Home screen (`--launcher`) | `home`, `drawer`, `shortcuts`, `shortcut`, `widgets`, `widget` {action}, `picker` |
| Wear system UI (`--launcher`) | `home`, `launcher`, `notifications` {op}, `ongoing`, `tiles` {op}, `health`, `quickSettings` |
| End | `quit` |

**Back** goes where a device sends it. A window that opted in to the callback API
(`android:enableOnBackInvokedCallback`, API 33+) gets its `OnBackInvokedCallback` (Compose's
`BackHandler`, Navigation, Wear's `SwipeDismissableNavHost`), so one Back pops one screen; any
other window gets `KEYCODE_BACK`. The `back` reply's `via` says which: `key`,
`OnBackInvokedCallback`, `Activity.onBackPressed` or `system`. The predictive back gesture is not
simulated: use `back`, not an edge swipe, on an opted-in window.

### Runtime permissions

Requests are answered with no dialog on screen, the way a device's permission controller answers
them. What a device decides without a dialog is decided the same way, and named in each result's
`by`: `alreadyGranted`, `notInManifest`, `installTime`, `groupGranted`, `dontAskAgain`, or
`ignored` for a permission the platform drops (newer than the simulated SDK, fine location without
coarse, background location before foreground). The Android XR tracking permissions and
`ACCESS_LOCAL_NETWORK` (Android 17) are runtime permissions, asked about like any other. The rest
are the dialog's (`by: dialog`), answered by the policy:

- `grant` (the default) or `deny`: every dialog answered at once. `grant` / `deny` with names set
  per-permission answers and apply now (a deny revokes).
- `ask`: the request waits, as a `permissions` event `{state:"waiting", requestId, ask:[…]}`,
  until `permissions` with `answer`: `grant`, `deny`, `dismiss` (backed out, not counted),
  `approximate` (coarse location only), `selected` (Android 14+ partial photo access), or an
  object of permission → answer.

```
→ {"cmd":"permissions","policy":"ask"}
→ {"cmd":"tap","text":"Find nearby"}
← {"event":"permissions","state":"waiting","requestId":3,"ask":["android.permission.ACCESS_FINE_LOCATION","android.permission.ACCESS_COARSE_LOCATION"],…}
→ {"cmd":"permissions","answer":"approximate"}
← {"event":"permissions","state":"answered","requestId":3,"granted":["android.permission.ACCESS_COARSE_LOCATION"],"denied":["android.permission.ACCESS_FINE_LOCATION"],…}
```

Denials count as on a device: after one dialog deny `shouldShowRequestPermissionRationale` is
true (test the rationale UI); after two the permission is denied without asking ("don't ask
again", `dontAskAgain: true`) until `grant` (as from Settings) or `reset`. Every request ends with
a `permissions` event, `state: "answered"`, with `granted`, `denied` and per permission `by`,
`rationale` and `dontAskAgain`. `permissions` with no arguments returns the policy, waiting
requests and each permission's state. The requesting activity is not paused while a request
waits.

### Google Play services

The device reports Google Play services installed, so `isGooglePlayServicesAvailable` is
`SUCCESS` and an app takes its Play-services path. Only availability is simulated: every API but
the Wearable Data Layer (under `--pair` / `--data-layer agent`) fails with `API_UNAVAILABLE`. To
test the app's error paths, `launch --play-services none|outdated|disabled|invalid` (MCP
`playServices`), or while it runs `{"cmd":"playServices","state":"outdated"}`: every check then
reports `SERVICE_MISSING`, `SERVICE_VERSION_UPDATE_REQUIRED`, `SERVICE_DISABLED` or
`SERVICE_INVALID`, `getErrorDialog` builds Play services' own dialog, and the package broadcast a
device sends goes out. An app that cached an earlier answer keeps it.

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
| `input keyevent KEYCODE_POWER` | `key POWER` (sleep / wake the screen) |
| `settings get` / `put` / `delete` | `settings` (`global airplane_mode_on` / `wifi_on` / `mobile_data` / `bluetooth_on`, `system font_scale`, `global animator_duration_scale` and a few others are applied) |
| `svc wifi` / `svc data`, `cmd connectivity airplane-mode`, `cmd netpolicy set restrict-background` | `network` |
| `cmd wifi status` / `start-scan` / `list-scan-results` / `connect-network`, `svc bluetooth enable` / `disable` | `wifi`, `bluetooth` |
| `dumpsys connectivity` / `wifi` / `bluetooth_manager` | `network` / `wifi` / `bluetooth` |
| `content query` / `insert` / `update` / `delete` | `content` |
| `cmd uimode night yes` / `no` | `qualifiers` `+night` / `+notnight` |
| `wm size` / `wm density` | `display` |
| `logcat -d -c -s -t -e` | `logcat` |
| `screencap -p [file]` (`-d <id>`), `uiautomator dump` | `screenshot`, `hierarchy` (JSON, not XML) |
| `run-as <pkg> ls` / `cat` / `rm` / `mkdir`, `adb pull` / `push` | `files` |
| `getprop`, `monkey -p <pkg> 1` | `getprop`, `launch` |

Device paths map to host directories, returned as `hostPath`: relative and `/data/data/<pkg>/…`
are the app's data dir, `/sdcard/…` its external storage. Not supported: `install` /
`uninstall`, `am instrument`, profiling, `dumpsys meminfo` / `gfxinfo`, `svc power` / `nfc` /
`usb`, `reboot`, `intent:` URIs, other packages' paths.

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
  before the screenshot. The watch face, tiles, notifications, ambient mode and the Data Layer are
  on [simulator-wear.md](./simulator-wear.md). For single-screen checks,
  [wear-ui.md](./wear-ui.md) previews are still cheaper.
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

## Home screen and widgets

`launch --launcher` puts a home screen under a phone app, so the app can be left and returned to,
and its **app widgets** and **shortcuts** exercised the way a launcher does. Use it to check a
widget's sizes, updates and taps, or the app's behavior across `onStop` / `onRestart`, with no
emulator. `--widget <provider>` (repeatable; implies `--launcher`) starts with one placed. Upstream:
[Home screen and widgets](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#home-screen-and-widgets).

```
→ {"cmd":"home"}                                                    # app stops; the grid shows
→ {"cmd":"widget","action":"add","provider":"TaskListWidgetReceiver"}
← {"event":"widget","state":"configuring","widgetId":1,…}           # its configure activity runs
→ {"cmd":"tap","textContains":"work"}
← {"event":"widget","state":"configured","widgetId":1,"spanX":3,"spanY":3,…}
→ {"cmd":"tap","textContains":"Work task 2"}                        # a row in the widget
← {"event":"widget","state":"updated","widgetId":1,"partial":true,"reason":"click",…}
→ {"cmd":"widget","action":"resize","widgetId":1,"spanX":4,"spanY":4}
→ {"cmd":"launch"}                                                  # the icon: the task comes back
```

- Adding a widget binds it, sends `APPWIDGET_ENABLED` / `APPWIDGET_UPDATE` to the app's receiver
  (Glance's included), runs a configure activity if there is one, and sends the size options, so
  a responsive `RemoteViews(Map<SizeF, RemoteViews>)` picks its layout. Each redraw is a `widget`
  `updated` event with a best-guess `reason` (`click`, `options`, `app`, …).
- Widget taps, Glance `actionRunCallback`s and collection rows (`RemoteViewsService` or
  `RemoteCollectionItems`) are delivered as the system delivers them.
- `shortcuts` lists static, dynamic and pinned shortcuts; `shortcut {shortcutId}` opens one.
  `requestPinAppWidget` shows a sheet answered by `widget {action:"pin", answer:"accept"}`.
- Home-screen views carry `sim:id/…` resource ids (`icon`, `widget`, `pin_accept`, …), and a
  widget's own views appear under its `widget` node, so `find` and `tap` reach both.

Limits: the app's own widgets only (one package), no notification shade, wallpaper or keyguard,
no drag between cells (`widget add` takes `cellX` / `cellY`), and the default display only. On a
Wear app, `--launcher` gives the watch's system UI instead: see
[simulator-wear.md](./simulator-wear.md#the-watch-face-tiles-and-notifications).

## Gotchas

- **Java 21.** The simulator JVM needs Java 21+ even though the CLI runs on 17. Pass `--java <jdk>`
  or set `COMPOSE_PREVIEW_SIMULATOR_JAVA` (for the MCP server, in its environment). It also needs
  an Android SDK platform's `android.jar`: `ANDROID_HOME`, or `local.properties` `sdk.dir`.
- **First run is slow.** The dex conversion takes tens of seconds per new APK, and the first use
  of an SDK level downloads Robolectric's `android-all` (about 200 MB), provisioned before the
  simulator starts so parallel launches share one download. Run `--prepare` ahead if a timeout
  matters. A rebuilt APK at the same path reconverts only the classes that changed. The cache
  is pruned to eight APKs or 2 GB, least recently used first, never one a running simulator uses.
- **Memory.** Each simulator JVM's heap is an eighth of the machine, between 768 MB and 2 GB;
  `--pair` runs two, and `--standby` a third. `--max-heap` overrides it: `1g` suits a phone app,
  `768m` a watch. The conversion itself fits in about 1 GB.
- **Keep stdin open until `ready`.** EOF on stdin ends the simulator, so `echo '{…}' | compose-preview
  launch …` exits before the app starts. Hold the pipe open and read stdout for `ready` first.
- **Use a debug APK.** A debug build works best; that is what was tested (Now in Android's demo
  flavor, Confetti with `--sdk 36`). R8-minified APKs defeat the Data Layer simulation.
- **The app skips real work under Robolectric?** Some apps check `Build.FINGERPRINT ==
  "robolectric"` and show canned preview data; pass `--fingerprint <a device fingerprint>`.
- **Network** is the host's when online: requests go out through the host JVM, its proxy and trust
  store. The simulated network decides whether they may, and how fast
  ([simulator-network.md](./simulator-network.md)).
