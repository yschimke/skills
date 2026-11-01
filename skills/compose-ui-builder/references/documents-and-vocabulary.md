# Documents, vocabulary and export

Part of the [compose-ui-builder skill](../SKILL.md).

## Which catalog reference to read

**Read [m3-catalog.md](./m3-catalog.md) rather than
calling `ui_builder_list_catalogs` to find out what to insert.** It carries the
component ids, slot names, required properties and enum values for
`m3-catalog`, and the pins for every catalog, which is what an insert needs. A
Wear app screen uses [wear-m3-catalog.md](./wear-m3-catalog.md) and
a Wear widget [remote-m3-catalog.md](./remote-m3-catalog.md). `list_catalogs` is the
authority and answers with far more — every component's parameters, adapter and
parity statuses — so reach for it when something is missing from the reference
file, and reduce it with the recipe at the bottom of that file.

## A document that works

`create_design` takes either `fromDesignId` (copy an existing design) or a whole
`document`. Copying is safer *if you can see a design to copy* — but a fresh
grant usually sees none (`list_designs` shows only what your actor owns or was
shared), so you will be writing a document. These three are verified against the
live server; the only fields you should change are the ids, the title, the
environment and — for `wear-m3` only, which has no stable pin — the whole
`catalogPin`.

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

**A Wear OS app screen** (`wear-m3`) — a round frame, a `screen-scaffold`
root whose `content` takes one child (usually a
`wear-m3/transforming-lazy-column`), and **no fixed pin**: `wear-m3` has no
`candidate` alias, so copy the whole `catalogPin` object from the `wear-m3`
entry of `ui_builder_list_catalogs`. The values below are what preview.coo.ee
served on 2026-10-11 and change with each catalog release:

```json
{
  "schema": "compose-ui-builder-document/v1-candidate",
  "id": "<designId>", "title": "<title>", "revision": 0,
  "catalogPin": {"systemId": "wear-m3",
                 "catalogRevision": "sha256:b37fb7ace974e9cd4b5a068d623487fe",
                 "capabilityDigest": "candidate",
                 "nativeRuntimeId": "wear-m3-p2-a70b6f2e1a9e"},
  "environment": {"widthDp": 227, "heightDp": 227, "density": 2, "theme": "dark",
                  "locale": "en-US", "fontScale": 1, "layoutDirection": "ltr"},
  "roots": ["root"],
  "nodes": {"root": {"id": "root", "componentId": "wear-m3/screen-scaffold",
                     "properties": {}, "slots": {"content": []}}}
}
```

The `catalogPin` is checked against what the server actually serves, and a pin
you invent is refused (`catalogUnavailable`) — which is why there is no "blank
template" argument on the tool. If a pin above stops working, copy the
catalog's `catalogPin` from `ui_builder_list_catalogs` unchanged. Run
`ui_builder_check_design` with the `document` before `create_design`: it
reports a refused pin without creating anything.

## The vocabulary

Four things have to be right, and all four are guessable-wrong:

**Component ids are slash-shaped**: `m3/text`, `layout/column`,
`m3/list-item` — not `m3.Text`, not `Text`. The full table is in
[references/m3-catalog.md](./m3-catalog.md).

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

The reference tables give each property's kind. The three that a raw
`ui_builder_list_catalogs` listing hides, because it describes the JSON shape
(`string`, `number`) rather than the meaning:

- **A property with `allowedValues` is an `enum`** — `style`, `variant`,
  `contentScale`, the arrangements and alignments. A value outside the list is
  refused by name.
- **A colour is a `color`**, written `#RRGGBB` — `m3/text.color`,
  `m3/surface.containerColor`, `m3/icon.color`. A theme role is a `colorToken`
  (`{"type": "colorToken", "value": "outlineVariant"}`), which is the better
  choice when you want the design to follow the theme.
- **A dimension is a `float`**, in dp, and the property name says so
  (`sizeDp`, `verticalSpacingDp`, `shapeDp`).

**Edits name the node by id.** Besides `insertNode`, the operations an edit
loop uses are these (all verified against 3.121.0):

```json
{"type": "setProperty", "nodeId": "signin", "property": "style",
 "value": {"type": "enum", "value": "filledTonal"}}
{"type": "setProperty", "nodeId": "title", "property": "style", "value": {"type": "null"}}
{"type": "removeNodeProperty", "nodeId": "title", "property": "style"}
{"type": "deleteNode", "nodeId": "email"}
{"type": "moveNode", "nodeId": "title",
 "location": {"parent": {"nodeId": "col", "slot": "children"}, "afterNodeId": "signin"}}
```

- `setProperty` sets one property and leaves the others alone. Its `value` is
  wrapped like an inserted one.
- A `{"type": "null"}` value, or `removeNodeProperty`, unsets a property: the
  way back after trying one. Unsetting a required property (`m3/button`'s
  `style`) is refused, naming the node and the field.
- `deleteNode` removes the node and everything in its slots.
- `moveNode` takes the same `location` as an insert.

To swap a component for another (a filled field for an outlined one), do it in
one `apply` call: insert the new node next to the old one, `moveNode` each child
you want to keep into the new node's slots, then `deleteNode` the old one.
Deleting first loses the label, icons and anything else in its slots. To try a
batch first, pass the same `operations` to `ui_builder_check_design` with
`designId` and `baseRevision`: it applies them to a scratch copy and saves
nothing.

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
  design, not a formatting step — but it is not a compile. The gate checks that
  each call has a record, not that the target classpath carries it: an icon key
  such as `pauseCircle` exports `Icons.Filled.PauseCircle`, which only
  `material-icons-extended` ships, with no diagnostic at all. Where it is
  advertised, `ui_builder_render_native` is the compile check: a
  `compileError` there (`Unresolved reference 'PauseCircle'`) is a real failure
  of the Kotlin, so fix it before handing the code over, or name the dependency
  it needs.
- **The design is the deliverable** — a mockup, a PNG, a screen a designer takes
  over → use whatever the catalog offers and read the diagnostics as a note about
  the generator rather than a problem with your design.
- **Server-driven UI is the deliverable** → on an A2UI-capable catalog pin,
  call `ui_builder_export` with `format: "json"` and read its diagnostics.
  Verify visuals separately with `format: "png"` or advertised native render;
  the viewer does not render A2UI. Return a `resource_link` only when supplied,
  and do not treat another JSON format as equivalent.
