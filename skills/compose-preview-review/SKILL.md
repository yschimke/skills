---
name: compose-preview-review
description: Review pull requests that change Compose UI by rendering @Preview composables on base and head and diffing them. Use when reviewing a UI PR locally, authoring an agent-opened PR that touches UI, or wiring compose-preview/main baselines and PR-comment GitHub Actions for a project. Pairs with the compose-preview skill.
---

# Compose Preview — Review

Workflows for reviewing pull requests that touch Compose UI, authoring
agent-opened PRs that include preview screenshots, and wiring CI to post
before/after diffs automatically.

This skill assumes the **compose-preview** skill is installed — it owns
the renderer, CLI, and Gradle plugin. Check first with
`compose-preview --version`; if it's missing, ask the user to run the
bootstrap installer (which covers both skills):

```sh
curl -fsSL https://raw.githubusercontent.com/yschimke/compose-ai-tools/main/scripts/install.sh \
  | bash
```

## Source

This skill is maintained at
[github.com/yschimke/skills](https://github.com/yschimke/skills) under
`skills/compose-preview-review/`. To check for updates, compare the
installed copy against `main` (e.g. `git ls-remote
https://github.com/yschimke/skills HEAD`). The CLI, renderer, and
GitHub Actions referenced below ship from
[github.com/yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools).

## When to use this skill

Pick the workflow that matches the task:

| Task | Read |
|---|---|
| Review a PR locally that touches UI | [references/agent-pr.md § Reviewing a PR](./references/agent-pr.md#reviewing-a-pr-agent-workflow) |
| Author an agent-opened PR that touches UI | [references/agent-pr.md § Authoring an Agent PR](./references/agent-pr.md#authoring-an-agent-pr-body-structure) |
| Wire `compose-preview/main` baselines + PR-comment CI for a project | [references/ci-previews.md](./references/ci-previews.md) |
| Render previews on base and head and diff them | [references/agent-pr.md § Render base and head locally](./references/agent-pr.md#1-render-base-and-head-locally) |

## Quick reference: review a UI PR locally

1. **Check whether the project has CI preview comments first.** If a
   sticky `<!-- preview-diff -->` comment is already on the PR, read it
   and cite it instead of re-rendering. See
   [references/agent-pr.md § Optional: integrate with preview-comment CI](./references/agent-pr.md#6-optional-integrate-with-preview-comment-ci-rare).

2. **Render base and head.** Use a worktree so the working copy stays put:

   ```bash
   BASE=$(gh pr view <N> --json baseRefName -q .baseRefName)
   git worktree add ../_pr_base "origin/$BASE"
   (cd ../_pr_base && compose-preview show --json) > base.json
   compose-preview show --json > head.json
   git worktree remove ../_pr_base
   ```

3. **Diff** by `id` + `sha256`. Bucket into changed / new / removed.

4. **Read** the PNGs for changed and new entries — that's the visual
   context the human reviewer will lack.

5. **Post a text-only review comment** summarising deltas. Image upload
   only with explicit consent — see
   [references/agent-pr.md § Uploading images](./references/agent-pr.md#3-uploading-images-only-with-explicit-consent).

## Reference docs

| Path | When to read |
|---|---|
| [references/agent-pr.md](./references/agent-pr.md) | Full PR review + agent PR authoring guidance: comment structure, image hosting choices, things to flag, integration with `preview-comment` CI when present. |
| [references/agent-audits.md](./references/agent-audits.md) | Agent audit recipes and data-product documentation clusters: accessibility, localisation, Wear clipping, resources, theme, traces, and failure triage. |
| [references/ci-previews.md](./references/ci-previews.md) | `compose-preview/main` baselines branch + PR-comment GitHub Actions: workflow YAML, action inputs, branch durability. |
| [references/mcp-review.md](./references/mcp-review.md) | Driving a PR review through the MCP server (two-workspace base+head flow, push notifications, edit-on-top iteration). |

## Related

- [**compose-preview** skill](../compose-preview/SKILL.md) — running the
  renderer itself: CLI, Gradle plugin, `@Preview` design patterns,
  capture modes (animations, scrolling), accessibility checks.
