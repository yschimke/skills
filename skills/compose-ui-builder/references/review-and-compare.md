# Seeing, comparing and reviewing a design

Part of the [compose-ui-builder skill](../SKILL.md).

## Seeing what you built

- **`ui_builder_view`** — the editor canvas as a person sees it: overlays
  (`include`, for example `["reference"]`), `selection`, a past `revision`, and
  `renderer: "native"` where the host compiles. It returns a short-lived https
  link; `inline: true` adds the image to the reply. Where it is not advertised,
  say so; an export is not the editor view.
- **`ui_builder_render_design_matrix`** — one contact sheet of the design on
  several devices × themes × font scales, captioned per cell, from one call.
  Nothing is saved. Use it before calling a screen done: the compact frame and
  `fontScales: [1, 2]` are where layouts break.
- **`ui_builder_export` `format: "compose"`** — the generated Kotlin, plus
  `diagnostics` naming anything the generator refused. Empty diagnostics is the
  gate a designer sees in the browser's code pane, so it is a real check on the
  design, not just a formatting step.
- **`format: "png"`** (or `"svg"`) — base64 in `artifact.content`, a few KB for a
  simple screen and a reliable view of the rendered document. It does not show
  the editor viewport, selection, reference overlay, or comment pins. Needs the
  server on Java 21+; a host without it says so.
- **`ui_builder_render_native`** compiles the design with real Compose on the
  host and reports where each node drew (`nodeBounds`, `taggedNodeIds`). It is a
  compile, so it takes minutes and only exists where the host can run one — reach
  for it when you need the ground truth about layout, and `export png` for the
  ordinary "does this look right" loop. When Kotlin is the deliverable, run it
  once before handing over: it is the only tool that proves the export compiles.
  An empty `nodeBounds` with a `compileError` means the code did not build, and
  the overlay tools (`ui_builder_view` outlines) have nothing to draw.

**A Wear widget is not a watch screen.** A `remote-m3` design whose root is a
`remote-m3/widget-container-*` is shown by the launcher inside a widget frame,
not across a full round display. Do not judge it on the matrix's Wear presets
(`wear_small_round`, `wear_large_round`): they draw the 216×76 dp widget as a
band across a watch face, which is not how anyone sees it. Instead:

- Pass widget-sized `devices` to `ui_builder_render_design_matrix` — the
  container's own size (216×76 dp small, 216×124 dp large) as
  `{"widthDp": 216, "heightDp": 76, "label": "small widget"}` — with the font
  scales below.
- The host shapes the export targets are the Samsung round frame
  (`RoundSmallWidgetPreviewParams`), the Pixel Watch squircle
  (`SquircleSmallWidgetPreviewParams`) and the rectangular one
  (`RectangularSmallWidgetPreviewParams`), plus their large variants. The
  guidelines pictures (`ui_builder_guidelines_prompt`, `check_design` with
  `rendered: true`) are drawn in the Samsung and Pixel Watch frames; ask for
  those when you need to see the clip a frame imposes.
- A Wear **app** screen (`wear-m3`) is the opposite case: cover the small round
  device and the largest font scale.

**Render the large font scale yourself.** `ui_builder_check_design`'s
accessibility pass reasons from declared sizes and, with `rendered: true`,
measured touch targets; it does not see a line that wraps and pushes its
siblings out of a fixed 76 dp frame. Draw the design at the large scale (1.24×
for a Wear widget, 1.5× for a mobile one, 2× only when asked — at 2× a widget
clips so widely the findings bury everything else) and look at the picture
before calling it done. A widget whose brand line wraps at 1.5× and pushes the
title out of the frame passed both the accessibility check and
`wear.layout.no-clipping`.
- **The browser URL** — `https://<host>/ui-builder/<catalogSystemId>/<designId>`
  — is what you hand a person. Always give them this rather than describing the
  design.

## Compare with a reference

A reference is the picture a design is built against — a Figma frame, a
screenshot of a shipped screen, a mock. It is kept **beside** the design, not in
it: no node holds it, no export sees it, the revision does not move. That is
different from an `asset/image` node, and `ui_builder_put_asset` does not attach
one.

### Over MCP

Check `tools/list` for `ui_builder_set_reference` and
`ui_builder_compare_reference`. They need a compose-preview-server release that
carries them and a host that keeps reference overlays; when they are absent,
use the browser route below and say that the MCP lacks them.

1. **Get the picture.** From Figma, use your Figma tools to take a screenshot of
   the frame (the node the user linked) and note its export scale; from a file
   or an attachment, read the bytes. Never invent or redraw a reference.
2. **Ask before uploading.** The reference is stored on the remote host. A
   request to *look at* an attachment is not permission to upload it: say where
   it will be stored and get an explicit yes. Never print its base64.
3. **Attach it:** `ui_builder_set_reference` with `designId`, `imageBase64`,
   `density` (pixels per dp — 2 for a Figma 2x export, 2.625 for a Pixel
   screenshot) and `sourceUrl` (the Figma frame link, kept as provenance). Also
   record the frame with `ui_builder_set_links` (`reference`).
4. **Read the facts** in the reply before changing anything: the picture's size
   in dp, where its density came from, whether it is a `screen`, a `tallScreen`,
   or a `region` (a component crop), and `pixelComparable`. A region is only
   comparable at its `actual` size, and a picture of another shape is compared
   by eye only — say so rather than "fixing" what a misplaced picture shows.
5. **Measure:** `ui_builder_compare_reference` with `differences` reports the
   share of pixels that differ and up to eight regions in dp, each with the
   layer it falls in. Add `nodeIds` for the layers you want to line up: each
   comes back with where it sits in the reference, the `alignment` (move, size,
   font size) and the exact `operations` for `ui_builder_apply`. Matching layers
   needs the native render, which needs the `ui-builder-export` grant **and** a
   host that compiles the pinned catalog. `renderer` defaults to `native`
   whenever `nodeIds` is given, so on a host without one (`NO_NATIVE_CATALOG`;
   preview.coo.ee has none for `m3-catalog` as of 3.121.0) the call fails, and
   with `renderer: "export"` each layer comes back with no operations. There,
   measure with `differences` alone (it uses the PNG export), read the regions
   and their layers, write the alignment yourself, and say that layer matching
   was not available.
6. **Apply what you agree with** through `ui_builder_apply` (quote the current
   `baseRevision`), one layer or a few at a time so collaborators see progress,
   then compare again — a layer that lines up reports `alreadyAligned` — and
   look with `ui_builder_view` (`include: ["reference"]`). Treat
   `confident: false` as a hint to check, not an edit to make; when the words or
   content differ from the mock, ask the person to draw a box round the target
   in the editor (a box mark is the strongest evidence) and compare again.

Report what you changed in dp and sp ("title moved right 12 dp, font size 22 →
28 sp") and what still differs. Do not chase the last pixels of anti-aliasing,
a different font rendering, or a status bar the mock includes.

The CLI spellings are `compose-preview-server design reference <designId>
--attach <picture> [--density <n>] [--source-url <url>]` (or `--clear`) and
`design compare <designId> [--node <id>] [--fit contain|width|actual]`.

### In the browser

Open the design URL and select **Frame, density and reference** in the right
inspector rail. **Import…** a file, paste an image, **Snapshot** the design, or
fetch a link (a Figma frame link works on the desktop app with `FIGMA_TOKEN`;
on the web, copy the frame as PNG in Figma and paste it). The panel shows the
picture's size, density and kind, and the fit (**Fit**, **Fit width**, **Actual
size**) that lines it up. Choose the view that answers the current question:

- **Overlay** for alignment at an adjustable opacity.
- **Difference** to make matching pixels recede and expose mismatches (offered
  only when the picture lands dp for dp).
- **Split** for a movable before/after wipe.
- **Boxes** for layout guides extracted from a compatible SVG.

**Measure → Differences** outlines where the design differs; select a layer and
**Match** to get the same move/size/font-size proposal as the MCP tool, with
**Apply** writing it as one undoable edit. The same panel supports markup,
component pieces, erasing, promotion of captured catalog components, and
**Flatten**. The feature and its storage boundary are documented in
[`UI_BUILDER_REFERENCE_OVERLAY.md`](https://github.com/yschimke/compose-ui-builder/blob/main/docs/design/UI_BUILDER_REFERENCE_OVERLAY.md).

For a UI-builder-shell reference, explicitly account for the top command bar
(undo/redo, Design/Preview, code, share, renderer, new and overflow), both
action rails, the surface/properties bar, zoom/fit controls, and the bottom
revision/node/live status. Do not call the reference complete while those
controls are absent merely because the central canvas resembles the target.

## Review design guidelines

When asked to review a design, follow the shared
[catalog guidelines checklist](../../compose-preview/references/design-guidelines.md).
It ships beside this skill in the default skill pair and works without a reviewer
agent or an OpenRouter key. Use advertised `ui_builder_guidelines_prompt`,
`ui_builder_get_guidelines` and `ui_builder_record_guidelines` tools; preserve
the prompt's revision and rules version, inspect its required pictures and
report unanswered rules. Recording a requested review is metadata at the home,
not an edit to nodes or a human approval. Keep model warnings advisory and
measured schema/accessibility checks separate.

**Working with platform skills.** When an official platform skill is loaded
(for example Android's Wear Compose Material 3 skill), it decides which
components and APIs are right. The builder's catalog decides what a design can
contain today. If they disagree, say so rather than picking silently. A catalog
renders one fixed library version, which may differ from the project that will
receive the exported Kotlin.

Return the canonical editor link and tell the person its **Issues** panel
shows a successfully recorded shared guideline result, its model and revision
freshness. Also return the compact verdict and coverage in chat. If recording
is unavailable, make that explicit and keep detailed findings at the design's
existing discussion home when authorized. Link to that discussion from chat;
never imply the panel contains an unsaved review or invent an audit-launch link.
