---
name: compose-ui-builder
description: Design or edit a screen or Wear widget in the Compose UI Builder over MCP. Use only for a UI Builder URL (…/ui-builder/…), a .uid design file, or an explicit request to design or author a screen or Wear widget in the UI Builder, explore design alternatives, or turn an approved builder design into Compose code.
---

# Compose UI Builder

The UI builder is an authoring surface served by `compose-preview serve`: a
design is a **document of catalog components**, edited by an operation log, and
exported as Compose Kotlin (or PNG/SVG). A person edits it in the browser at
`/ui-builder/<catalog>/<designId>`; you edit the same live document over the
server's MCP endpoint. Both land in one revision log, so you and a designer can
work on the same design at the same time.

A design can also live in a checked-in `.uid` file. For a repository design,
inspect its schema and follow [the local design-to-code workflow](references/local-design-to-code.md):
edit the canonical file, compare real design renders with references, adapt
exported Kotlin into the application, then render the affected `@Preview`s.
Use `compose-preview` alongside this skill when a composable already exists.

The server ships from
[compose-preview-server](https://github.com/yschimke/compose-preview-server);
people start at <https://ui.coo.ee/start> (longer guide:
[`docs/UI_BUILDER_GETTING_STARTED.md`](https://github.com/yschimke/compose-preview-server/blob/main/docs/UI_BUILDER_GETTING_STARTED.md)).
The public host's MCP endpoint is `https://preview.coo.ee/mcp`: configure only
that URL ([mcp.md § Which MCP server](../compose-preview/references/mcp.md#which-mcp-server)).

## Firm collaboration contract

These rules apply before the creation and editing recipes below:

1. **Work at the recorded home.** For an existing server design, start with
   `ui_builder_get_design` and read its `home`. For a checked-in `.uid`, read
   the file and its recorded home first; a server lookup is not required. A server-homed design is edited
   on that server; a repo-homed design is edited at its recorded `.uid` path.
   Do not export a server design, edit the copy locally, and re-import it.
   Servers record `home` since compose-preview-server v3.76.0; if the response
   has none (an older host, or a design created before then), say that the
   canonical home cannot be verified. Do not infer or rewrite it.
2. **Keep discussion at the home.** For a server-homed design, call
   `ui_builder_list_comments` before the first edit, reply and resolve there,
   and check again before finishing. For a repo-homed design, use its linked PR
   or issue. Link to that discussion with `ui_builder_set_links`; do not split
   it across chat, an issue, and server comments.
3. **Use typed operations and validation.** Prefer `ui_builder_apply` and the
   tool schemas over editing document JSON. Call `ui_builder_check_design`
   (which runs `ui_builder_validate` plus accessibility checks) before showing
   or finishing, or `ui_builder_validate` on a host that has only that. If
   validation or a required schema is not available, say so; an export
   diagnostic is useful but is not a substitute for document validation. If hand-editing is unavoidable,
   validate before saving and render again afterwards.
4. **See the editor after each visible step.** Call `ui_builder_view`
   (compose-preview-server v3.89.0 and later): it draws the canvas as a person
   sees it, with selection, reference overlay and comment pins. On a host that
   does not advertise it, inspect PNG/SVG or native output, label it as not the
   editor viewport, give the browser URL, and never infer selection, overlays,
   or comment pins from JSON or an export.
5. **Close temporary copies.** A local copy may be used for a compile check or
   offline experiment only. Announce its path and purpose, keep its recorded
   home pointing at the canonical design, and save the result back to that home
   or discard the copy before finishing. Moving a design between server and
   repo homes requires explicit approval.

Before finishing, run `ui_builder_check_design`, look at the final editor view
and the device grid, and check for unread or unacknowledged comments at the
design's home. Hand back the link, the revision and whether a person has
approved it ([Approval and handoff to code](references/collaboration.md#approval-and-handoff-to-code)).
Report any capability that prevented one of those checks.

## Viewer, prompts, and interactive decisions

The MCP Apps viewer, prompts and elicitation depend on the host as much as on
the server. Discover them from `tools/list` and the client's capabilities, and
use the text fallbacks in the
[catalog MCP reference](../compose-preview/references/catalog-mcp.md#draft-viewer-and-interactive-capability-fallbacks)
when they are absent.

## Core creation loop

This compact example shows the core creation calls; the home, comment,
validation, and editor-view checks above still apply:

```jsonc
// 1. request_access  — capabilities, not scope (see "Getting in")
{"capabilities": ["ui-builder-read", "ui-builder-write", "ui-builder-export"],
 "ttlSeconds": 14400,
 "label": "add a header row to the settings screen"}
// → show approveUrl + userCode to your human, then poll_access

// 2. ui_builder_create_design — a whole document; the starter below is known-good
{"designId": "settings-v2", "document": { …see references/documents-and-vocabulary.md… }}

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

// 4. ui_builder_check_design — schema, catalog/export gate and accessibility in one
{"designId": "settings-v2"}
// → {"summary": "…", "ok": false, "findings": [{"nodeId": "title", …}]}  ← fix with apply
//   pass "operations" (+ "baseRevision") instead to dry-run a batch before applying it
//   a `skipped` reason of "no native render was available" may hide a failed
//   compile on older hosts: call ui_builder_render_native to find out

// 5. ui_builder_render_design_matrix — every device the screen claims, one picture
{"designId": "settings-v2", "themes": ["light", "dark"], "fontScales": [1, 2]}

// 6. ui_builder_export — the Kotlin, or diagnostics saying why not
{"designId": "settings-v2", "format": "compose"}

// 7. tell your human where it is
// https://<host>/ui-builder/<catalogSystemId>/settings-v2
```

Read each reply's `summary` first; it is written to be enough on its own. Step 4
replaces a separate validate and accessibility pass, though not the editor
view: run it before you show a design to anybody, and fix its findings by `nodeId` through
`ui_builder_apply`. The device grid in step 5 is where a navigation rail that
never collapses, or text that clips at 200% font scale, shows up. Look at it
before calling the screen done.

Send that browser URL as soon as the design exists, then keep sending the
current revision, what just changed, the comment state, and the next action.
Do not make a person infer progress from a silent series of MCP calls. A useful
update is: “Desktop reference is at revision 4; the header and rails are in;
there are no open comments; next I am comparing it with the attached reference.”

Before creating or editing anything, orient yourself:

1. Look for an existing design or checked-in fixture with the requested name.
   Call `ui_builder_get_design`, read its recorded home and links, and read the
   discussion at that home before deciding to edit or create. Do not copy an
   existing design merely to avoid working at its home.
2. Open the canonical path URL returned by the design identity:
   `https://<host>/ui-builder/<catalogSystemId>/<designId>`. Do not invent an
   old query-string URL; the path carries both the catalog and design.
3. If the request names or attaches a visual reference, check whether one is
   already attached (`ui_builder_compare_reference`, or **Frame, density and
   reference** in the browser).
   The full reference workflow is under [Compare with a reference](references/review-and-compare.md#compare-with-a-reference).
4. Report the link, revision, open-comment count, and the first planned part
   before editing. This is the point where the person can correct the target
   while the correction is still cheap.

## Getting in

The `ui_builder_*` tools are gated on **capabilities** — `ui-builder-read`,
`ui-builder-write`, `ui-builder-export` — *not* implied by the
`preview` / `live` / `playground` scope ladder. The handshake is the ordinary agent-grant one
([server-access.md](../compose-preview/references/server-access.md),
[catalog-mcp.md](../compose-preview/references/catalog-mcp.md)), plus:

- **Ask for all three capabilities at once**, and `preview` scope, which costs
  nothing.
- **Ask for enough time once**: `ttlSeconds: 14400` when the task includes
  reference comparison or live feedback.
- **Pass the token as each tool's `token` argument**; a token approved
  mid-session cannot become a header.
- **Make the approve link one click**: the `userCode` on one line, the bare
  `approveUrl` on its own line below it.
- **Collect approval in the background**: call `poll_access` every
  `pollIntervalSeconds` until approved, denied, expired or unknown. Never spin,
  and never make the person come back and say “done”.

Grants live in memory: a redeploy drops yours mid-task. Ask again the same way.
The full flow is in [access-and-editing.md § Getting in](references/access-and-editing.md#getting-in).

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
- **A rejection is a normal reply, not an error**: `rejected`, with a `code`,
  `nodeId` and `field` precise enough to fix without a re-read.

Drive from `apply`, not snapshots, one part of the screen per call (shell,
header, list, footer). After each part, do the contract's visual check and read
the comments. Detail and the common rejections:
[access-and-editing.md § The edit loop](references/access-and-editing.md#the-edit-loop).

## Reference index

Read only what the task needs.

| Task | Read |
|---|---|
| What to insert: ids, slots, required properties, enums. **Read these rather than calling `ui_builder_list_catalogs`**, the authority when something is missing | [m3-catalog.md](references/m3-catalog.md), [wear-m3-catalog.md](references/wear-m3-catalog.md) (Wear app), [remote-m3-catalog.md](references/remote-m3-catalog.md) (Wear widget) |
| A checked-in `.uid` design, implemented in the app | [local-design-to-code.md](references/local-design-to-code.md) |
| No host: run `ui-builder --no-project`, attach MCP, shell verbs | [local-host.md](references/local-host.md) |
| Known-good starter documents, the vocabulary, export as a check | [documents-and-vocabulary.md](references/documents-and-vocabulary.md) |
| Full grant flow, edit-loop detail, Material and gap-reporting habits | [access-and-editing.md](references/access-and-editing.md) |
| Look at the design, compare with a reference, review design guidelines | [review-and-compare.md](references/review-and-compare.md) |
| Comments and a designer, branches, approval and handoff to code, keeping a design | [collaboration.md](references/collaboration.md) |
| Something behaves oddly | [gotchas.md](references/gotchas.md) |
