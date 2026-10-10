# From a checked-in design to application code

Use this render/export workflow for a repository `.uid` containing an editor
DesignDocumentV1, including an existing screen with a composable. Inspect the
schema first: `.uid` is also used for production contracts
(`compose-ui-builder-production/v1-candidate`). The editor can open production
layouts while preserving their declarations, but the CLI's `--document` lane
accepts DesignDocumentV1, not a production envelope. Use the project's
registered build-generation lane for a production contract; do not strip its
API, model, state or action declarations to make this recipe work. Model-only
production files have no visual layout. See
[the production contract](https://github.com/yschimke/compose-ui-builder/blob/main/docs/design/UI_BUILDER_BUILD_GENERATION.md). The design remains canonical at its recorded
repository path; source code and preview artifacts are linked implementation
and evidence.

1. Read the file and its recorded home before editing. Record its path,
   revision or content hash, catalog/version, target devices and reference
   images. Resolve the implementing composable and its `@Preview` functions.
   If the home is missing or disagrees with the opened path, report the
   mismatch and resolve it before writing.
2. Use an advertised file editor with typed operations when available.
   Address nodes by stable IDs from selection or comments. Work in small
   batches and reread before writing so a concurrent user edit is preserved.
   On a revision/ETag conflict, reload and reconcile; do not force overwrite.
   Without typed editing, validate against the actual document schema before
   saving. Do not treat an operations fixture as a `.uid` document.
3. Render the design with its pinned catalog. A single DesignDocumentV1 file
   can use the installed CLI's local lane:

   ```sh
   compose-preview design render --local --document ui-builder/designs/home.uid \
     --catalog catalog.bundle -o design.png
   ```

   Supply repeatable `--components <catalog>=<components.json>` records and
   `--assets <dir>` when required. A multi-design collection needs the editor's
   supported single-design export first; preserve its original home. Check
   `compose-preview design --help` for the installed version. A compiler or
   missing-frame diagnostic is a failed render, not visual evidence.
4. Inspect actual design and reference pictures at matching device, density,
   theme and state. Compare layout, spacing, typography, components and
   interaction states; identify unavailable frames and mismatched catalog
   versions. Use structured reference comparison only when advertised for
   this document. The local CLI supports render/export, not local comparison.
   Do not upload the design or move its home just to obtain a comparison.
5. Show the before/after images and concrete differences in chat. Continue
   requested, unambiguous edits and rendering without asking permission at
   every step. Ask for a decision when alternatives or requirements materially
   differ. A model guideline verdict never counts as human approval.
6. Export Kotlin into a temporary review artifact, then adapt it to the app's
   existing components, state, navigation and accessibility conventions:

   ```sh
   compose-preview design export --local --document ui-builder/designs/home.uid \
     -o generated/HomeScreen.kt
   ```

   Include required component records here too. Review generator diagnostics;
   do not overwrite the app's implementation wholesale. Keep the design path
   and revision/hash in the implementation handoff or linked PR.
7. Render the affected application previews with the canonical
   [compose-preview workflow](../../compose-preview/SKILL.md). Inspect them
   against the design and references, run relevant checks, and report remaining
   differences. A generated Kotlin file alone does not finish implementation.

Keep the person in the same conversation with real pictures, the affected
node IDs, source changes and outstanding decisions. Check discussion at the
recorded home before finishing. Report exactly which validations and renders
ran, which failed, and which host capabilities were unavailable.
