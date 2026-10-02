# Round-tripping: both directions on one project

Running code→design and design→code on the same repo is supported, and it is
the setup most teams end up wanting. It is also the setup where a
half-considered configuration produces a loop that overwrites somebody's
work, so the ordering below matters.

```
                      code-led
   Compose @Preview ──────────────▶ catalog export ──▶ design-artifacts/<system>
        │  (compose-design-catalog)                        │
        │                                                  │ (figma-catalog-import)
        │                                                  ▼
        │                                              Figma file
        │                                                  │
        │                    design-led                    │ (import → reference cache)
        └◀──────── verdict / PR comment ◀── parity run ◀────┘
                         (this skill)
```

## The one decision that governs everything: direction

`.design-parity.json`'s `direction` is not a per-run flag — it is a
**committed statement about which side is canonical**, and both directions
read it.

| Direction | Parity run | Catalog export | Push-back |
|---|---|---|---|
| `design-led` | Failures **block** the PR | Still fine (kits are seed) | **Never runs** |
| `code-led` | Failures reported, don't block | The authoritative direction | Eligible |

A project that publishes a catalog *and* checks parity is almost always
`code-led`: the code is the source of truth and the Figma file is a
downstream view of it. Setting `design-led` on such a project means the bot
blocks PRs for drifting from a file that the same pipeline regenerates from
those PRs — which is the loop to avoid.

## Direction 1 — code → design

Owned by [compose-design-catalog](../../compose-design-catalog/SKILL.md) (render
a whole component system into an importable sticker-sheet bundle) and
[figma-catalog-import](../../figma-catalog-import/SKILL.md) (land that bundle in
a Figma file, reconciled in place by `componentId`, never
delete-and-rebuilt).

The two things this direction must get right for the round trip to close:

- **`componentId` is the join key.** The catalog's `design-map.json`
  correspondence and the parity run's `design-map.json` have to name the same
  components. If the catalog is generated from `@CatalogComponent(reference =
  …)` annotations, don't hand-write that projection on either side — run
  `emit-design-map.mjs` + `design-parity-kit-index resolve` as the
  `design-map-command` in both workflows, so the two derive the map from the
  same annotations by the same code. See [Deriving the map from
  annotations](./ci.md#deriving-the-map-from-annotations). A repo that
  hand-rolls the projection ends up with two copies that agree until one of
  them is edited.
- **Published kits are seed only.** In a code-led pipeline the Figma file is
  regenerated from renders; treat hand edits in it as feedback to bring back
  into code, not as a reference to diff against.

## Direction 2 — design → code

The parity run in the [main skill](../SKILL.md), reading a committed
reference cache. When the Figma file is itself downstream of a catalog
export, the cache is importing your own published renders back — which is
the point: it proves the round trip is lossless, and it catches the cases
where it isn't (a rasterization difference, a variable that didn't project,
a component the import silently dropped).

## Code-to-Canvas push-back

The narrow, opt-in path that writes candidate renders **back onto the Figma
canvas** after a parity run, so the design file reflects what shipped.

It is gated **three** ways, and anything short of all three is a no-op with a
clear log line:

1. an explicit opt-in flag is set, **and**
2. the resolved direction is `code-led` — in `design-led` the design stays
   canonical and code is never pushed back, **and**
3. the component's `source` is `figma`.

A fourth practical gate: **the Figma REST API is read-only**, so a real write
needs a companion plugin / Dev Mode bridge behind a
`FIGMA_CANVAS_ENDPOINT`. With no writer configured the run no-ops too. The
push-back module itself is pure — it makes no network or model calls.

Treat the "no-op with a clear log line" behaviour as the feature it is: a
misconfigured push-back tells you it did nothing rather than half-writing a
file.

## What must agree between the directions

| Thing | Both sides must… |
|---|---|
| `direction` | read the same `.design-parity.json`. Don't override it per workflow. |
| `design-map.json` | be derived the same way — commit it, or generate it with the same command in both workflows. |
| Component identity | key on `componentId`, not on frame position or layer name. |
| Render target | render the candidate on the target that represents what ships (see the main skill's step 4). A catalog exported from Desktop and a parity check rendered on Android will disagree for reasons that have nothing to do with the design. |

## Canonical reference

- [`docs/design-artifacts/FIGMA_IMPORT.md`](https://github.com/yschimke/design-parity/blob/main/docs/design-artifacts/FIGMA_IMPORT.md)
  — the code→design last hop.
- [`docs/PRINCIPLES.md`](https://github.com/yschimke/design-parity/blob/main/docs/PRINCIPLES.md)
  — Principle 5 is the one that makes push-back opt-in and triple-gated.
- [`docs/page-backdrops.md`](https://github.com/yschimke/design-parity/blob/main/docs/page-backdrops.md)
  — the whole-screen variant (import key design pages as backdrops, lay code
  renders on top). Opt-in and off by default.
