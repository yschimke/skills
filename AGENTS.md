# AGENTS.md

Instructions for AI agents (Claude Code, Codex, Gemini, etc.) working in
this repo.

This is a **content-only** repo. The skills here are markdown documentation
that pairs with the `compose-preview` CLI and Gradle plugin published from
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).
The CLI lives there; consumer guidance lives here.

## When adding, renaming, or removing a skill

1. **Update `README.md`** — keep the skills list in sync. Each entry links
   to the skill's `SKILL.md` and summarises what it covers. If you add a
   skill and don't update the README, the change is incomplete.
2. **Do not bump the plugin version unless explicitly asked.** When you
   are asked for a release, edit `.claude-plugin/plugin.json` using
   semver: patch for wording/docs, minor for a new skill or new triggers,
   major for removals or breaking renames.

## Skill layout

- Skills live at `skills/<skill-name>/SKILL.md`. **Flat** — never nest by
  topic. Encode the topic in the directory name (e.g.
  `compose-preview-review`, not `compose-preview/review`).
- The `name:` in the SKILL.md frontmatter **must match the directory
  name** exactly. Use lowercase kebab-case for both.
- Supporting files (design notes, scripts) sit alongside `SKILL.md` in
  the skill dir.

## Manifests

- `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` are
  both JSON (not JSONC). Validate with `jq . <file>` before committing.
- The plugin `name` in both manifests must stay `yschimke-skills`.

## Cross-repo references

The `compose-preview` skill documents the CLI shipped from the
`compose-ai-tools` repo, so it cites release tags (e.g.
`v0.10.10`) and links into that repo. Keep those links stable. When the
CLI gets a new version, update referenced version strings here; do not
introduce a release-please marker in this repo — versions in skill text
track the upstream CLI, not this plugin.

## What not to do

- Don't add CI, build tooling, or Gradle config here — this is a content
  repo. CI, packaging, and the renderer live in `compose-ai-tools`.
- Don't rename existing skill directories "for consistency" without a
  concrete reason; renames break user references and bundled installs.
