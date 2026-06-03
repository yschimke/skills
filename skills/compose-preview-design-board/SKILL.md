---
name: compose-preview-design-board
description: Assemble rendered Compose @Preview PNGs into a single self-contained HTML design board for Claude Design and other design-tool imports. Use when turning a set of rendered previews into one coherent design brief — grouped, captioned, and ordered — rather than handing over loose screenshots. Pairs with the compose-preview skill.
---

# Compose Preview — Design Board

Assemble the PNGs produced by `compose-preview` into a single, self-contained
HTML **design board** — categories, groups, captions, and layout — so a set of
renders travels as one coherent brief instead of loose screenshots. The board
is built for import into Claude Design (and similar design tools).

This skill assumes the **compose-preview** skill is installed — it owns the
renderer, CLI, and Gradle plugin that produce the PNGs this skill arranges.
Check first with `compose-preview --version`; if it's missing, ask the user to
run the bootstrap installer (which covers the compose-preview skills):

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/compose-ai-tools/main/scripts/install.sh \
  | bash
```

## Source

This skill is maintained at
[github.com/yschimke/skills](https://github.com/yschimke/skills) under
`skills/compose-preview-design-board/`. To check for updates, compare the
installed copy against `main` (e.g. `git ls-remote
https://github.com/yschimke/skills HEAD`). The renderer and CLI that produce
the input PNGs ship from
[github.com/yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).

## When to use this skill

- You have a set of rendered `@Preview` PNGs and want to hand them to a designer
  or to Claude Design as a structured brief — grouped by feature/screen, with
  captions and intent notes — not a flat folder of images.
- You want one portable artifact (a single HTML file, images inlined) that can
  be opened in a browser, served from a branch / GitHub Pages, or dropped into a
  design tool.

For *rendering* the previews, see the **compose-preview** skill. For *reviewing*
a UI PR by diffing base vs head renders, see **compose-preview-review**. This
skill is the export/presentation step that sits on top of those.

## Workflow

1. **Render previews.** Use the compose-preview CLI to produce PNGs and the
   manifest of what was rendered:

   ```sh
   compose-preview show --module <m> --json > /tmp/<m>-show.json
   ```

2. **Write a board spec.** A JSON document describing how to arrange the renders
   (categories → groups → items, each item pointing at a PNG path). See
   [Board spec schema](#board-spec-schema) below.

3. **Generate the HTML.** Run the builder to inline every referenced PNG as
   base64 and emit one self-contained file. Missing PNGs render as visible
   placeholders rather than failing the build:

   ```sh
   python3 scripts/build-design-board.py --spec board-spec.json --out design-board.html
   ```

   (The spec can also be piped on stdin instead of `--spec`.)

4. **Import to Claude Design.** Pick the route that fits:
   - **Web capture (best fidelity)** — open `design-board.html` in a browser, or
     serve it (GitHub Pages / a branch), and use Claude Design's web capture on
     the page.
   - **File upload** — drag the `.html` (or the individual PNGs) into Claude
     Design's drop zone.
   - **Connect the GitHub repo** for design-system context alongside the board.

   Grouping, captions, and flow order travel with the images, so the board reads
   as one brief rather than a pile of screenshots.

## Board spec schema

JSON, top-down:

| Level | Fields |
|---|---|
| **Top level** | `title`, `tagline`, `footer`, optional `palette` (colour swatches), `categories[]` |
| **Category** | `badge`, `title`, `intro`, `groups[]` |
| **Group** | `title`, `note` (the design intent / rationale), `layout`, `items[]` |
| **Item** | `src` (PNG path from compose-preview), `caption`, optional `sub` (state / size / theme) |

`layout` controls how a group's items are arranged:

- `"row"` — left-to-right wrapping; good for phone screens.
- `"grid"` — auto-fill grid; good for theme swatches and tiles.
- `"wide"` — full-width frames; good for size matrices.

## The builder script

`build-design-board.py` turns a spec into HTML with all images inlined (no
external file dependencies). Where the script itself should live is a project
choice:

- **Alongside this `SKILL.md`** as a supporting script — fine for a small,
  self-contained builder (this content repo permits scripts beside a skill).
- **Upstream in [compose-ai-tools](https://github.com/yschimke/compose-ai-tools)**
  next to the CLI/renderer if it grows into a first-class command.

Either way, keep paths in any example spec generator **relative to the repo root
or passed as arguments** — do not hardcode an absolute checkout path like
`/home/user/<project>`, or the spec breaks in every other checkout.

## Related

- [**compose-preview** skill](../compose-preview/SKILL.md) — render the
  `@Preview` PNGs this board is built from: CLI, Gradle plugin, capture modes.
- [**compose-preview-review** skill](../compose-preview-review/SKILL.md) —
  review a UI PR by rendering base and head and diffing them.
