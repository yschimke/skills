# Network, Wi-Fi and Bluetooth in the simulator

The radios half of [simulator.md](./simulator.md): what the app sees from `ConnectivityManager`,
`WifiManager` and the Bluetooth adapter, and what happens to its real traffic. Upstream
reference:
[Network, Wi-Fi and Bluetooth](https://github.com/yschimke/compose-ai-tools/blob/main/docs/SIMULATOR.md#network-wi-fi-and-bluetooth).
Newer than CLI v2.75.0: check `compose-preview launch --help` for `--network`. Over MCP,
`simulator_launch` takes `network` and `simulator_command` takes `network`, `wifi` and
`bluetooth` with the same arguments.

| You want to check | Use |
| --- | --- |
| the offline banner, retry and cached-data paths | `--network offline`, or `network {mode:"offline"}` mid-flow |
| sync that waits for unmetered (WorkManager `UNMETERED`) | `network {mode:"cellular"}`, then `{mode:"wifi"}` |
| a captive portal, a VPN, airplane mode | `mode: captive` / `vpn`, `airplane: true` |
| loading states on a slow or flaky API | `network {latencyMs, kbps}`, `block` a host |
| a `WifiNetworkSpecifier` connect, suggestions | `wifi {op:"request"}` and the `wifiRequest` event |
| BLE scanning, a GATT peripheral, the enable dialog | `bluetooth {op:"advertise"}`, `gatt` events, `bluetooth {op:"request"}` |

## Networks and real traffic

`launch --network wifi|cellular|ethernet|vpn|captive|offline` (append `,airplane`, or just
`airplane`) starts in a mode; the default is validated Wi-Fi. `network` changes it while the app
runs and returns the state:

```
→ {"cmd":"network","mode":"offline"}
→ {"cmd":"screenshot","path":"/tmp/offline.png"}              # the app's offline state
→ {"cmd":"network","mode":"cellular","cellular":"3g"}         # metered, slow
→ {"cmd":"network","mode":"wifi","latencyMs":2000,"block":["api.example.com"]}
→ {"cmd":"network","airplane":true}
```

| Mode | The app sees |
| --- | --- |
| `wifi` | Wi-Fi, `VALIDATED`, unmetered |
| `cellular` | metered cellular (`cellular`: `5g` / `lte` / `3g` / `2g` sets the data network type); needs mobile `data` on and airplane off |
| `ethernet` | unmetered Ethernet, which survives airplane mode |
| `vpn` | a VPN over Wi-Fi |
| `captive` | Wi-Fi behind a captive portal: never `VALIDATED`, no internet |
| `offline` | no active network |

Callbacks fire as on a device: `registerNetworkCallback`, `registerDefaultNetworkCallback` and
`requestNetwork` get `onAvailable` / `onCapabilitiesChanged` / `onLost`, `CONNECTIVITY_ACTION` is
sent, and WorkManager constraints follow. Other knobs: `wifi`, `data`, `airplane` (the switches,
mirrored in `Settings.Global`), `metered`, `downKbps` / `upKbps`, `dataSaver`.

**Real traffic is gated.** Offline or captive, the app's connections fail as on a device
(`UnknownHostException` for a host name, `ENETUNREACH` for an address) and open connections are
cut. Online, `latencyMs` delays connects and responses, `kbps` caps throughput, and `block`
refuses hosts (`api.x.com`, `*.ads.net`). This covers OkHttp, `HttpURLConnection` and Ktor's OkHttp
and Android engines; NIO clients (Ktor CIO, `java.net.http.HttpClient`) see only the DNS failure.
The reply's `traffic` counts what was `refused` and `cut`. Online, requests really go out through
the host's network.

## Wi-Fi

`WifiManager` reports the radio, the associated access point (SSID `AndroidWifi` unless you
connect another) and scan results. `wifi` {`op`}: `status`; `scan` with `networks`
(`[{ssid, rssi?, security?}]`) puts access points in range; `connect` / `disconnect` an `ssid`.

The app's requests that a device answers with a system dialog are answered for you:

- A `requestNetwork` with a `WifiNetworkSpecifier` arrives as a `wifiRequest` event and is
  accepted by default. `{"cmd":"wifi","op":"request","policy":"reject"}` (or `"ask"` to hold
  requests, then `answer` with a `requestId`) tests the other branches.
- `addNetworkSuggestions` is a `wifiSuggestions` event.
- Settings screens and panels (`ACTION_WIFI`, `Settings.Panel.ACTION_INTERNET_CONNECTIVITY`,
  `BLUETOOTH_SETTINGS`, …) are a `systemUi` event, closed with `RESULT_CANCELED`.

## Bluetooth and BLE

The adapter is on unless airplane mode or `bluetooth {op:"disable"}` turned it off.
`ACTION_REQUEST_ENABLE` is a `bluetoothRequest` event, accepted by default (`bluetooth
{op:"request", policy|answer}` as for Wi-Fi). Nothing is in range until you put it there:

- `bluetooth {op:"advertise", address, name?, serviceUuids?, serviceData?, manufacturerData?,
  rssi?}` puts a BLE peripheral on air; each matching `BluetoothLeScanner` scan gets a real
  `ScanRecord`, now or when it starts later (`bleScan` event).
- `found` answers classic discovery; `bond` / `unbond` change `getBondedDevices()`; `remove` takes
  a device out of range.
- With a `gatt` spec the peripheral is a GATT server you play: the app's `connectGatt`,
  `discoverServices`, reads, writes and subscriptions work, and its writes arrive as `gatt`
  events. Push values with `bluetooth {op:"notify", address, characteristic, value}`, or drop the
  link with `disconnect`.

```
→ {"cmd":"bluetooth","op":"advertise","address":"AA:BB:CC:DD:EE:01","name":"HR Strap",
   "serviceUuids":["180d"],"gatt":{"services":[{"uuid":"180d","characteristics":[
   {"uuid":"2a37","properties":["read","notify"],"value":"0048"}]}]}}
→ {"cmd":"tap","textContains":"Scan"}
→ {"cmd":"tap","text":"HR Strap"}
← {"event":"gatt",…}                                            # the app subscribed
→ {"cmd":"bluetooth","op":"notify","address":"AA:BB:CC:DD:EE:01","characteristic":"2a37","value":"0050"}
```

Bytes are hex (`"0a1b"`), `{"text":…}`, `{"base64":…}` or a number array. A `connectGatt` to a
device not in range fails with status 133, as a device times out.

Not simulated: classic sockets (RFCOMM), audio profiles, the app advertising or hosting a GATT
server itself, `CompanionDeviceManager.associate`, Wi-Fi-to-cellular fallback, roaming.

## adb equivalents

Through `shell` (see [simulator.md § adb equivalents](./simulator.md#adb-equivalents)):
`svc wifi enable|disable`, `svc data enable|disable`, `cmd connectivity airplane-mode enable`,
`cmd netpolicy set restrict-background true`, `settings put global airplane_mode_on 1` →
`network`; `cmd wifi status|start-scan|list-scan-results|connect-network <ssid> …` → `wifi`;
`svc bluetooth enable|disable` → `bluetooth`; `dumpsys connectivity|wifi|bluetooth_manager` →
their state as JSON.
