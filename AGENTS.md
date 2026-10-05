# AGENTS.md

Instructions for AI agents (Claude Code, Codex, Gemini, etc.) working in
this repo.

This is a **content-only** repo. The skills here are markdown documentation
that pairs with the `compose-preview` CLI and Gradle plugin published from
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).
The CLI lives there; consumer guidance lives here.

**Generic skills, not harness wiring.** Skills here read the same in any agent
host: what to do, and which MCP tools or CLI commands to use. The set is meant
to grow beyond the preview toolchain into a wider range of Compose and Android
UI skills. Anything that names a particular host, or installs into, configures
or works around one (per-harness manifests, MCP client config, hooks, host
detection, a host's cloud sandbox, `claude.yml` sessions), belongs in
[yschimke/compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins).
The full table, and the references still waiting to move, are in its
[`docs/repository-consolidation.md`](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/repository-consolidation.md#the-two-agent-repositories).
Don't add new host-specific material here.

**Two upstream repos, not one.** The CLI, the Gradle plugin, the renderers and
the local daemon MCP ship from `compose-ai-tools`. The preview *server* —
everything behind `compose-preview serve`, including its catalog MCP endpoint,
the UI builder and the playground — ships from
[yschimke/compose-preview-server](https://github.com/yschimke/compose-preview-server),
on its own release line. When a skill cites `serve` source or a server-side
design doc, it belongs to that repo. (Its operator-facing manual,
`docs/public-preview-server.md`, still lives in `compose-ai-tools` — cite it
where it actually is rather than where the code is.)

## Git history

- Git history attributes work only to the human committer. Never add an AI
  `Co-authored-by:` trailer or use an agent identity as author or committer, in a commit or
  in a PR title or body. Session links and "Generated with" footers are fine.
- **Reviewers, human or bot: verify before reporting an attribution finding.** Across these
  repositories it is the most-reported and least-real review finding, and reports have named
  commits that do not exist. Never infer the identity from the fact that an agent wrote the code: it
  is whatever `git config user.email` held, and here that is the human. Check the real range first:

      git cat-file -t <sha>          # a commit you are about to name must actually exist
      git log --format='%h %an <%ae> | %cn <%ce> | %(trailers:key=Co-authored-by,valueonly,separator=%x2C)' <base>..<head>

  Report only an agent name or an `@anthropic.com` / `@openai.com` address that this output
  actually shows, and quote it. `Yuri Schimke <yuri@schimke.ee>` is the human identity, and
  `github-actions[bot]` / `renovate[bot]` are exempt bot accounts. `GitHub <noreply@github.com>` is
  the committer of every squash merge. None of these is ever a finding.

## When adding, renaming, or removing a skill

1. **Update `README.md`** — keep the skills list in sync. Each entry links
   to the skill's `SKILL.md` and summarises what it covers. If you add a
   skill and don't update the README, the change is incomplete.
2. **Put it in one bundle and regenerate.** Add the skill to exactly one entry
   of `BUNDLES` in `scripts/generate-bundles.py`, then run
   `python3 scripts/generate-bundles.py`. CI fails while `plugins/` is stale.
3. **Do not bump the plugin version unless explicitly asked.** When you
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
- `plugins/<bundle>/` holds **generated copies** of skills, grouped so a
  harness can install the default pair (`compose-skills`: `compose-preview`
  and `compose-ui-builder`, matching `install.sh`'s defaults) without the
  review (`compose-review-skills`) and design (`compose-design-skills`)
  skills. Never edit them; edit `skills/` and regenerate.

## Manifests

- `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` are
  both JSON (not JSONC). Validate with `jq . <file>` before committing.
- The plugin `name` in both manifests must stay `yschimke-skills`.
- The bundle entries in `marketplace.json`, and every file under `plugins/`,
  are written by `scripts/generate-bundles.py`; don't hand-edit them.

## Cross-repo references

The `compose-preview` skill documents the CLI shipped from the
`compose-ai-tools` repo, so it cites release tags (e.g.
`v1.79.0`) and links into that repo. Keep those links stable. When the
CLI gets a new version, update referenced version strings here; do not
introduce a release-please marker in this repo — versions in skill text
track the upstream CLI, not this plugin.

## What not to do

- Don't add CI, build tooling, or Gradle config here — this is a content
  repo. The one exception is `scripts/generate-bundles.py` (stdlib Python)
  and its `--check` step in CI. CI, packaging, and the renderer live in `compose-ai-tools`.
- Don't rename existing skill directories "for consistency" without a
  concrete reason; renames break user references and bundled installs.
