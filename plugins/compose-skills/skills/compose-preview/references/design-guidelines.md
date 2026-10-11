# Review catalog design guidelines

Use this checklist when asked to review a Compose preview, catalog render or
UI Builder design against Android design guidance. It runs in the current
context when no reviewer agent is available. A simple request to show a
component does not need this review.

Rules belong to the catalog's `ui-builder.guidelines.json`; do not copy a list
of Wear or Material rules into a skill or invent rules when none are published.
Read the request's rule IDs, checks, sources, version, surface and pictures.
The returned schema is authoritative: preview and UI Builder verdicts have
different shapes. Discover tools and their schemas before choosing a lane;
availability depends on the server version, deployment and access grant.
The `catalog_` names below identify the hosted lane; some clients expose those
as `list_data_products`, `get_preview_data` and so on on their catalog server.
Use the exact names the active client advertises.

## Choose the review lane

For a published catalog or server-homed design, use the advertised hosted tools
first. Resolve the named catalog through `catalog_list_projects` and
`catalog_list_previews`, or the supplied design ID through `ui_builder_get_design`.
A catalog name is not a request to clone its repository. No checkout, local
Gradle bootstrap, cloud environment or workspace proxy is needed for this lane.
Fetch source only when the requested review requires evidence the hosted tools
cannot supply, or the person explicitly requests a source change.

If a connection fails before a server tool response, stop retries, report
blocked evidence and follow the integration's setup/recovery guidance. Do not
infer an expired server grant from a network/proxy error or silently switch to
local builds. Use advertised server access tools for a reachable server's
structured `authorization_required` response. Resume when tools are available;
never claim an audit ran without evidence.

| Subject | First read | Review with |
| --- | --- | --- |
| UI Builder design | `ui_builder_get_design`, its home and revision, then `ui_builder_get_guidelines` when advertised | `ui_builder_guidelines_prompt`, judged with your own model; record through `ui_builder_record_guidelines` where allowed |
| Local `@Preview`s | Existing `build/compose-previews/guidelines.json` and applicable catalog rules, if present | `preview_guidelines_prompt` on the local server, with explicit `surface` and a batch of `previews` |
| Hosted catalog preview | `catalog_list_data_products`, then `catalog_get_preview_data` with `kind: "guidelines/result"` when listed | Inspect the published result and its render; use only review/render tools that this host advertises |
| CLI without preview MCP | `compose-preview --help`, the module's rules and existing report | [`compose-preview review`](#cli-the-review-loop), judged with your own model; `compose-preview guidelines` only for a requested provider run with a key |

Keep detailed discussion at the recorded home: server comments for a
server-homed design, its linked PR or issue for a repo-homed design. Publishing
discussion still requires the task's authorization. A plain preview has no
design home; return its findings directly when no review destination is given.

### UI Builder: keyless review and shared results

1. Run `ui_builder_check_design` for the advertised schema, catalog and
   accessibility checks. These are separate from model guideline judgments.
2. Reuse a guidelines result only when it covers the requested checks, matches
   the reviewed revision and rules, and is not stale. An empty findings list
   alone proves neither coverage nor freshness.
3. Otherwise request `ui_builder_guidelines_prompt` with `designId` and the
   reviewed `revision`. Its default rendered lane includes native pictures and
   exported Compose source. Inspect those pictures. With read-only access or no
   renderer, use `rendered: false` if supported and label the review partial:
   that lane omits pictures, source and visual rules.
4. Answer the request's yes/no checks from the supplied evidence. YES is
   `pass`; NO is `fail`; `not_applicable` is for a rule whose condition does
   not apply, never for a missing picture or unknown fact. For a rule you
   cannot judge, leave its verdict out and list it as unchecked.
5. Where the task authorizes recording review results at a server home and
   write access exists, call `ui_builder_record_guidelines` with the prompt's
   `revision`, `rulesVersion` (`rules.version`), all `asked` rule IDs
   (`rules.asked[].id`), the actual judging `model`, and the verdicts. Cite
   supplied `nodeIds` and a short reason; do not fabricate model identity or
   confidence. Missing verdicts must remain visible as unanswered rules.
   This replaces the latest review record, not the design document. It is not
   a human approval. Never call `ui_builder_record_decision` just because
   guidelines passed.
6. Read the recording response's freshness and recheck the current revision
   before finishing. If a collaborator edited during review, report the
   reviewed revision as stale or review the new one; never relabel old answers
   with a newer revision. At a repo home or without a record tool/write grant,
   return the result at the existing review destination and explain why the
   editor's shared result was not updated.

An explicitly requested provider run can instead use
`ui_builder_check_design` with `checks: ["guidelines"]` and `rendered: true`,
but only if its advertised schema accepts that check and the operator enables
the account. Read `skipped`; the absence of a model key is not a clean review.

### Local previews: select rules and surface explicitly

Use the module's discovered `build/compose-previews/ui-builder.guidelines.json`
or pass `guidelines` with the project's chosen catalog file or URL. An app
that does not publish a catalog can use the appropriate upstream catalog's
published rules explicitly; identify that source in the report. Do not silently
substitute another platform's rules or create a catalog file in the app.

Pass `surface: "screen"` for screens, `"widget"` for widget hosts and
`"component"` for isolated component stickers. The preview MCP currently
defaults to `component`; the CLI infers screen from a declared preview device.
Set it explicitly in either lane when reviewing screens so screen-only Wear
rules are not silently filtered out. Batch related previews with the same
surface and rules; separate batches for different surfaces or catalogs.

`preview_guidelines_prompt` spends no provider key. Judge every asked rule for
every subject using the response schema, preserving subject IDs, node IDs and
picture indices. If more evidence is needed, fetch it through advertised
render/data tools and cite it; keep undecidable rules unchecked rather than
passing them. Do not send preview verdicts to `ui_builder_record_guidelines`:
that tool records UI Builder design verdicts, not preview results.

### CLI: the review loop

`compose-preview review` (compose-preview 2.46.0 and later; check
`compose-preview help --all`) is the CLI's keyless lane. It renders the
selection, batches it and writes each request a model would be sent to a file,
so you judge it with your own model. It takes the same selection as `render`
and `show` (`--module`, `--filter`, `--id`, `--changed-only`, `--id-file`) and
the same `--surface` and `--guidelines` as `guidelines`:

```sh
compose-preview review --filter ListScreenPreview --surface screen \
  --guidelines path/to/ui-builder.guidelines.json --annotate
```

**Check who judges.** `review` defaults to `--backend auto` and prints its
choice and reason on stderr, as `review: backend <name> (<reason>)`. When it
recognises an agent session it picks `prompt`, the loop below. If that line
says `openrouter` or `openai`, a provider is judging on the person's key and
there are no requests for you to answer. To judge the review yourself, pass
`--backend prompt`. Pass `--backend openrouter` or `--backend openai` only for
a provider run the person asked for ([below](#provider-runs-and-the-key)).

In prompt mode, run it, then repeat until it exits `0`:

1. **Exit `3`: requests are waiting.** It lists each
   `build/compose-previews/review/<id>/request.md`. Exit `3` here means waiting
   for replies, not "no previews" as it does for `render` and `show`.
2. **Answer each request.** Read its instructions, request and rules, look at
   every picture it lists (`picture-N.png` beside it), and write only the JSON
   reply its schema asks for to `reply.json` in the same directory. Keep its
   subject ids (`s1`), picture numbers and the node ids it supplies. List only
   rules that do not pass, then the `others` entry per subject (and one with
   `subjectId: null` for set rules) that the request asks for. A rule with
   neither is reported unchecked.
3. **Ask for evidence, don't fetch it.** When a rule needs accessibility
   data, source or another render and the request lists that kind as
   available, answer `needs_evidence` with it in `needs`. The next run fetches
   it and writes a follow-up request carrying it, for that preview and rule
   only. Judging touch targets or contrast by eye when `a11y` is offered is the
   mistake this avoids.
4. **Run the same command again.** Each `request.md` names it. The run reads
   the replies through the same checks as a model's, writes any follow-ups,
   and exits `3` again until every rule is decided or left unchecked.

With several requests, hand each to a subagent with only its `request.md`
path; it reads the pictures and writes `reply.json`, so the renders stay out
of your context. Keep the selection and flags identical between runs: requests
are named by a hash of what they ask, so a different selection makes new ones
and the old replies are not read. Do not edit `request.md`, the pictures, the
cache under `build/compose-previews/guidelines/` or `guidelines.json` by hand.
An unreadable reply is reported as a failed request (exit `2`) with the
reason; rewrite that `reply.json` and run again.

When it exits `0` the result is in `build/compose-previews/guidelines.json`
(and `*.guidelines.png` with `--annotate`), recorded with the model `agent`
(`--model` names yours). Report it as below. Exit `1` means findings at
`--fail-on`; exit `2` a failed request or build. A module without catalog rules
reports that and asks nothing.

### Provider runs and the key

For a requested provider run, `check_preview_guidelines` reads
`COMPOSE_PREVIEW_OPENROUTER_KEY` from the server environment and accepts
`max_cost` (USD). The CLI equivalent, with an existing key and an agreed budget,
is `guidelines`, or `review --backend openrouter` (capped at $0.25 unless
`--max-cost` says otherwise):

```sh
compose-preview guidelines --filter ListScreenPreview --surface screen \
  --guidelines path/to/ui-builder.guidelines.json --json --annotate --max-cost 0.10
```

`compose-preview guidelines models` lists the OpenRouter `--model` ids that
read pictures and keep to a reply schema, cheapest first, with prices per
million tokens. It needs no key.

For an OpenAI-compatible endpoint the person names, such as OpenAI, Gemini's
OpenAI endpoint, a local Ollama or LM Studio, or a LiteLLM proxy, use
`--backend openai` with the base URL (version path included) and the
endpoint's own model id:

```sh
compose-preview review --backend openai --base-url http://localhost:11434/v1 \
  --model llava:13b --filter ListScreenPreview --surface screen
```

Its key comes from `COMPOSE_PREVIEW_MODEL_KEY`, else the one the person stored
for that endpoint with `compose-preview guidelines key set --for <base-url>`.
A localhost endpoint needs none. Such an endpoint reports no cost, so
`--max-cost` cannot stop the run: narrow the selection instead. It has no
`--checker jev`.

The CLI writes `build/compose-previews/guidelines.json` and optional
`*.guidelines.png` overlays. Results are cached per backend, so a verdict from
one endpoint never answers for another. The OpenRouter key comes from
`COMPOSE_PREVIEW_OPENROUTER_KEY`, else from the person's credentials file,
which they fill with `compose-preview guidelines key set` in their own
terminal. A stored key, OpenRouter's or an endpoint's, is used only for a
project they trusted, at the terminal prompt or with
`compose-preview guidelines key trust <dir>`. Without a terminal the CLI
refuses and names that command and the variable that would work instead:
relay them to the person. Never run `key set` or `key trust` for them, read
the credentials file, or pass, print or write a key yourself.
`compose-preview guidelines key status` (with `--for <base-url>` for an
endpoint) shows where a key comes from without revealing it.
Do not invoke a second provider just to review when the agent can judge the
keyless prompt or `review`. Without a key or guidelines tools, inspect source, measured
accessibility results and real PNGs with the published rules and report the
manual coverage. Missing rules or an unreadable report mean unavailable, not
passed. Do not hand-edit a cached report to simulate a provider run.

### Hosted results

Read `guidelines/result` only when the catalog lists it. This is an existing
published check, not a new live review. Preserve its actual model, rule version,
render identity and any pending or unchecked status. Verify freshness against
the reviewed render where metadata permits it; otherwise report freshness as
unverified. Do not apply a published snapshot's result to an override render.
If no result exists, obtain the catalog's rules and real renders through
advertised tools and judge them yourself. State missing source, measurements
or views. Do not require a local Gradle checkout for a hosted catalog review.

## Evidence and pictures

Follow the catalog's frame plan and each rule's named view, not a generic
device sweep. In the current catalog guidance:

- Wear screens need the first device frame and, when scrolling, an unrolled
  view. Content outside the viewport along a scrollable axis is not proof of
  clipping; an edge button revealed at the end is not missing from the screen.
- Mobile adaptive rules compare a compact phone (412×915dp) and expanded tablet
  (1280×800dp). One stretched render cannot establish adaptive behavior.
- Widget rules use their declared host containers rather than screen rules.

The local preview prompt currently supplies one picture per subject; do not
assume it executed the catalog's entire frame plan. Request missing views with
advertised device/matrix/scroll render tools. Identify matching content across
frames; unrelated previews are not evidence of adaptation. If a necessary view
cannot be obtained, mark the dependent rules unchecked. A hash proves a render
changed, not whether it follows a visual rule: inspect the relevant pixels.

Use source and wrapper/callee evidence for code rules. A preview body that
delegates to a scaffold wrapper cannot prove the scaffold is absent. Prefer
measured touch-target, contrast and large-font clipping results over a model's
picture estimates, while preserving their measurement limitations. When
source or measurements cannot establish a structure rule, report it unchecked.

## Show the review and offer another run

Always return a compact review in chat, including when an MCP App or shared
editor shows the same result. Name the reviewed subject and revision/render,
verdict, answered/asked and unchecked counts, model, freshness and where the
result is saved. For subjects without a recorded home, show important findings with their
rule IDs and evidence links. For a design with a home, keep detailed findings
and discussion at that home when publishing is authorized: server comments
for a server home, its linked PR or issue for a repo home. In chat, return
the compact verdict, coverage and home/thread links instead of repeating the
findings. If access prevents publishing, report that limitation and the
intended destination; do not move the design discussion to chat. A viewer being open, an audit request being sent, or empty findings
without coverage does not mean the review passed.

For a requested accessibility or layout audit, prefer one `render_preview`
call with `details: ["a11y", "layout"]` when its advertised schema supports
those values and both are relevant. The MCP viewer can show the measured
findings, accessibility overlay and layout bounds. A model guideline review
is separate: do not label those measurements as its verdict, and fetch the
full advertised data products when the render returns only a summary.

For UI Builder, reuse or save the requested guidelines record as described
above, then return the canonical editor URL supplied by the design identity.
Tell the person its **Issues** panel shows the shared result, model and stale
revision status. If the review could not be saved, say so and keep detailed
findings at the design's existing discussion home when authorized; a link to
the editor does not prove they were recorded.
Do not manufacture an audit tab, query parameter or node deep link.

The Compose Preview MCP App may offer **Review design guidelines** for its
current subject. Clicking it requests the current chat agent's review; it
does not run an OpenRouter check directly. Treat its subject and overrides as
review inputs, discover the actual tools, and follow this checklist. Preserve
the selected overrides: a prompt or published report for the base render does
not review a locale, font-scale or device variant. If the guidelines prompt
cannot accept that variant, inspect its actual render and relevant data with
the catalog rules, and report any missing source or checks as partial coverage.
When message delivery is unavailable, the viewer offers a request to copy into
chat. Never promise that this action exists on an older deployment or that
its presence means an audit result has been displayed in the app.

For a UI Builder subject, an updated viewer may also offer **Show saved
review** when `ui_builder_get_guidelines` is advertised. It reads the shared
result on demand and shows findings, model, rules version, reviewed/current
revisions and answered/unchecked coverage. This is a saved result, not a new
audit; stale, missing and denied results must remain explicit. Local preview
verdicts are not UI Builder records and do not use this action.

Without an interactive app (non-interactive clients, static cards or chat-only
clients), return the same compact review with real image/artifact links or file
paths. Subjects without a recorded home can include findings directly; designs
with a home return verdict, coverage and home/thread links, preserving the
discussion at its existing destination. If a follow-up audit would be useful, give a runnable prompt naming
the subject and missing checks, for example:

> Review ListScreenPreview against the Wear catalog guidelines using your
> own model. Inspect the watch and unrolled views and measured accessibility.
> Report failures, unchecked rules and evidence links without editing the UI.

Offer commands only for tools available to this project. Do not present a
browser link as an audit launch unless the server actually supplies that
capability. Offer provider-backed commands only when a key and budget are
explicitly configured; ordinary agent review uses the keyless path.

## Return a compact review

- Verdict: `pass`, `pass with notes`, `fail`, or `partial review` when required
  evidence or coverage is missing. Report confirmed failures even in a partial
  review. Advisory guideline warnings produce notes; schema/render failures
  and measured accessibility errors can fail the review. Model findings never
  become an export or Stop-hook gate automatically.
- Identity: subject/URI or design home and reviewed revision/render hash;
  catalog, rules version/source, actual judging model or reused result model.
- Coverage: asked, answered, not applicable, unchecked/pending rules and their
  reasons; inspected devices/frames, font scales and accessibility results.
- Findings: rule ID, severity from the rule, short reason, source link and
  supplied node/ref or picture region. Keep detailed findings at the home and
  return its links when that discussion is authorized.
- Evidence links or file paths; say whether the shared result was recorded,
  reused, stale or could not be saved. Never claim a viewer was displayed when
  only text or file output exists.

Rule data and pictures remain canonical in the catalogs. Background:
[UI Builder guidelines](https://github.com/yschimke/compose-ui-builder/blob/main/docs/guidelines/README.md),
[preview engine and CLI](https://github.com/yschimke/compose-ai-tools/blob/main/docs/design/DESIGN_GUIDELINES.md).
