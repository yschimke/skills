# Verifying Wear UI with Compose Preview

## Defer API and migration choices to the platform skill

Android's official
[Wear Compose Material 3 skill](https://developer.android.com/agents/skills/wear/wear-compose-m3/skill)
is the source of truth for dependencies, component selection, API usage, and
Material 2.5 or Horologist migrations. Follow it when it is available. This
reference does not provide competing Wear architecture or migration guidance;
it covers only rendering and verification with `compose-preview`.

If the platform skill is unavailable, say that current Wear API guidance was
not loaded rather than treating this rendering reference as an API authority.

## Verification workflow

1. Before editing, discover the previews for the affected screen and render a
   hash baseline. Save before-images for one to three screens the person will
   judge when the harness can show files.
2. Make the API and migration changes prescribed by the platform skill.
3. Sweep the preview variants with hashes first. Render PNGs only for changed
   or representative cells, then actually view those images before describing
   the result.
4. Check a small round device and the largest declared font scale explicitly.
   Multi-preview annotations can expand one function into many renders, so do
   not load every PNG into model context.
5. Run the accessibility data product or `compose-preview a11y`. Render
   failures and new accessibility errors are blockers. Pixel or hash changes
   are information, not failures: a migration is expected to change the UI.

Use `history_diff` or saved paths for a before/after comparison when available.
Never claim that a Wear screen looks correct from source, semantics, or hashes
alone.

## Round-face clipping in rendered PNGs

Any preview whose `device` resolves as round — `id:wearos_small_round`,
`id:wearos_large_round`, custom `spec:…isRound=true`, or
`spec:…shape=Round` — is clipped to a transparent inscribed circle before the
PNG is written. Corners outside the circle are alpha-zero, matching the usable
area of a real round watch face.

- On fixed, non-scrolling screens, keep primary content inside the inner safe
  rectangle.
- On scrolling screens, top and bottom cropping is expected. Check the initial
  state and an end or long capture instead of insetting every item.
- Long stitched captures use a capsule mask so vertical content remains
  visible between the round ends.
- Square Wear devices are rendered without the circular clip.

## Keep previews deterministic

Wear previews often fan out across devices, font scales, and scroll slices. A
single changing value can make every PNG noisy.

- Pin the time shown by `TimeText` in preview fixtures. Inject a fixed time
  source rather than reading the wall clock.
- For long stitched captures, suppress transient scroll-indicator animation
  when `LocalScrollCaptureInProgress.current` is true. Keep production
  behaviour unchanged outside that renderer-provided signal.
- Build preview fixtures from the screen-level composable so the preview can
  supply deterministic scaffolding, time, state, and data without changing the
  production app root.
- Keep reduced motion enabled for long scroll captures unless motion itself is
  the subject of the check.
- An edge action that appears only at the end of a scrolling list should be
  checked in the final scroll state; its absence in the initial frame is not by
  itself a regression.

## Accessibility checks on Wear

Round clipping and small displays make Wear findings different from phone
findings. Check at least:

- touch targets after round-face clipping, especially custom icon-only actions;
- content descriptions for icon-heavy controls;
- text clipping and loss of action labels at the largest font scale; and
- the annotated accessibility overlay, not only the unannotated PNG.

The annotated overlay for round Wear devices uses a stacked screenshot and
legend so findings remain readable on small displays. Report new errors as
blockers and warnings as findings; never treat an expected visual migration
diff as an accessibility failure.
