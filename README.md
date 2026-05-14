# Skills

Skills for rendering and reviewing [Jetpack Compose] and [Compose
Multiplatform] UI from agent workflows. They pair with the
`compose-preview` CLI and Gradle plugin published from
[yschimke/compose-ai-tools] — the CLI does the rendering, these skills
tell the agent how to drive it.

[Jetpack Compose]: https://developer.android.com/jetpack/compose
[Compose Multiplatform]: https://www.jetbrains.com/compose-multiplatform/
[yschimke/compose-ai-tools]: https://github.com/yschimke/compose-ai-tools

## Install

Three install paths — all of them end up with a working `compose-preview`
CLI on `$PATH`. The two skill-marketplace paths ship a self-bootstrapping
stub at `skills/compose-preview/scripts/compose-preview`; the first time
that stub is invoked it runs the canonical installer (`--cli-only`) and
re-execs into the real CLI.

**Curl the installer directly** (gets CLI + both skill bundles + per-host
symlinks for Claude Code and Codex into `~/.agents/skills/` in one shot):

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh \
  | bash
```

**Install as a Claude Code plugin** — drops the skill content (including
the bootstrap stub) into `~/.claude/plugins/`:

```
/plugin marketplace add yschimke/skills
/plugin install yschimke-skills@yschimke-skills
```

**Or via the [skills CLI](https://skills.sh):**

```
npx skills add yschimke/skills
```

With the two marketplace paths, the CLI download happens on first
invocation of the stub — there's no separate "now install the CLI" step.

## Skills

- [`compose-preview`](skills/compose-preview/SKILL.md) — render
  `@Preview` composables to PNG outside Android Studio. Covers Android
  (Jetpack Compose via Robolectric) and Compose Multiplatform Desktop
  (`ImageComposeScene` + Skia), with design notes on capture modes,
  multi-preview annotations, paused-clock animations, accessibility
  checks, display filters, Wear UI, resource previews, and cloud
  sandbox setup.
- [`compose-preview-review`](skills/compose-preview-review/SKILL.md) —
  review pull requests that change Compose UI by rendering `@Preview`
  composables on base and head and diffing them. Pairs with
  `compose-preview`; covers agent-authored PRs, local review
  workflows, and wiring `compose-preview/main` baselines + PR-comment
  GitHub Actions.

The CLI, Gradle plugin, renderer, MCP server, and VS Code extension
live in [yschimke/compose-ai-tools]; this repo is content-only.

## Contributing

Skills live at `skills/<skill-name>/SKILL.md`, flat (no language or
topic nesting). The `name:` in the SKILL.md frontmatter must match the
directory name. See [AGENTS.md](AGENTS.md) for the full contributor
contract.

## License

[Apache 2.0](LICENSE)

[plugins]: https://docs.claude.com/en/docs/claude-code/plugins
