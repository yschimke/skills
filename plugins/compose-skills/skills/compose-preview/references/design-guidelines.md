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

| Subject | First read | Review with |
| --- | --- | --- |
| UI Builder design | `ui_builder_get_design`, its home and revision, then `ui_builder_get_guidelines` when advertised | `ui_builder_guidelines_prompt`, judged with your own model; record through `ui_builder_record_guidelines` where allowed |
| Local `@Preview`s | Existing `build/compose-previews/guidelines.json` and applicable catalog rules, if present | `preview_guidelines_prompt` on the local server, with explicit `surface` and a batch of `previews` |
| Hosted catalog preview | `catalog_list_data_products`, then `catalog_get_preview_data` with `kind: "guidelines/result"` when listed | Inspect the published result and its render; use only review/render tools that this host advertises |
| CLI without preview MCP | `compose-preview --help`, the module's rules and existing report | `compose-preview guidelines` when a model key is configured; otherwise read the rules, source, accessibility data and real renders yourself |

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

For a requested provider run, `check_preview_guidelines` reads
`COMPOSE_PREVIEW_OPENROUTER_KEY` from the server environment and accepts
`max_cost` (USD). The CLI equivalent, with an existing key and an agreed budget:

```sh
compose-preview guidelines --filter ListScreenPreview --surface screen \
  --guidelines path/to/ui-builder.guidelines.json --json --annotate --max-cost 0.10
```

The CLI writes `build/compose-previews/guidelines.json` and optional
`*.guidelines.png` overlays. Keep the key out of arguments, chat and files.
Do not invoke a second provider just to review when the agent can judge the
keyless prompt. Without a key or guidelines tools, inspect source, measured
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
