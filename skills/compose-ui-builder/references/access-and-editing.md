# Getting in and the edit loop, in full

Part of the [compose-ui-builder skill](../SKILL.md); its core keeps a short
version of the first two sections.

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
[server-access.md](../../compose-preview/references/server-access.md) and
[catalog-mcp.md](../../compose-preview/references/catalog-mcp.md) in the
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
- **Make the approve link one click.** Put the `approveUrl` on a line of its
  own, as a bare URL (and as a link card where the host can show one), with the
  `userCode` on the line above — never only inside a sentence, where a person has to
  ask for it again:

  ```
  Approve access (code <userCode>):
  https://<host>/agent-access/<request-id>
  ```
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

After each accepted part, perform the available visual check described in the
[collaboration contract](../SKILL.md#firm-collaboration-contract). State when the editor-view tool is absent, and do not
replace it with an inference from document JSON. Check server comments at the
same boundary so feedback lands before the next part.

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
