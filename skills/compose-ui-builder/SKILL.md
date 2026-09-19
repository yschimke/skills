---
name: compose-ui-builder
description: Author and edit a Compose UI design over MCP against a compose-preview serve deployment — create a screen or a Wear widget, insert and edit nodes, and export the Kotlin, PNG or SVG. Also use when no host exists and the builder must be run locally (ui-builder --no-project). Use when asked to build, change, or review a UI Builder design (a URL like /ui-builder/<catalog>/<designId>), to turn a design into Compose code, or to collaborate with a designer on one.
---

# Compose UI Builder

The UI builder is an authoring surface served by `compose-preview serve`: a
design is a **document of catalog components**, edited by an operation log, and
exported as Compose Kotlin (or PNG/SVG). A person edits it in the browser at
`/ui-builder/<catalog>/<designId>`; you edit the same live document over the
server's MCP endpoint. Both land in one revision log, so you and a designer can
work on the same design at the same time.

This is **not** the `compose-preview` renderer. That renders `@Preview`
functions from a checkout you can build. This authors a design that has no
checkout at all, on someone else's server, and hands you Kotlin at the end. If
you have the repo and the composable already exists, you want **compose-preview**.

Maintained at [github.com/yschimke/skills](https://github.com/yschimke/skills)
under `skills/compose-ui-builder/`. The server ships from
[github.com/yschimke/compose-preview-server](https://github.com/yschimke/compose-preview-server);
its human-facing guide is
[`docs/UI_BUILDER_GETTING_STARTED.md`](https://github.com/yschimke/compose-preview-server/blob/main/docs/UI_BUILDER_GETTING_STARTED.md).

## Get to the first edit in five calls

Everything below is the long version. This is the whole loop:

```jsonc
// 1. request_access  — capabilities, not scope (see "Getting in")
{"capabilities": ["ui-builder-read", "ui-builder-write", "ui-builder-export"],
 "ttlSeconds": 14400,
 "label": "add a header row to the settings screen"}
// → show approveUrl + userCode to your human, then poll_access

// 2. ui_builder_create_design — a whole document; the starter below is known-good
{"designId": "settings-v2", "document": { …see "A document that works"… }}

// 3. ui_builder_apply — insert a column and a text into it, one operation
{"designId": "settings-v2", "operationId": "op-1", "baseRevision": 0, "operations": [
  {"type": "insertNode",
   "node": {"id": "col", "componentId": "layout/column", "slots": {"children": []}},
   "location": {"parent": {"nodeId": "root", "slot": "content"}}},
  {"type": "insertNode",
   "node": {"id": "title", "componentId": "m3/text",
            "properties": {"text": {"type": "string", "value": "Settings"}}},
   "location": {"parent": {"nodeId": "col", "slot": "children"}}}]}
// → {"outcome":{"type":"accepted","committedRevision":1, …}}   ← next baseRevision

// 4. ui_builder_export — the Kotlin, or diagnostics saying why not
{"designId": "settings-v2", "format": "compose"}

// 5. tell your human where it is
// https://<host>/ui-builder/<catalogSystemId>/settings-v2
```

Send that browser URL as soon as the design exists, then keep sending the
current revision, what just changed, the comment state, and the next action.
Do not make a person infer progress from a silent series of MCP calls. A useful
update is: “Desktop reference is at revision 4; the header and rails are in;
there are no open comments; next I am comparing it with the attached reference.”

Before creating anything, orient yourself:

1. Look for an existing design or checked-in fixture with the requested name.
   Read the current design, its links, and its comments before deciding to copy,
   edit, or create it.
2. Open the canonical path URL returned by the design identity:
   `https://<host>/ui-builder/<catalogSystemId>/<designId>`. Do not invent an
   old query-string URL; the path carries both the catalog and design.
3. If the request names or attaches a visual reference, open **Frame, density
   and reference** in the browser and check whether one is already attached.
   The full reference workflow is under [Compare with a reference](#compare-with-a-reference).
4. Report the link, revision, open-comment count, and the first planned part
   before editing. This is the point where the person can correct the target
   while the correction is still cheap.

**Read [references/m3-catalog.md](./references/m3-catalog.md) rather than
calling `ui_builder_list_catalogs` to find out what to insert.** It carries the
component ids, slot names, required properties and enum values for the two
published catalogs, which is what an insert needs. `list_catalogs` is the
authority and answers with far more — every component's parameters, adapter and
parity statuses — so reach for it when something is missing from the reference
file, and reduce it with the recipe at the bottom of that file.

## No host? Run one locally

Everything above assumes somebody is hosting the builder. If nobody is, you can
be the host — the editor, the design service and the MCP endpoint all ship
inside the server distribution `compose-preview` fetches on first use. This is
the path agents most often get wrong, so the wiring is spelled out.

### Start it

```sh
compose-preview ui-builder --no-project --no-open
#   Local:   http://127.0.0.1:8723/?token=…
#   Builder: http://127.0.0.1:8723/ui-builder/m3-catalog/?token=…
```

`--no-project` opens the builder against the **packaged** catalogs
(`m3-catalog`, `remote-m3`) with no Gradle project and no build host. Without
it, the server wants a project and a build host and says so. `--no-open` prints
the URL instead of launching a browser. Designs persist under
`~/.compose-preview/ui-builder-state`; `--ui-builder-state-dir <dir>` moves
that, and `--ui-builder-state-dir none` serves the editor with no design API.
PNG and SVG export need the JVM to be **Java 21+**; on an older JVM everything
else works and the startup log says which version it found.

The port is the server's default (`8723`) unless taken, in which case the next
free one is used — **read the printed URL, don't assume the port**.

### With a project: name the module

Drop `--no-project` and the server wants a Gradle project and a build host, and
it discovers *every* module that applies the preview plugin. On a repo with more
than one module — or with a module whose previews do not render on your machine
— that is a build you did not ask for, and the server refuses to host more than
one module anyway. Pass the module:

```sh
compose-preview ui-builder --module :my-module --no-open
```

`--module` scopes discovery and the render to that one module, so a broken
sibling cannot fail the build before the builder starts. (A server distribution
older than the fix for this ignores the flag, builds everything, and then asks
you to narrow — update the distribution if you see that.) `--no-project` and
`--module` are mutually exclusive; the server refuses the pair rather than
guessing.

### The flag that decides whether MCP works at all

A local session is closed by default. Three facts, each of which cost an agent
an hour:

| Symptom | Cause | Fix |
| --- | --- | --- |
| `POST /mcp` 404s | the aggregate MCP endpoint was never enabled | start with `--catalog-mcp`, which also requires `--agent-grants` |
| `/mcp` lists every `ui_builder_*` tool but each call answers *"the presented identity lacks the UI-builder read capability"* | the grant store's capability ceiling is empty, so no approval can carry them | add `--agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export` and restart |
| the approval page shows scopes but no capability checkboxes | same ceiling, seen from the human's side | same flag; the page will then offer them (and name them as withheld when it cannot) |

So the full local command is:

```sh
compose-preview ui-builder --no-project --no-open \
  --agent-grants --catalog-mcp \
  --agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export
```

The `?token=` in the printed Builder URL is the **operator** credential: it
authorizes browser routes and the approval page, and it is what makes you the
approver. It is not the MCP bearer and should not be sent as one.

### Get a grant

Same device-code flow as a deployed host, pointed at the local port:

```sh
compose-preview auth request --server http://127.0.0.1:8723 \
  --capability ui-builder-read --capability ui-builder-write --capability ui-builder-export \
  --label "local authoring session"
# prints approveUrl + userCode; open the URL, confirm the code, approve
```

Open the `approveUrl` with the operator token appended
(`?token=<the token from the Builder URL>`) when the box is gated, approve, and
the waiting command stores the grant. `compose-preview auth status --server …`
shows it; `compose-preview auth token --server …` prints it for anything else.
The request expires in ten minutes and a server restart drops the grant — a
sudden refusal after a restart is that, not a bug.

### Two ways to attach your MCP client

**Server aggregate MCP (Streamable HTTP).** `POST http://127.0.0.1:8723/mcp`
with `Authorization: Bearer <grant>` (a bare `GET /mcp` answers 405 — POST is
the transport). Tool names are the `ui_builder_*` family this skill uses
throughout, so everything below applies unchanged.

**Standalone stdio MCP.** `compose-preview mcp serve --ui-builder-url
http://127.0.0.1:8723`, with `COMPOSE_PREVIEW_UI_BUILDER_TOKEN` exported — it is
read from the environment and **never accepted as an argv value**. This server
speaks the versioned v1 design API, and its tools are named differently from the
aggregate endpoint:

| Tool | What it does |
| --- | --- |
| `list_components` | catalogs and capability schemas — read the current pin before creating |
| `create_design` | a whole v1 document, never overwriting an existing id |
| `open_design` | the latest committed snapshot |
| `apply_design_operations` | one v1 batch (shape below) |
| `render_design` / `export_svg` / `export_compose` | revision-pinned artifacts (the committed revision is required, as on the aggregate tools) |
| `get_revision_diff` | durable events after a sequence cursor |

`apply_design_operations` takes `{"submission": …}` and the submission is the
**batch envelope**: the `type` discriminator is required, `clientId` is required
(any stable string naming your session), and `actorId` must be **omitted** — it
is bound to the authenticated actor, and a different one is refused:

```json
{"type": "batch", "designId": "my-design", "operationId": "op-1",
 "clientId": "my-session", "baseRevision": 0,
 "operations": [
   {"type": "insertNode",
    "node": {"id": "col", "componentId": "layout/column", "slots": {"children": []}},
    "location": {"parent": {"nodeId": "root", "slot": "content"}}}]}
```

A decoder error naming a class discriminator, or `Field 'clientId' is required`,
means exactly those two fields — the same operations work once they are present.

### The shell verbs, against the local session

`compose-preview design list|get|render|export` are clients: they talk to a
server that is already up and exit. Point them at the session explicitly:

```sh
compose-preview design list --server http://127.0.0.1:8723
compose-preview design export my-widget -o Widget.kt --server http://127.0.0.1:8723
```

Two traps. The verbs read `$COMPOSE_PREVIEW_TOKEN` (or the older
`$COMPOSE_PREVIEW_UI_BUILDER_TOKEN`) rather than the `auth` store, so export the
token unless your CLI is new enough to bridge a stored grant for an explicit
`--server`. And with no credential they start an interactive device flow and
**wait** — pass `--no-authorize` in CI so they fail fast instead. The default
`--server` is the server's default port, so an auto-picked port needs the flag.

### Creating and rendering without MCP at all

The browser routes accept the operator token as `?token=`, which is enough for a
smoke test:

```sh
curl -X POST 'http://127.0.0.1:8723/ui-builder/designs?token=<operator-token>' \
  -d 'catalog=remote-m3&designId=my-widget&template=weather-widget'   # 303 → the design URL
curl -o design.svg \
  'http://127.0.0.1:8723/api/ui-builder/v1/designs/my-widget/export.svg?token=<operator-token>'
```

Template ids: `blank` for `m3-catalog`; `wear-widget-small`, `wear-widget-large`,
`hello-widget` and `weather-widget` for `remote-m3` — the last two are finished
worked designs, useful as a known-good starting document.

## Two habits worth keeping

**1. Follow Material guidance, responsive layout included.**

A screen that looks right at the frame you authored it at may still have work
left, so it is worth reaching for the catalog's adaptive components before
falling back to fixed layout:

- `layout/supporting-pane-scaffold` is `androidx.compose.material3.adaptive`'s
  own `SupportingPaneScaffold`. It gets a directive computed from the frame's
  constraints, so it collapses to one pane on a phone by itself — a good fit for
  list-detail and content-plus-context screens, better than a `row`.
- `layout/lazy-grid` with `{"type": "adaptiveGrid", "minimumCellWidthDp": N}` is
  `GridCells.Adaptive`, and reflows its column count with the width. Usually
  what you want wherever the item has a natural minimum size.
- Set `environment.exportDevices` to the devices the screen claims to work on,
  and try to look at each before calling it done — the set you look at is the
  set the export writes as `@Preview(device = …)`.

If you find yourself wanting to branch the document on width, that is usually a
sign an adaptive component fits better: the builder holds one document per
design, and two designs for two sizes is the thing adaptive layout saves you
from.

Then read the compact frame honestly. A navigation rail still 88dp wide at
411dp, a chip row squeezed to one letter per line, a tab row breaking its labels
over three lines — worth treating as findings rather than cosmetics, which leads
to the second habit.

**2. Report the gap before working around it, and say that you worked around it.**

When the catalog, the canvas or an exporter will not do the Material-correct
thing, the finding is often worth more than the screen. Roughly in order:

1. **File it**, with the node, the property, the message, and which lane
   refused — canvas, local export, server export; they do not always agree, and
   which ones disagree is half the report.

   Where it goes depends on what is missing, because the catalogs are their own
   projects on their own release trains:

   | The gap | Where it belongs |
   | --- | --- |
   | A component the catalog does not have, or one whose declared property it does not honour — no `NavigationSuiteScaffold`, no `FlowRow`, a `contentAlignment` nothing reads | the catalog's own repository: **m3-catalog**, **wear-m3-catalog** |
   | The builder, the canvas, an exporter or the wire — a shape the canvas draws and the exporter refuses, a validator that disagrees with the server, a dock that clears what you picked | [compose-preview-server](https://github.com/yschimke/compose-preview-server/issues) |

   Not always obvious which, and it is fine to say so: file where you can reach,
   name the component and the lane, and say which project you think owns it.

   A design comment pinned to the node with `ui_builder_post_comment` also puts
   it where the designer will see it. For a real gap, usually worth both.
2. **Then** author the stand-in, if the screen needs one — a `column` of icon
   buttons where a navigation rail should be, rows where a fixed grid should be.
3. **Say it is a stand-in**, in the comment and in whatever you hand back. An
   unlabelled workaround tends to read as the catalog's answer, which hides the
   gap from the next person.

"I used a Row because there is no FlowRow" is a useful sentence. A Row with no
explanation is a screen that looks finished and is not.

## Getting in

The `ui_builder_*` tools are gated on **capabilities** — `ui-builder-read`,
`ui-builder-write`, `ui-builder-export` — which are *not* implied by the
`preview` / `live` / `playground` scope ladder the catalog tools use. Asking for
`live` gets you nothing here. Ask for the three capabilities by name (and
`preview` scope, which costs nothing and lets you look at rendered catalogs).

A call without them fails with the flow spelled out:

> this tool needs a UI-builder read grant; none was presented. Call
> request_access with capability 'ui-builder-read' …

The handshake is the ordinary agent-grant one — see
[server-access.md](../compose-preview/references/server-access.md) and
[catalog-mcp.md](../compose-preview/references/catalog-mcp.md) in the
**compose-preview** skill; all of it applies. Two things specific to here:

- **Ask for all three capabilities at once.** Discovering `ui-builder-write` one
  `403` at a time costs a human round trip each time, and an approver can only
  grant what the server's own ceiling allows anyway.
- **Ask for enough time once.** An iterative authoring and review session often
  outlives the one-hour default. Request `ttlSeconds: 14400` (four hours) when
  the task includes reference comparison or live feedback, while keeping the
  grant limited to these three capabilities. The approver may shorten it. Do
  not ask for a longer grant merely to compensate for polling or idle waiting.
- **Pass the token as each tool's `token` argument.** An MCP client fixes its
  headers when it connects, so a token approved mid-session cannot become a
  header. Every gated tool takes `token` for exactly this reason.
- **Collect approval in the background.** Immediately after `request_access`,
  relay its exact `approveUrl` and `userCode`, then start a bounded background
  task that calls `poll_access` with the returned request id and device secret.
  `poll_access` is interval polling rather than a server-held long poll, so
  obey `pollIntervalSeconds` and stop on approved, denied, expired or unknown;
  never spin. The collector should hand the token back to the active task
  without printing it and wake the edit automatically. Do not make the person
  return and say “done” merely to trigger the first poll. If the runtime cannot
  delegate background work, keep the current turn open and poll at the stated
  interval while doing any useful ungated or already-authorized preparation.
  The approval request itself normally expires after ten minutes, independently
  of the longer grant TTL being requested.

Grants live in memory: a redeploy drops yours mid-task. A sudden refusal is
that, not a bug — ask again the same way.

## A document that works

`create_design` takes either `fromDesignId` (copy an existing design) or a whole
`document`. Copying is safer *if you can see a design to copy* — but a fresh
grant usually sees none (`list_designs` shows only what your actor owns or was
shared), so you will be writing a document. These two are verified against the
live server; the only fields you should change are the ids, the title and the
environment.

**A phone screen** (`m3-catalog`):

```json
{
  "schema": "compose-ui-builder-document/v1-candidate",
  "id": "<designId>",
  "title": "<title>",
  "revision": 0,
  "catalogPin": {"systemId": "m3-catalog", "catalogRevision": "candidate",
                 "capabilityDigest": "candidate", "nativeRuntimeId": "candidate"},
  "environment": {"widthDp": 412, "heightDp": 915, "density": 2, "theme": "light",
                  "locale": "en-US", "fontScale": 1, "layoutDirection": "ltr"},
  "roots": ["root"],
  "nodes": {"root": {"id": "root", "componentId": "m3/surface",
                     "properties": {}, "slots": {"content": []}}}
}
```

**A Wear widget** (`remote-m3`) — note the different `catalogRevision`, the
216×76dp (small) or 216×124dp (large) frame, and the scaffold's two slots:

```json
{
  "schema": "compose-ui-builder-document/v1-candidate",
  "id": "<designId>", "title": "<title>", "revision": 0,
  "catalogPin": {"systemId": "remote-m3", "catalogRevision": "wear-widget-scaffolds-v1",
                 "capabilityDigest": "candidate", "nativeRuntimeId": "candidate"},
  "environment": {"widthDp": 216, "heightDp": 76, "density": 2, "theme": "dark",
                  "locale": "en-US", "fontScale": 1, "layoutDirection": "ltr"},
  "roots": ["widget"],
  "nodes": {"widget": {"id": "widget", "componentId": "remote-m3/widget-container-small",
                       "properties": {}, "slots": {"background": [], "content": []}}}
}
```

The `catalogPin` is checked against what the server actually serves, and a pin
you invent is refused — which is why there is no "blank template" argument on
the tool. If a pin above stops working, read the current one out of
`list_catalogs`'s `benchmark` (`catalogSystemId`, `catalogRevision`,
`nativeRuntimeId`) and use `"candidate"` for `capabilityDigest`.

## The vocabulary

Four things have to be right, and all four are guessable-wrong:

**Component ids are slash-shaped**: `m3/text`, `layout/column`,
`m3/list-item` — not `m3.Text`, not `Text`. The full table is in
[references/m3-catalog.md](./references/m3-catalog.md).

**A child goes into a named slot of its parent**, never just "into" it:

```json
"location": {"parent": {"nodeId": "col", "slot": "children"}}
```

Slot names differ per component — `children` for `layout/column|row|box`,
`content` for `m3/surface|card|button`, `items` for the lazy containers,
`headline`/`supporting`/`trailing` for `m3/list-item`, `topBar`/`content` for
`layout/scaffold`. `afterNodeId` / `beforeNodeId` place a node among its
siblings. `location: {}` targets the root list — and a design has **at most one
root** (`a design has at most one root; found 2`), which the starter document
already supplies, so in practice every insert you write names a parent slot.

**Property values are wrapped, and the wrapper is the value's *kind*** —
`{"type": …, "value": …}`:

```json
"properties": {"text":     {"type": "string", "value": "Settings"},
               "style":    {"type": "enum",   "value": "headlineSmall"},
               "color":    {"type": "color",  "value": "#5F6368"},
               "maxLines": {"type": "int",    "value": 2},
               "verticalSpacingDp": {"type": "float", "value": 12},
               "enabled":  {"type": "bool",   "value": true}}
```

The three that are not obvious from the reference table's `jsonType`, because
that column describes the JSON shape rather than the meaning:

- **A property with `allowedValues` is an `enum`** — `style`, `variant`,
  `contentScale`, the arrangements and alignments. A value outside the list is
  refused by name.
- **A colour is a `color`**, written `#RRGGBB` — `m3/text.color`,
  `m3/surface.containerColor`, `m3/icon.color`. A theme role is a `colorToken`
  (`{"type": "colorToken", "value": "outlineVariant"}`), which is the better
  choice when you want the design to follow the theme.
- **A dimension is a `float`**, in dp, and the property name says so
  (`sizeDp`, `verticalSpacingDp`, `shapeDp`).

**Modifiers are a typed list**, replaced wholesale by `setModifiers`:

```json
{"type": "setModifiers", "nodeId": "col", "modifiers": [
  {"type": "fillMaxWidth"},
  {"type": "padding", "startDp": 16, "topDp": 24, "endDp": 16, "bottomDp": 16}]}
```

Others in use: `fillMaxSize`, `matchParentSize`, `size` (`widthDp`/`heightDp`),
`height`, `width`, `clip` (`shape`), `border`, `weight`, `testTag`. A
`background` takes a colour like any other — `{"type": "background", "color":
{"type": "color", "value": "#D7E3F4"}, "shape": "medium"}` — and `shape` is a
token (`medium`, `large`) or a corner radius in dp as a string (`"20"` on a 40dp
box is a circle, which is how you draw an avatar). Each component declares what
it accepts in `modifierCapabilities`.

## The edit loop

`ui_builder_apply` is the workhorse and the only cheap call:

- **Batch.** `operations` is an array; a scaffold, its column and three texts are
  one call, one revision, one undo step for the designer watching.
- **`operationId` is yours** and makes a retry idempotent — a replay answers
  `idempotentReplay: true` rather than inserting twice.
- **`baseRevision` is the revision you last saw.** The reply's
  `committedRevision` is your next one; track it locally rather than re-reading
  the design. A stale base is **not** automatically refused — the service rebases
  what does not collide and reports what does in `conflicts`, so check that array
  rather than assuming a rejection.
- **A batch is atomic.** One refused operation lands none of them, so a
  container and the child a slot requires can safely be inserted together.
- **A rejection is a normal reply, not an error.** It arrives as
  `{"outcome":{"type":"rejected","code":"invalidDocument","message":"required
  property text is missing","nodeId":"no-text","field":"text"}}` — code, node and
  field, precise enough to fix without a re-read. The three you will actually
  meet:

  | Message | What it means |
  | --- | --- |
  | `required property text is missing` | the component's `required` column |
  | `property style is outside its catalog allowed values` | not in `allowedValues` |
  | `slot content has 0 children; expected 1..unbounded` | that slot needs a child now |

### Keep the loop cheap

`apply` costs a few hundred bytes; a snapshot (`create_design`, `get_design`)
answers with the design **and** the catalog behind it, which is a much bigger
reply. So drive from `apply`: it tells you the new `committedRevision`, which is
the only thing you needed the snapshot for. Hold the node ids you are creating —
you chose them — and re-read the design when somebody else has edited it, not
after every change of your own.

If your host saves oversized tool results to a file, that is the cheap way to
read one: pull `state.document` out of the file rather than into the
conversation.

### Work in visible steps

One `apply` per part of the screen — shell, header, list, footer — rather than
one call for the lot. Each is its own revision, so:

- a rejection costs one part rather than the screen (the batch is atomic, so
  nothing lands and nothing is half-built);
- the designer watching in the browser sees the screen assemble in steps they
  can follow and undo individually;
- and when something looks wrong you know which step did it.

Batch *within* a part, though: a container and the child its slot requires go in
one call, because a slot with a minimum is refused while it is empty.

## Export is also a check

A design and its Kotlin are two different deliverables, and a design can be
perfectly good without being exportable — the document holds what the catalog
declares, and the Compose generator writes what it has a record for. When the two
disagree the export says so per node, and the design itself is untouched:

```json
{"severity": "error", "code": "UNPROVEN_CALL_SITE",
 "message": "no component `m3/list-item` in this catalog"}
```

So decide which you are making, and act on it early:

- **Kotlin is the deliverable** → export after the first structural batch, not at
  the end. A diagnostic then costs one component swap; the same diagnostic after
  eighty nodes costs a rebuild. Empty `diagnostics` is a real check on the
  design, not a formatting step.
- **The design is the deliverable** — a mockup, a PNG, a screen a designer takes
  over → use whatever the catalog offers and read the diagnostics as a note about
  the generator rather than a problem with your design.

## Seeing what you built

- **`ui_builder_export` `format: "compose"`** — the generated Kotlin, plus
  `diagnostics` naming anything the generator refused. Empty diagnostics is the
  gate a designer sees in the browser's code pane, so it is a real check on the
  design, not just a formatting step.
- **`format: "png"`** (or `"svg"`) — base64 in `artifact.content`, a few KB for a
  simple screen and the most reliable way to *look* at your work. Needs the
  server on Java 21+; a host without it says so.
- **`ui_builder_render_native`** compiles the design with real Compose on the
  host and reports where each node drew (`nodeBounds`, `taggedNodeIds`). It is a
  compile, so it takes minutes and only exists where the host can run one — reach
  for it when you need the ground truth about layout, and `export png` for the
  ordinary "does this look right" loop.
- **The browser URL** — `https://<host>/ui-builder/<catalogSystemId>/<designId>`
  — is what you hand a person. Always give them this rather than describing the
  design.

## Compare with a reference

The browser has a persistent reference-diff workspace. It is not the same as
adding an `asset/image` node and it is deliberately separate from the design:
reference pixels are not catalog-validated, revisioned, replayed, or included
in Kotlin/PNG/SVG exports.

To find it, open the design URL, select **Frame, density and reference** in the
right inspector rail, then use **Attach file** or paste an image from the
clipboard. Choose the view that answers the current question:

- **Overlay** for alignment at an adjustable opacity.
- **Difference** to make matching pixels recede and expose visual mismatches.
- **Split** for a movable before/after wipe.
- **Boxes** for layout guides extracted from a compatible SVG.

Adjust opacity, X/Y offset, scale, or the split position before changing the
document; a badly aligned reference creates false design work. The same panel
supports markup, component pieces, erasing, promotion of captured catalog
components, and **Flatten** when the current annotated stack should become the
next reference. The feature and its storage boundary are documented in
[`UI_BUILDER_REFERENCE_OVERLAY.md`](https://github.com/yschimke/compose-preview-server/blob/main/docs/design/UI_BUILDER_REFERENCE_OVERLAY.md).

An uploaded reference persists on the remote host beside the design. Before
uploading a user-supplied screenshot, say that plainly and obtain explicit
authorization for that image and destination. A request to inspect an
attachment is not upload permission. Never print its base64 or put a bearer
token in a URL, repository, comment, or progress update.

At present the browser exposes reference import and diff controls, while the
catalog MCP may expose no `ui_builder_*reference*` tool. Confirm with
`tools/list`; do not pretend `put_asset` attaches a reference. When the MCP
lacks parity, guide the person through the browser controls. Use the reference
REST routes only when the person explicitly asked you to upload the image and
the available execution environment can keep the token and pixel payload out
of logs. Treat missing MCP parity as product feedback, not as evidence that the
browser feature does not exist.

After attaching a reference, inspect **Difference** or **Split** in the browser
in addition to exporting the design on its own. For a UI-builder-shell
reference, explicitly account for the top command bar (undo/redo,
Design/Preview, code, share, renderer, new and overflow), both action rails,
the surface/properties bar, zoom/fit controls, and the bottom
revision/node/live status. Do not call the reference complete while those
controls are absent merely because the central canvas resembles the target.

## Working with a person on it

- **You are working as the person who approved your grant.** A design you create
  is **owned by them**, not by your grant — so it outlives the grant and the link
  you send them opens. Designs they already own are open to you, with the
  capabilities they ticked. `list_designs` shows the pair: `ownerActorId` is
  theirs, `requesterAccess.actorId` is yours. Your edits stay attributed to you.
- **Sharing** is per design and owner-only: `ui_builder_design_access` lists who
  can open one, `ui_builder_share_design` adds an actor id
  (`github:<login>`, `operator`, `agent:<fingerprint>`) as `viewer` (read and
  export) or `editor` (also write). Neither role can share it on. `GET
  /agent-access/whoami` tells you your own `actorId` and the
  `onBehalfOfActorId` you are acting for.
- **Comments are a conversation.** `ui_builder_list_comments` reads the threads a
  designer left, `ui_builder_post_comment` replies (pinned to a node, a markup
  stroke, or a point on the frame), `ui_builder_resolve_comment_thread` closes
  one. This is how you answer "why did you put the button there".
- **A design says what it is for.** `ui_builder_get_links` reads the record
  beside a design — the tracker `issue` it was drawn for, the `reference` frame
  in the design tool, the `pr` that implemented it, the chat `thread` it is
  being discussed in, and the `previous` design it continues. You rarely need
  to call it: the same object rides along on `ui_builder_get_design` as
  `links`, so the brief behind a screen arrives on the reply you are already
  reading. Read it before you redesign something — "make the header smaller" is
  a different task when the issue says the header is the complaint.
  `ui_builder_set_links` writes it back, and **replaces the whole record**, so
  send every link you want to keep and not only the one you are changing. All
  five are optional; everything but `previous` is an absolute `http(s)` URL.
  Writing takes the design's own write access, so a design shared with you as a
  viewer is readable and not writable.
- **A comment may leave the editor.** A host can be started with
  `--ui-builder-comment-webhook`, and then a new thread, a reply and a
  resolution are posted to a chat channel with a link back to the thread — the
  author's name, the first 160 characters of what was said, and where it is
  pinned. Reactions and acknowledgements are deliberately silent, so catching up
  on a thread never pages anybody. Write a comment as something a PM or an
  engineer might read in Slack rather than as a note to the designer alone, and
  say what you changed rather than only that you changed something. Your
  comments are marked `authorKind: agent`, so a channel can tell them from a
  person's.
- **Check comments at the edges of every visible step.** Read comments before
  the first edit and after every accepted `apply` or export. Acknowledge or
  answer new feedback before starting the next part, and report the open-thread
  count with the revision. This keeps a comment posted during a long build from
  sitting unseen until the final handoff.
- **Wait instead of polling.** `ui_builder_await_design` blocks until somebody
  else changes the design and returns what changed;
  `ui_builder_await_comments` does the same for the discussion. Both take a
  cursor you quote (`lastSequence` / `sequence`) and answer `timedOut` when
  nothing happens. Before a bounded wait, tell the person what link and revision
  are ready, which feedback you are waiting for, and how long you will wait.
  On timeout, say that no new comments arrived and either continue with the
  stated next step or hand back control; do not silently recurse forever. Reuse
  the same cursor for a later wait. This is cheaper and faster than re-reading
  the design in a loop, and it is what makes you a participant in a session
  rather than a poller.
- **Delegate a background watcher when the agent runtime supports it.** For an
  active collaborative session, give a background task the design id, host,
  current comment `sequence`, and a bounded window (30 minutes is a useful
  default). It should loop on `ui_builder_await_comments` with calls shorter
  than the host's request timeout, reuse the returned cursor, and notify only
  when a new comment arrives, the grant expires, a material error needs action,
  or the window ends. It must not mutate the design or discussion. Tell the
  person when the watcher starts and exactly when it stops, so “background”
  never implies an invisible permanent service. A delegated task belongs to
  the current agent task unless the runtime explicitly provides durable
  automations; it must not promise notification after that task is closed.

## Keeping a design

A live design exists only in the server's state directory. To version one, the
server repo ships `scripts/ui-builder/design-sync.mjs`, which exports a design as
an operations fixture (and imports one back as a fresh live design):

```sh
COMPOSE_PREVIEW_UI_BUILDER_TOKEN=… node scripts/ui-builder/design-sync.mjs export my-widget \
  --server https://<host> --out ui-builder/designs/my-widget.json
```

An app checkout keeps those under `ui-builder/designs/` with an `index.json`;
a host started with `--ui-builder-designs ./ui-builder/designs` lists them under
**From the projects** on `/admin/ui-builder`, ready to open again. That fixture
format (`compose-ui-builder-operations/v1-candidate`) is a **different envelope**
from the `DesignMutationV1` operations you send to `apply` — do not copy one into
the other; its `insertNode` puts the parent at the top level, `apply`'s puts it
under `location`.

## Gotchas

- **A local session is closed until you open it.** `--agent-grants --catalog-mcp
  --agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export`
  is the difference between a working local MCP endpoint and one that 404s or
  refuses every call — see [No host? Run one locally](#no-host-run-one-locally).
- **Capabilities, not scope.** `live` does not include `ui-builder-read`.
- **`list_designs` can legitimately be empty.** It lists what *your actor* can
  see, not what is on the server.
- **A design id must be path-safe** and is chosen by you; creation never
  overwrites, so an id that exists answers "already exists" rather than replacing
  a design.
- **Presence never wakes `await_design`.** Somebody looking at the design, or
  moving their cursor, is deliberately not a change.
- **The tools are absent, not failing, on a box with no builder.** Read
  `tools/list`; `ui_builder_render_native` is likewise absent where the host
  cannot compile.
- **`setModifiers` replaces the whole list** for a node — there is no
  add-one-modifier operation, so send the modifiers you want the node to end up
  with.
- **An `assetKey` has to resolve on the host.** `asset/image` names an asset the
  server holds; on a host with no asset store there is nothing to name, and a
  coloured `layout/box` is the honest stand-in for a photograph in a mockup.
- **The frame's ground comes from `environment.theme`.** A surface's
  `containerColor` colours that surface; going dark is
  `{"type": "updateEnvironment", "changes": [{"type": "setTheme", "value": "dark"}]}`.
