# Working with a person, branches, approval and keeping a design

Part of the [compose-ui-builder skill](../SKILL.md).

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

## Explore alternatives on branches

When the person wants options ("try a compact and a roomy header"), or you would
otherwise edit over somebody working live, branch rather than copy:

1. **Branch once per idea from the same revision.** Note the parent's current
   revision once, then call `ui_builder_branch_design` with `designId`, that
   `revision` (so an edit landing between calls cannot give the alternatives
   different baselines), a `name` that says what the alternative is, and your
   own `branchId` so a retry is idempotent. A branch is a design with its own id:
   edit it with `ui_builder_apply` exactly as in
   [the edit loop](../SKILL.md#the-edit-loop). Branches of a branch are
   refused.
2. **Show them side by side in one picture.** `ui_builder_compare_branches`
   renders the parent's head and each open branch into one numbered contact
   sheet (a short-lived https link) with what each changes. Post the picture
   and the numbered list; never describe the alternatives from their JSON.
3. **Let the person choose.** `ui_builder_pick_branch` shows a picker or form
   where the host has one. If it returns `ask-in-chat`, post its list and
   picture and wait for their number. Never pick for them, and treat `declined`
   as an answer.
4. **Merge the choice.** `ui_builder_merge_branch` with `dryRun: true` first,
   read the per-command report, then merge. Its open siblings are archived for
   you; `ui_builder_archive_branch` drops one without merging.

## Approval and handoff to code

A design is done when a person approves a revision, not when you stop editing.
The record lives beside the design, so the coding agent can pick it up later
without the chat.

- **Wait for approval instead of asking again.** Tell the person the link and
  revision, then `ui_builder_await_decision` with `designId`, that `revision`
  and the `afterSequence` you last saw (0 the first time). Without `revision`
  a verdict on an older revision would answer the wait. It returns when a
  *person* approves or rejects that revision, or `timedOut` after
  `waitSeconds`. If you edit after asking, the person is looking at a new
  revision: say so and wait on that one. `waitSeconds: 0` is a
  cheap poll for a routine that checks back later. Quote the reply's `sequence`
  next time. Your own `ui_builder_record_decision` is recorded as an agent's
  and does not answer a person's wait; never record an approval on their
  behalf.
- **Link the implementation.** When code lands, `ui_builder_set_implementation`
  with the PR URL, its `status` and the design `revision` it implements. After
  you have rendered the PR's `@Preview`s and compared them with the design, add
  `previewMatch` (`match`, `mismatch` or `unknown`, with an evidence link). It
  replaces the whole record.
- **Start the code side from the design.** In a coding session,
  `ui_builder_implementation_status` returns in one call the revision, its links,
  the implementation PR and whether its previews matched, the latest verdict, and
  the Compose export with its diagnostics. From a PR,
  `ui_builder_find_design_for_pr` finds the designs it implements. Implement the
  approved revision, not whatever the design holds now: if `summary` says the
  revision moved on or was never approved, say so before writing code.

## Keeping a design

A server-homed design remains canonical on its recorded server. The server repo
ships `scripts/ui-builder/design-sync.mjs`, which can make an operations fixture
for a compile check, review artifact, or explicitly approved move to a repo:

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

Exporting this fixture does not move the design's home. Announce the temporary
copy and either apply its result back at the recorded home or discard it before
finishing. Changing the canonical home to the repo is a separate action that
requires the person's explicit approval and updates the recorded home rather
than silently creating two authoritative designs.
