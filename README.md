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

The recommended path is the bootstrap installer in `compose-ai-tools`,
which installs the CLI **and** drops these skill bundles into the
shared `~/.agents/skills/` dir (with per-host symlinks for Claude Code
and Codex):

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/compose-ai-tools/main/scripts/install.sh \
  | bash
```

If you only want the skill content (no CLI — useful for read-only
agent setups), install as a Claude Code plugin:

```
/plugin marketplace add yschimke/skills
/plugin install yschimke-skills@yschimke-skills
```

Or with the [skills CLI](https://skills.sh):

```
npx skills add yschimke/skills
```

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
