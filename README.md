# Skills

**Let your agent see your Compose UI:** <https://preview.coo.ee/start/>

**Design a new screen with an agent:** <https://ui.coo.ee/start>

## Install

Claude Code:

```text
/plugin marketplace add yschimke/compose-agent-plugins
/plugin install compose-preview@compose-agent-plugins
```

Codex:

```sh
codex plugin marketplace add yschimke/compose-agent-plugins
```

then enable `compose-preview` from `/plugins`.

Antigravity:

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/compose-agent-plugins/main/scripts/antigravity-install.py | python3 -
```

Any other agent (Gemini CLI, OpenCode, Cursor, Copilot, …), or no plugin system:

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh | bash
```

(installs the CLI and the two default skills). Or, with Node:

```sh
npx skills add yschimke/skills --global --yes --skill compose-preview --skill compose-ui-builder
```

Then ask your agent to render one of your previews. Installer flags, updating
and [other hosts](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md)
are in [setup.md](skills/compose-preview/references/setup.md).

## Skills

| Skill | What it does | Installed |
|---|---|---|
| [`compose-preview`](skills/compose-preview/SKILL.md) | Render `@Preview` composables to PNG and look at them, verify UI edits, compare before/after, review against design guidelines, run an APK without an emulator. | Default |
| [`compose-ui-builder`](skills/compose-ui-builder/SKILL.md) | Design a screen or Wear widget in the UI Builder over MCP and turn it into Compose code. | Default |
| [`compose-preview-review`](skills/compose-preview-review/SKILL.md) | Review a pull request that changes Compose UI by rendering base and head and diffing them. | Optional: `install.sh --skills compose-preview-review,compose-preview-ci`, `npx skills add yschimke/skills --skill compose-preview-review`, or `/plugin install compose-review@compose-agent-plugins` |
| [`compose-preview-ci`](skills/compose-preview-ci/SKILL.md) | Set up GitHub Actions that post before/after renders on PRs, fork PRs included. | Optional, as above |

Audit results from `compose-preview` follow the same chat summary and
evidence-link convention in every host. App-capable viewers can show measured
render details; UI Builder can show saved guideline reviews in its Issues
panel. See the
[presentation checklist](skills/compose-preview/references/design-guidelines.md#show-the-review-and-offer-another-run).

The skills are generic and host-neutral; the harness plugins that vendor them
live in [yschimke/compose-agent-plugins](https://github.com/yschimke/compose-agent-plugins).
The CLI, Gradle plugin and renderers ship from
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools), and
the preview server and UI Builder from
[yschimke/compose-preview-server](https://github.com/yschimke/compose-preview-server).
This repo is content-only.

## Contributing

Skills live at `skills/<skill-name>/SKILL.md`, flat (no language or
topic nesting). The `name:` in the SKILL.md frontmatter must match the
directory name. See [AGENTS.md](AGENTS.md) for the full contributor
contract.

## License

[Apache 2.0](LICENSE)

## Repository merge policy

Repository settings and required checks are managed by
[yschimke/renovate-config](https://github.com/yschimke/renovate-config/tree/main/repo-policy).
Pull requests use Conventional Commit titles and squash merges. Run
`scripts/install-git-hooks.sh` to enable the same attribution checks locally.
