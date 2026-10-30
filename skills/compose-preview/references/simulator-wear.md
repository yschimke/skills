# Wear OS in the simulator: system UI, ambient mode and the Data Layer

The Wear half of [simulator.md](./simulator.md). A Wear APK (a required
`android.hardware.type.watch` feature) launches on a 454×454 round display with the crown as
`rotary`; this page covers what goes around the app. Upstream reference:
[Wear system UI](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#wear-system-ui),
[Screen power and ambient mode](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#screen-power-and-ambient-mode),
[A paired phone and watch](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#a-paired-phone-and-watch),
and the design doc
[`SIMULATOR_DATALAYER.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/design/SIMULATOR_DATALAYER.md).

Everything here except `--pair` is newer than CLI v2.75.0: check `compose-preview launch --help`.
Over MCP, `simulator_launch` takes `dataLayer: "agent"` and `fingerprint`, and `simulator_command`
takes `dataLayer`, `screen`, `ambient`, `tilt`, `wake`, `palm` and `sleep`; the system UI
commands, `rotary` and `--pair` need `launch --control stdio` directly.

| You want to check | Use |
| --- | --- |
| a screen of the app | a [wear-ui.md](./wear-ui.md) preview render (cheaper) |
| navigation, the crown, the whole app | `launch wear.apk --control stdio`, `rotary` |
| tiles, Wear Widgets, notifications, ongoing activities | `--launcher` / `--tile <service>` |
| the app's ambient UI, or that it pauses when the screen sleeps | `ambient`, `palm`, `tilt` |
| phone ↔ watch sync with both real apps | `phone.apk --pair wear.apk` |
| one app's sync against scripted peer data or errors | `--data-layer agent` |

## The watch face, tiles and notifications

`--launcher` on a Wear app (or any `--tile <service>`, repeatable) puts a Wear OS system UI under
it: a demo watch face at the bottom of the back stack, with the launcher, notification stream,
tiles carousel and quick settings around it. Leaving the app stops it and coming back restarts
it, as on a watch; `info` reports the `surface` (`watchface`, `launcher`, `notifications`,
`tiles`, `quickSettings`, `app`).

| On a watch | Command |
| --- | --- |
| Home, back from the app's root | `home`, `key HOME` |
| the side button: the launcher | `key STEM_PRIMARY`, `launcher` {`label`? / `component`? / `index`?} |
| swipe up: the notification stream | `notifications {op:"open"}` |
| swipe left / right: the tiles carousel | `tiles {op:"next" / "prev" / "show"}` |
| swipe down: quick settings | `quickSettings` {`airplane`?, `wifi`?} |

```
→ {"cmd":"tiles","op":"add","component":".tile.WorkoutTileService"}
→ {"cmd":"health","heartRate":142,"steps":5400}        # tiles and widgets redraw with it
→ {"cmd":"screenshot","path":"/tmp/tile.png"}
→ {"cmd":"notification","key":"7","op":"reply","text":"On my way"}
```

Tiles are bound and rendered with the protolayout renderer (a `LoadAction` re-requests the tile, a
`LaunchAction` starts its activity); Wear Widgets (Glance Wear) share one carousel page. `health`
sets the Health Services values tiles and widgets read. Notifications are drawn from their extras
as Wear draws them (actions, `WearableExtender`, inline-reply choices), and `notification` {`key`,
`op`: `tap` / `action` / `reply` / `dismiss` / `snooze`} acts on one; `notifications` without
`op` also says when a watch would hide one (`hiddenBecause`: a blocked channel,
`POST_NOTIFICATIONS` denied). `ongoing` lists and taps `androidx.wear.ongoing` activities. System
views carry `sim:id/…` resource ids (`tile`, `notification_card`, `launcher_item`, …), so `find`
and `tap` reach them too.

Limits: no Watch Face Format or `WatchFaceService` faces, no complications;
`TileUpdateRequester` is not wired (use `tiles {op:"refresh"}`); widgets draw at their large
container size only.

## Ambient mode and screen power

The screen is `on`, `ambient` (a watch's always-on doze) or `off`. Each change sets
`PowerManager.isInteractive()` and `Display.getState()`, broadcasts `SCREEN_OFF` / `SCREEN_ON`,
and arrives as a `screen` event. Use it to check an app's ambient layout, or that a non-ambient
app pauses and resumes properly. Works with or without `--launcher`.

- **An ambient-aware app** stays resumed and gets `onEnterAmbient` (with `burnIn` / `lowBit`),
  `onUpdateAmbient` once a simulated minute (or on `ambient {op:"update"}`) and `onExitAmbient`:
  androidx.wear `AmbientLifecycleObserver`, the legacy `AmbientModeSupport`, Horologist
  `AmbientAware`, and Wear Compose `rememberAmbientModeManager()`.
- **Any other app** is paused and stopped, and restarts on wake. **Off**, everything stops and
  screenshots are black.

| Command | Does |
| --- | --- |
| `screen` {`state`?: `on` / `ambient` / `off`, `timeoutMs`?, `alwaysOn`?, `burnIn`?, `lowBit`?} | without arguments, the state, including each ambient activity the app registered; `timeoutMs` sleeps after idle; `alwaysOn:false` makes a sleep go off |
| `ambient` {`value`?, `op`?: `update`} | Wear only: enter (`true`) or leave (`false`) ambient, toggles without `value` |
| `palm` / `sleep` | ambient on an always-on watch, off otherwise |
| `tilt` / `wake` | wake; `tilt` first fires `TYPE_WRIST_TILT_GESTURE` to its listeners |
| `key` `POWER` / `SLEEP` / `WAKEUP` | the power button; `input keyevent KEYCODE_POWER` through `shell` |

```
→ {"cmd":"screen","burnIn":true,"lowBit":true}   # details the next onEnterAmbient reports
→ {"cmd":"palm"}
← {"event":"screen","state":"ambient",…}
→ {"cmd":"screenshot","path":"/tmp/ambient.png"} # the app's ambient UI
→ {"cmd":"tilt"}
```

While the screen sleeps, the first `tap`, `swipe`, `rotary` or `key` only wakes it (the reply says
`consumed`), as on a watch. Nothing enforces ambient on the drawing: no dimming, burn-in shift or
frame-rate cap, so judge the app's own ambient UI from the screenshot.

## A paired phone and watch

`compose-preview launch phone.apk --pair wear.apk --control stdio` runs the watch in a second
simulator (`--pair-qualifiers` for its display) and joins the two over a simulated Wearable Data
Layer. `DataClient`, `MessageClient`, `NodeClient` and `CapabilityClient` answer from the
simulator instead of Play services, so data items, messages, requests and capabilities reach the
other app's listeners and manifest `WearableListenerService`s.

- A command with `"device":"watch"` goes to the watch; without, to the phone. Every output line
  carries its `device`, and each crossing is a `datalayer` event naming the path, size and who it
  was `deliveredTo`.
- `{"cmd":"dataLayer"}` reports the node, its peers, their capabilities and every data item.
  `{"cmd":"dataLayer","addCapability":"horologist_phone"}` (or `removeCapability`) changes this
  node's capabilities as if its `android_wear_capabilities` declared it: the way to unblock a
  peer that looks for a capability the app forgot to declare.
- Remote interactions work both ways: `RemoteActivityHelper.startRemoteActivity` opens the
  activity on the other device (on an API 34+ watch too); Horologist's `DataLayerAppHelper`
  (`isAvailable()`, `connectedNodes()`, `startRemoteOwnApp`, `installOnNode`, `startCompanion`)
  works; on the watch `RemoteAuthClient` (answered on the phone with
  `{"cmd":"dataLayer","oauthResponse":"<redirect URL>"}`), `BridgingManager` and
  `PhoneTypeHelper` work. A remote "start own app" brings the running task forward rather than
  stacking a second activity.
- The paired phone has a simulated Pixel Watch companion app, so `startCompanion` opens it and
  Horologist's Install Tile prompt opens its tile editor.
- Data items behave as Play services syncs them: a `put` with unchanged contents is reported
  `unchanged` and not re-sent, and an empty item stays empty.
- The watch gets a `TIME_TICK` every minute, so `TimeText` and other clocks move.
  `Build.DEVICE` / `Build.MODEL` name the node (`watch-sim`) rather than `robolectric`.
- `--max-heap 2g` caps each of the two JVMs.

Not simulated: `ChannelClient` (`API_UNAVAILABLE`), the deprecated `GoogleApiClient` APIs, and
R8-minified APKs (the shadow matches the `Wearable` class by name). A watch launched without
`--pair` still has the Wear OS app's services, so `BridgingManager` binds and `RemoteAuthClient`
answers `ERROR_PHONE_UNAVAILABLE`.

## The agent as the peer

`launch app.apk --data-layer agent --control stdio` (MCP: `simulator_launch {"dataLayer":"agent"}`)
simulates the Data Layer for **one** app, phone or watch, with the agent playing every peer. It is
cheaper than `--pair`, needs only one APK, and lets you script what the other side says,
including errors and timeouts.

What the app sends arrives as a `datalayer` event of kind `send`: `type` `hello`, `message` (a
`requestId` when it is a `sendRequest`), `response`, `data`, `capabilities`, `activity` (a
`startRemoteActivity`) or `oauth`, with the bytes as base64 `data`, a `text` preview, a decoded
`dataMap` when the bytes are a `DataMap`, and a data item's `assets` (base64). That is the form
`put` takes, so a captured item can be replayed as it was. Answer with `{"cmd":"dataLayer",
"action":…}`:

| `action` | Arguments | The peer… |
| --- | --- | --- |
| `connect` | `node`?, `name`?, `package`?, `capabilities`?, `nearby`? | joins (`getConnectedNodes`, capability listeners) and receives the app's data items |
| `disconnect` | `node`? | leaves |
| `capabilities` | `node`?, `capabilities` | changes what it advertises |
| `put` / `delete` | `node`?, `path`, payload, `assets`? | writes or deletes a data item |
| `message` / `request` | `node`?, `path`, payload | sends a message, or a request the app answers (a `send` of type `response`) |
| `reply` | `requestId`, payload or `error`; `result` (remote activity); `responseUrl` (OAuth) | answers the app's request |
| `config` | `requestTimeoutMs` | how long the app's requests wait (default 30 s, then `TIMEOUT`) |

A payload is `text`, `data` (base64) or `dataMap` (JSON: strings, booleans and ints bare, others
`{"type":"long"|"float"|"double"|"bytes"|"string[]"|"stringList"|…,"value":…}`). `node` defaults to
the only connected peer; with none, the app's `sendMessage` / `sendRequest` fail with
`TARGET_NODE_NOT_CONNECTED`, which is how to test the "phone not reachable" state.

```
→ {"cmd":"dataLayer","action":"connect","capabilities":["horologist_phone"]}
← {"event":"datalayer","kind":"send","type":"message","path":"/WearGrpcService/…","requestId":3,…}
→ {"cmd":"dataLayer","action":"reply","requestId":3,"error":"unavailable"}   # the error path
→ {"cmd":"dataLayer","action":"put","path":"/wear/settings","dataMap":{"theme":"dark"}}
→ {"cmd":"screenshot","path":"/tmp/watch-synced.png"}
```

**`--fingerprint`.** Some apps check `Build.FINGERPRINT == "robolectric"` (Robolectric's value) to
show canned preview data and never touch the Data Layer. If the app sends nothing, launch again
with `--fingerprint <a device fingerprint>`.
