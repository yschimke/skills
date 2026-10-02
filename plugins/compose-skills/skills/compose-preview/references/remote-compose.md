# Remote Compose

Remote Compose is a Compose dialect that compiles your `@Composable` tree into
a portable **RemoteDocument** byte stream — a serialisable description of the
UI that a remote player (a watch face, tile, widget, or another surface that
can't host a full Compose runtime) replays at display time. Same `@Composable`
authoring model, but the output is a document, not an Android view tree.

Two things that matter for anyone writing previews against it:

- **Different applier.** Remote Compose uses its own applier that emits into a
  RemoteDocument capture buffer, not into Android's layout/draw tree. A plain
  `Text("hello")` from `androidx.compose.material` won't work inside a Remote
  Compose tree — you need the remote-aware equivalents (`RemoteText`,
  `RemoteBox`, `RemoteButton`, …). Mixing the two inside a single capture
  produces a document with gaps.
- **Different target marker.** Remote-aware composables are annotated with
  `@RemoteComposable` (a `@ComposableTargetMarker`) instead of the usual
  `@UiComposable`. The Compose compiler uses target markers to flag "wrong
  dialect" usage at compile time, so the compiler — not runtime — tells you
  when you reach for a UI composable inside a remote subtree.

## Library layout

The group is `androidx.compose.remote` (plus the Wear add-on
`androidx.wear.compose.remote`). For previews the interesting pieces are:

| Purpose | Artifact |
| :--- | :--- |
| **Authoring primitives** (`RemoteBox`, `RemoteModifier`, state like `RemoteString`/`RemoteColor`, the `.rs`/`.rdp`/`.rb`/`.rf` conversion helpers, `HostAction`) | `androidx.compose.remote:remote-creation-compose` |
| **Core creation runtime** (capture buffer, profiles) | `androidx.compose.remote:remote-creation` |
| **Preview tooling** (`RemotePreview`, `RemotePreviewWrapper`) | `androidx.compose.remote:remote-tooling-preview` |
| **Wear Material 3 remote components** (`RemoteButton`, `RemoteText`, `RemoteButtonDefaults`, `buttonSizeModifier`, …) | `androidx.wear.compose.remote:remote-material3` |

`remote-material3` builds on top of `remote-creation-compose` — it gives you
Material 3 components that emit remote layout/draw commands, so you get M3
styling inside a RemoteDocument without reinventing button colours, shapes,
and typography. Same role `compose-material3` plays for a normal app.

### Dependency wiring

`remote-tooling-preview`'s POM declares its creation deps at **`runtime`**
scope, so a project that only lists it on `implementation` won't see the
creation types on its compile classpath. Add them explicitly:

```kotlin
dependencies {
    implementation("androidx.compose.remote:remote-tooling-preview:…")
    implementation("androidx.compose.remote:remote-creation:…")
    implementation("androidx.compose.remote:remote-creation-compose:…")
    implementation("androidx.wear.compose.remote:remote-material3:…")

    // Use the same version as the ee.schimke.composeai.preview Gradle plugin.
    // debugImplementation is enough when Remote Compose is only used by previews.
    debugImplementation("ee.schimke.composeai:data-remotecompose-connector:<compose-preview-version>")
}
```

The connector is not just an editor/override add-on. It substitutes
`RemotePreviewWrapper` with the recorder-aware wrapper that emits the encoded
`<render-stem>.rc` document beside the PNG, and declares that wrapper structural
so a catalog `themeProvider` nests around it instead of replacing its Remote
Compose applier. If a project publishes executable preview bundles or expects
recorded documents, keep this dependency on the preview runtime classpath.

Most Remote Compose APIs are `@RestrictTo(LIBRARY_GROUP)`. You'll get lint
failures (`RestrictedApi`) and IDE red squigglies without either
`@file:Suppress("RestrictedApiAndroidX")` at the top of each file *and* a
`lint { disable += "RestrictedApi" }` block in the module's `build.gradle.kts`.

## Previewing: same pixels, different export behavior

### 1. `RemotePreview` wrapper inside a `@Preview` composable

```kotlin
@Preview(showBackground = true, widthDp = 200, heightDp = 200)
@Composable
fun RemoteButtonEnabledPreview() {
    RemotePreview(profile = RcPlatformProfiles.ANDROIDX) {
        Container { RemoteButtonEnabled() }
    }
}
```

`RemotePreview` captures the inner `@RemoteComposable` tree into a
RemoteDocument, then plays it back into the regular Compose preview surface.
This is the shape used in `wear/compose/remote/remote-material3/samples` in
AOSP and works on any Android Studio that can render `@Preview` — no
dependency on the newer `PreviewWrapper` annotation.

This in-body shape creates a document in memory for playback, but
compose-preview does **not** record that document as a `.rc` sidecar. The same
applies to the newer spelling `RemoteContentPreview { … }`. Rendering a PNG is
not evidence that an encoded document was exported.

### 2. `@PreviewWrapper(RemotePreviewWrapper::class)`

```kotlin
@Preview(showBackground = true, widthDp = 200, heightDp = 200)
@PreviewWrapper(RemotePreviewWrapper::class)
@Composable
fun RemoteButtonWithBorderPreview() {
    Container { RemoteButtonWithBorder() }
}
```

Tooling applies `RemotePreviewWrapper.Wrap { … }` around the function body, so
the preview function itself only contains remote content. `PreviewWrapper`
landed in `androidx.compose.ui:ui-tooling-preview` 1.11.0-beta+ — older
Compose releases don't ship the annotation class, so this shape is newer than
approach 1.

With `data-remotecompose-connector` on the preview runtime classpath, this is
the compose-preview **recording** path: it emits a non-empty `.rc` sidecar,
preserves the Remote applier under theme overrides, and enables Remote Compose
document replay/editing in bundles. Do not replace this annotation with an
in-body `RemoteContentPreview` merely to cure `Invalid applier`; that keeps the
pixels but silently drops the recorded document. Fix the missing connector or
structural-wrapper handling instead.

`RemotePreviewWrapper` itself lives in `remote-tooling-preview`:

```kotlin
class RemotePreviewWrapper : PreviewWrapperProvider {
    @Composable
    override fun Wrap(content: @Composable () -> Unit) {
        RemotePreview(profile = RcPlatformProfiles.ANDROIDX, content = content)
    }
}
```

> [!NOTE]
> If your `remote-tooling-preview` alpha predates the published
> `RemotePreviewWrapper` class, drop a local copy into the sample module —
> signature is identical, swap to the upstream one once it ships.

Both approaches can render the same pixels. Pick approach 1 for IDE-only pixel
previews that need different profiles or framing per case. Pick approach 2 plus
the connector whenever compose-preview must export/replay the encoded document.

After rendering, verify the recording rather than inferring it from the PNG:

```sh
find <module>/build/compose-previews/renders -name '<PreviewStem>*.rc' -size +0
```

## Component previews, not device previews

Remote Compose components don't care about device chrome (bezel, status bar,
system time) — they're rendered by a host surface that owns those details.
Size previews by the component's own footprint, not by a device:

```kotlin
@Preview(showBackground = true, widthDp = 200, heightDp = 200)
```

Skip `@WearPreviewDevices` / `@PreviewScreenSizes` here. A 200×200 canvas
frames a single `RemoteButton` cleanly; stretch when you add components that
need more room, or split into multiple previews rather than packing a whole
screen.

Give the remote tree a centered container so the component isn't jammed into
the top-left corner of the canvas:

```kotlin
@Composable
@RemoteComposable
fun Container(content: @Composable @RemoteComposable () -> Unit) {
    RemoteBox(
        modifier = RemoteModifier.fillMaxSize(),
        contentAlignment = RemoteAlignment.Center,
        content = content,
    )
}
```

## Reference sample

A working end-to-end example lives in [`samples/remotecompose/`](https://github.com/yschimke/compose-ai-tools/tree/main/samples/remotecompose):

- `RemoteComponents.kt` — three `@RemoteComposable` button variants + the
  `Container` helper.
- `Previews.kt` — both preview shapes side by side.
- `RemotePreviewWrapper.kt` — local copy of the wrapper until the upstream
  alpha catches up.
- `build.gradle.kts` — explicit dependency wiring, `lint { disable +=
  "RestrictedApi" }`, and a note on why this module doesn't use the Compose
  BOM (Remote Compose alphas pull in a newer Compose runtime than the BOM
  currently pins).

`./gradlew :samples:remotecompose:composePreviewRenderAll` produces PNGs for both
shapes, so you can see that the capture-and-replay path works end-to-end in
the plugin's renderer.

## The JSON format: two dialects, not one

AndroidX also defines a **JSON** representation of a Remote Compose document, described by
`compose/remote/Documentation/parts/remote_compose_schema.json` and `parts/json-parser.md` in the
AndroidX tree. Before reaching for it, know that "the RemoteCompose JSON format" names two different
things, that they are not inverses, and that conflating them is where every mistake in this area
starts.

| | **Authoring JSON** | **Document JSON** |
| :--- | :--- | :--- |
| What it is | a source language | a projection of a compiled document |
| Who reads it | AndroidX's `RemoteComposeJsonParser` | you, `diff`, `jq` |
| Names things as | `"bg"`, `"fillMaxSize"`, `"@w / 2.0"` | `ColorConstant`, `WidthModifierOperation` |
| Specified by | AndroidX's `remote_compose_schema.json` | compose-preview, and nothing parses it back |

```
authoring JSON  --compile-->  .rc (binary)  --dump-->  document JSON
                                   ^
                       also written by a real render
                       capturing a @RemoteComposable preview
```

One way. Dumping a compiled document does **not** give you back the JSON that produced it:
compiling collapses names to integer ids, expands `fillMaxSize` into a `WidthModifierOperation`
carrying a NaN-encoded marker, and flattens the ordered modifier list into the operation stream.
That is what compilation is, not a gap someone will close.

**Upstream ships the authoring direction only.** There is no official `.rc` → JSON writer in any
AndroidX artifact; the document dialect is compose-preview's, and it is produced by walking the
document through AndroidX's own `androidx.compose.remote.core.serialize.Serializable` hook rather
than by re-reading the wire format.

### Authoring a document as JSON

The schema's only required key is `root`. A minimal document:

```json
{
  "header": { "width": 300, "height": 300, "contentDescription": "Hello" },
  "resources": { "colors": [ { "name": "bg", "value": "#FF102030" } ] },
  "root": [
    { "column": {
        "modifiers": [ "fillMaxSize", { "background": "@colors.bg" }, { "padding": 12.0 } ],
        "horizontalAlignment": "center",
        "verticalAlignment": "center",
        "children": [
          { "text": { "value": "Hello RC JSON", "fontSize": 24.0, "color": "#FFFFFFFF" } }
        ] } }
  ]
}
```

Components may be written either as `{ "column": { … } }` (the shorthand the docs recommend) or as
`{ "type": "column", … }`. Modifiers are an **ordered** array — `.background().padding()` and
`.padding().background()` are the same set and different pixels — and simple sizing modifiers may
be bare strings (`"fillMaxWidth"`). Expressions are infix strings referring to variables with `@`
(`"@w / 2.0"`). Helper objects — modifiers, shapes, click actions — always use the explicit
`"type"` key even where components do not.

**The trap worth knowing before you write one.** `RemoteComposeJsonParser` accepts `{}` and returns
a valid, playable, 17-byte header-only document. So does a *generation-library entry*, which wraps
the real document under a `json` key beside its prose metadata. Nothing downstream complains: the
bytes are a real document, a bundle packs them, a player replays them, and the preview renders
blank. `compose-preview rc compile` refuses a document with no `root` for exactly this reason —
if you are calling the parser directly, check for `root` yourself.

Also: **compiling is not rendering.** The parser runs on a platform whose text measurement and path
parsing are stubs, so a document whose layout depends on measured text compiles cleanly and still
has to be measured by a real player before its bounds mean anything.

### `compose-preview rc`

```
compose-preview rc compile <doc.json> -o <doc.rc>   authoring JSON -> binary document
compose-preview rc dump <doc.rc> [--compact]        binary document -> document JSON
compose-preview rc dump <dir>                       every .rc under <dir> -> <stem>.rc.json
compose-preview rc header <doc.rc> [--json]         declared size, profile, version — no inflate
```

Offline: no daemon, no Gradle, no project. `rc dump` on a `.rc` you pulled out of a bundle with
`unzip` is a complete workflow.

`rc header` answers the cheap questions cheaply — and `profiles` is the one to check first when a
document plays in one host and is blank in another, because a player refuses a profile it does not
implement by drawing nothing:

```
$ compose-preview rc header sticker.rc
version              1.1.0
size                 300 x 300
contentDescription   Simple Timer
profiles             513  (EXPERIMENTAL)
bytes                1395
```

**Reading a dump.** Non-finite floats appear as strings, and that is not cosmetic. An id in this
format does not travel as a number — it travels as a *NaN payload* — so `"width": ["@42", "@42"]`
is two encoded references, and `"NaN"` is a genuine NaN (`fillMaxWidth` uses one as its "no
explicit fraction" marker). `$tags` names the operation's role (`COMPONENT`, `MODIFIER`,
`DRAW_OPERATION`, …) so you can filter a dump to the layout tree without hardcoding type names.
`$unserialized` marks an operation upstream has not taught to serialize — `Header` always appears
there, and is decoded properly into the dump's own `header` key, so seeing it twice is expected.

**The one gotcha in the batch mode.** `File.listFiles()` decodes names with `sun.jnu.encoding`;
under `LANG=C`/`POSIX` that is ASCII, and a preview id containing an em-dash comes back mangled and
unreadable. `rc dump <dir>` refuses such a tree by name rather than reporting it as empty — but run
it under `LANG=C.UTF-8` and the question does not arise.

### Where the JSON shows up already

- **A served catalog** answers `GET /render/<id>.rc.json` with the document JSON for any preview it
  publishes a `.rc` for — the text counterpart of the existing `.rc` lane, which serves bytes for
  the in-browser player. A document the server can serve but cannot inflate (a bundle baked on a
  newer Remote Compose alpha than the server links) answers `422` naming the document, rather than
  failing as a server error.
- **A delivery branch** carries `documents/<id>.rc.json` when its catalog sets `rc-document-json` on
  the design-artifacts workflow. That is what makes "did the component change, or did the player
  draw it differently" answerable from a `git diff` — a question a PNG diff cannot separate from a
  different antialiasing pass. `remote-m3` in
  [yschimke/wear-m3-catalog](https://github.com/yschimke/wear-m3-catalog) is the worked example.

The normative account of all of this — including why the dump rides AndroidX's serialization hook
instead of a hand-written binary reader — is
[`docs/design/REMOTE_COMPOSE_JSON.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/design/REMOTE_COMPOSE_JSON.md)
in compose-ai-tools.

## Building live-updating widgets

Most Remote Compose consumers are widget-like: a Glance widget, a tile,
or a watch surface that refreshes its state without re-encoding the
document on every change. Two state models matter:

### Host-driven state (named bindings)

The host pushes a fresh value into a named binding after an HA / API /
WebSocket update. The document identifies the binding by name and
reacts without any re-recording.

```kotlin
// Widget-side authoring
val isOn: RemoteBoolean = createNamedRemoteBoolean(
    name = "light.kitchen.on",
    initialValue = false,
    domain = Domain.User,
)
val label: RemoteString = createNamedRemoteString("light.kitchen.label", "—")

RemoteText(
    text = label,
    color = isOn.select(onColor, offColor),
    // ...
)
```

```kotlin
// Host-side update (your app)
player.write("light.kitchen.on", true)
player.write("light.kitchen.label", "On")
```

**Gotcha.** On the authoring side, `RemoteBoolean.constantValueOrNull`
returns `null` for named bindings — there's no compile-time constant to
seed the initial visual from. If your layout needs to *branch* on the
initial value (e.g. "render the knob on the right when the widget is
authored for a seeded-true light") you have to carry that `Boolean` on
the host side separately and pass it into the composable as a plain
Kotlin `Boolean`, producing a literal `0f.rf` / `1f.rf` in the document.

### In-document state (optimistic click)

For click-flip-now-ack-later UX, the player keeps the state in-document
and flips it on click without a host round-trip:

```kotlin
val localIsOn: MutableRemoteBoolean = rememberMutableRemoteBoolean(initial)
val toggle: Action = ValueChange(localIsOn, localIsOn.not())
val hostCall: Action = HostAction("light.toggle", entityId)

RemoteBox(
    modifier = RemoteModifier
        .clip(RemoteRoundedCornerShape(11.rdp))
        .background(localIsOn.select(onColor, offColor))
        .clickable(toggle, hostCall), // both run on tap
)
```

The `ValueChange` fires synchronously in the player; the `HostAction`
is dispatched back to your app so it can call the real service. If the
host call fails, write back to the same binding by name to roll back.
This is the pattern in the `ClickableDemo` / `SwitchDemo` in the
androidx-main `compose/remote/integration-tests/demos`.

### Animation

Wrap a `RemoteFloat` target in `animateRemoteFloat` and the player
tweens at playback time — no per-frame wake-up on the host:

```kotlin
val target: RemoteFloat = localIsOn.select(1f.rf, 0f.rf)
val progress: RemoteFloat = animateRemoteFloat(rf = target, duration = 0.18f)
// drive position / alpha / color lerp from `progress`
```

## alpha08 pitfalls

All of these bit us building a Lovelace-card widget library against
`remote-creation-compose:1.0.0-alpha08`. Check whether your current
alpha still has each before designing around it.

### V2 applier: don't mix Remote and UI composables

alpha08 dropped the UI-applier fallback. Use `RemotePreview` /
`RememberRemoteDocumentInline` / `captureSingleRemoteDocumentV2` to
open a recording scope, and keep its body pure `@RemoteComposable`.
Mixing in a `Text(…)` from `compose.material` inside the recording
scope produces a broken document. Between scopes (e.g. a regular
`Column` holding multiple independent `RemotePreview` hosts) is fine —
that's how you model "one widget per card" dashboards.

### FlowLayout requires the experimental profile

`RemoteFlowRow` and `RemoteFlowColumn` emit op code 240, which isn't
in the baseline ANDROIDX profile. Build a shared profile once:

```kotlin
val androidXExperimental: Profile = Profile.create(
    Profile.OperationsSetType.Predefined,
    /* operations = */ null,
    Profile.PROFILE_ANDROIDX or Profile.PROFILE_EXPERIMENTAL,
)

RemotePreview(profile = androidXExperimental) { /* uses RemoteFlowRow */ }
```

### Converting a `RemoteFloat` to `RemoteDp`

The `RemoteDp(RemoteFloat)` constructor is `internal`, but `RemoteFloat`
has a public `asRemoteDp()` converter — use that when you need a dp
value that tracks a computed float (e.g. to drive
`Modifier.offset(x = progress.asRemoteDp(), y = 0.rdp)` for sliding a
knob between positions). See
[`RemoteDp.kt`](https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:compose/remote/remote-creation-compose/src/main/java/androidx/compose/remote/creation/compose/state/RemoteDp.kt;l=146)
in androidx-main.

### Modifier chain order when mixing click + clip + background

On the outer shape of a clickable pill, keep the visual modifiers
first and `.clickable` last:

```kotlin
modifier
    .size(36.rdp, 22.rdp)
    .clip(RemoteRoundedCornerShape(11.rdp))
    .background(trackColor)
    .clickable(toggle, hostAction)   // <- last
```

Prepending `.clickable` ahead of `.clip`/`.background` in alpha08 can
swallow the clip + child content (shape renders as a rectangle with no
interior widgets). Probably related to how the clickable wrapper is
emitted into the document.

### `Row` with weighted children overruns `.size(...)`

`RemoteRow` with any `weight(…)` child claims all available width and
ignores a `Modifier.size(W, H)` on the row itself — the weight
behaviour treats the row as fillMax. When you need a fixed-size
weight-driven layout (e.g. the inside of a toggle switch), wrap in an
outer `RemoteBox` whose `.size(...)` is the hard constraint, and have
the inner row `.fillMaxSize()` inside it.

```kotlin
RemoteBox(modifier = RemoteModifier.size(TrackWidth, TrackHeight)
    .clip(...).background(...)) {
    RemoteRow(modifier = RemoteModifier.fillMaxWidth().fillMaxHeight()) {
        // weighted children are now bounded by the Box's size
    }
}
```

## Architecture: one document per card

For dashboard-shaped UIs (a list of independent cards that each update
on their own), resist the urge to author one big `.rc` for the whole
surface. Each widget instance owning its own document gives you:

- independent state updates (one card's binding change doesn't invalidate
  another's player),
- independent hosting (install one card as a Glance widget without
  dragging the whole dashboard into scope),
- smaller documents (easier to stay under `remote-player` memory budgets
  on Wear / embedded surfaces).

Model this in previews too. A "dashboard" preview is a regular
`Column` of `RemotePreview` hosts — *not* one `RemotePreview` wrapping a
`RemoteVerticalStack`:

```kotlin
@Preview(widthDp = 381, heightDp = 411)
@Composable
fun Dashboard() {
    Column(Modifier.fillMaxWidth()) {
        PlayerSlot(heightDp = 43)  { RenderCard(tileA) }
        PlayerSlot(heightDp = 43)  { RenderCard(tileB) }
        PlayerSlot(heightDp = 169) { RenderCard(entities) }
        PlayerSlot(heightDp = 149) { RenderCard(glance) }
    }
}

@Composable
private fun PlayerSlot(heightDp: Int, content: @Composable @RemoteComposable () -> Unit) {
    Box(Modifier.fillMaxWidth().height(heightDp.dp)) {
        RemotePreview(profile = androidXExperimental, content = content)
    }
}
```

`RemoteDocPreview` (what `RemotePreview` delegates to) sizes the player
from `LocalWindowInfo.current.containerSize`, so each slot must have a
bounded size — a wrap-content parent won't work.

## Pixel-parity canvas sizing

When you're comparing RC renders to a reference screenshot, pin the
preview canvas in dp such that the RC PNG has the same pixel
dimensions as the reference PNG:

```
widthDp = round(referenceCapturePx.width / previewRenderDensity)
```

The `compose-preview` plugin renders at density **2.625**. If you
capture HA / dashboard references via Puppeteer at
`deviceScaleFactor = 2` (Retina), a 1000×444 px reference is 381×169 dp
at our render density. Lock that in a top-of-file comment so future
changes don't drift the canvas "for safety margin" and desync the
comparison.

When your converter emits content smaller than the reference card's
natural size, do not shrink the canvas to hide the gap — the
transparent padding is a signal to grow the widget, not the canvas.
