---
name: compose-ui-builder
description: Author and edit a Compose UI design over MCP against a compose-preview serve deployment — create a screen or a Wear widget, insert and edit nodes, and export the Kotlin, PNG or SVG. Use when asked to build, change, or review a UI Builder design (a URL like /ui-builder/<catalog>/<designId>), to turn a design into Compose code, or to collaborate with a designer on one.
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

**Read [references/m3-catalog.md](./references/m3-catalog.md) rather than
calling `ui_builder_list_catalogs` to find out what to insert.** It carries the
component ids, slot names, required properties and enum values for the two
published catalogs, which is what an insert needs. `list_catalogs` is the
authority and answers with far more — every component's parameters, adapter and
parity statuses — so reach for it when something is missing from the reference
file, and reduce it with the recipe at the bottom of that file.

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
- **Pass the token as each tool's `token` argument.** An MCP client fixes its
  headers when it connects, so a token approved mid-session cannot become a
  header. Every gated tool takes `token` for exactly this reason.

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
- **Wait instead of polling.** `ui_builder_await_design` blocks until somebody
  else changes the design and returns what changed;
  `ui_builder_await_comments` does the same for the discussion. Both take a
  cursor you quote (`lastSequence` / `sequence`) and answer `timedOut` when
  nothing happens, which you answer by calling again with the same cursor. This
  is cheaper and faster than re-reading the design in a loop, and it is what
  makes you a participant in a session rather than a poller.

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
