# CI preview baselines (`compose-preview/main` branch)

Projects that use the Gradle plugin can wire up a single GitHub Actions
workflow that maintains a `compose-preview/main` branch with rendered
PNGs and a `baselines.json` file (preview ID → SHA-256), and posts
before/after diff comments on pull requests. The branch serves two
purposes:

1. **Browsable gallery** — the branch has a `README.md` with inline images,
   viewable directly on GitHub.
2. **PR diff comments** — on PRs the same action renders previews,
   compares against the baselines, and posts a before/after comment.

The action ships from
[yschimke/compose-ai-tools](https://github.com/yschimke/compose-ai-tools)
as a composite action. Add one workflow file to your project; you're done.

## Upgrade notice — proactively migrate to `apply`

As of `v0.11.6` the four legacy composite actions —
`preview-baselines`, `preview-comment`, `a11y-report`, and
`notification-previews` — have been replaced by a single unified
`apply` action that auto-selects baseline vs comment mode from the
event and runs all four pipelines (compose / resources / a11y /
notifications) back-to-back.

The legacy actions are **kept for one release as deprecation shims
that forward to `apply`**, then removed. If you encounter a project
still wired to any of them, **proactively migrate** to `apply` (and
collapse separate `preview-baselines.yml` / `preview-comment.yml` /
`a11y.yml` / `notifications.yml` workflows into a single
`compose-preview.yml`) as part of the next change touching CI. The
migration is mechanical and removes four workflow files plus their
duplicated checkout / Java / Gradle setup.

See [Migrating from the legacy actions](#migrating-from-the-legacy-actions)
below for a concrete before/after.

## Optional pipelines: a11y and notifications

`apply` runs all four pipelines (`compose`, `resources`, `a11y`,
`notifications`) by default. The a11y and notifications pipelines are
no-ops unless you point them at a Gradle module via `a11y-module` /
`notifications-module`. Use `only:` / `skip:` to narrow what runs.

A11y renders the built-in a11y hierarchy, ATF checks, and overlay
annotation path enabled, then appends the annotated PNGs and
`findings.json` to `compose-preview/a11y/main` on push, or
`compose-preview/a11y/pr` with a `<!-- a11y-report -->` comment on PRs.

A11y is daemon-only — to drive the CLI directly outside CI:

```bash
./gradlew :cli:installDist
cli/build/install/compose-preview/bin/compose-preview a11y --module :samples:wear
```

Every preview then gets its `.a11y.png` annotated overlay next to the clean PNG, and the
artifact set on disk (`build/compose-previews/accessibility.json` plus
`build/compose-previews/data/<id>/a11y-overlay.png`) is unchanged — existing CI scripts that
read those paths keep working. A populated a11y baseline branch should contain `.a11y.png`
files next to the clean PNGs; if the README only links clean PNGs, the a11y CLI didn't run.

## Single workflow — `compose-preview.yml`

```yaml
# .github/workflows/compose-preview.yml
name: Compose Preview
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
    types: [opened, synchronize]
  workflow_dispatch:
permissions:
  contents: write          # baselines push + compose-preview/pr branch
  pull-requests: write     # upserts the PR comment
concurrency:
  group: compose-preview-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          persist-credentials: false
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: 17
      - uses: gradle/actions/setup-gradle@v6
      - uses: yschimke/compose-ai-tools/.github/actions/apply@v0.11.6
        with:
          cli-version: catalog   # or "latest", or a literal "0.11.6"
          a11y-module: samples:wear            # optional — empty skips
          notifications-module: samples:android # optional — empty skips
```

`mode` defaults to `auto` and is picked from the event (`push` →
`baseline`, `pull_request` → `comment`). Override with
`mode: baseline | comment | skip` for one-off `workflow_dispatch`
runs.

## Pinning the CLI version

`cli-version` accepts:

- A literal string (e.g. `"0.11.6"`) — pinned, deterministic.
- `latest` — resolved via the GitHub releases API on each run.
- `catalog` — read the `composePreviewCli` key from
  `gradle/libs.versions.toml`. Pair with the Renovate `customManager`
  snippet in the [README](../../../README.md#on-github-actions) to keep
  the version bumped on releases.
- `none` — assume `compose-preview` is already on `PATH`.
- `source` — build from the current checkout (internal CI only).

`catalog-path` and `catalog-key` override the catalog location and key
when needed.

## `apply` inputs

| Input | Default | Purpose |
| --- | --- | --- |
| `cli-version` | `latest` | CLI version (`latest` / `catalog` / literal / `none` / `source`). |
| `catalog-path` | `gradle/libs.versions.toml` | Catalog file when `cli-version=catalog`. |
| `catalog-key` | `composePreviewCli` | `[versions]` key when `cli-version=catalog`. |
| `timeout` | `600` | CLI render timeout in seconds. |
| `development-branch` | `main` | Long-lived branch that drives baseline pushes. |
| `only` | `` | Comma-separated subset of `compose,resources,a11y,notifications`. Empty = all. |
| `skip` | `` | Comma-separated pipelines to skip after `only` is resolved. |
| `a11y-module` | `` | Gradle module path for the a11y pipeline. Empty skips silently. |
| `notifications-module` | `` | Gradle module path for the notifications pipeline. |
| `pr-number` | `` | Override for PR number when context is ambiguous. |
| `comment-on-empty-diff` | `false` | Post an empty-diff sticky comment instead of staying silent. |
| `skip-render` | `false` | Reuse pre-staged `_previews.json` / `_resources.json` instead of invoking the CLI. |
| `mode` | `auto` | Event-based selector override: `auto` / `baseline` / `comment` / `skip`. |

## Migrating from the legacy actions

The four previous workflows collapse into one. The shims still work
for one release, so you can do this in a single PR.

**Before** — four files:

| File | Action used |
| --- | --- |
| `.github/workflows/preview-baselines.yml` | `…/actions/preview-baselines@v0.10.10` |
| `.github/workflows/preview-comment.yml`   | `…/actions/preview-comment@v0.10.10` |
| `.github/workflows/a11y-report.yml`       | `…/actions/a11y-report@v0.10.10` |
| `.github/workflows/notification-previews.yml` | `…/actions/notification-previews@v0.10.10` |

**After** — one `.github/workflows/compose-preview.yml` using
`…/actions/apply@v0.11.6` (see the YAML above). Delete the four old
workflow files. If a project only wants a subset of pipelines, use
`only:` / `skip:` rather than reintroducing separate workflows.

Inputs map 1:1: the `cli-version`, `catalog-path`, `catalog-key`, and
`timeout` inputs keep their names and defaults. `branch` /
`base-branch` / `head-branch` on the legacy actions are no longer
overridable from the workflow — the new action standardises on
`compose-preview/main` and `compose-preview/pr`.

## Mobile readability

A lot of PR review happens on phones, where GitHub renders comment tables
inline and any wide row forces horizontal scrolling. Long fully-qualified
function or class names are the usual offender. When tweaking the comment
generator (or building similar before/after reports), keep the layout
vertical-friendly:

- Columns are still fine — the goal isn't to drop the table, just to keep
  rows narrow enough to fit on a phone.
- Put the image on the left as a small thumbnail (e.g. `width="120"`) and
  wrap it in a link to the full-size PNG so reviewers can tap through for
  pixel detail.
- Trim package names — the simple class / function name plus the module
  heading is usually enough to disambiguate. Stash the FQN in a `<details>`
  block or `title=` attribute if it's worth keeping.

## Querying baselines outside CI

```bash
git ls-remote --exit-code origin compose-preview/main          # check existence
git fetch origin compose-preview/main
git show origin/compose-preview/main:baselines.json            # read manifest
git show origin/compose-preview/main:renders/<module>/<id>.png # read PNG
```

Or via raw URL:

```
https://raw.githubusercontent.com/<owner>/<repo>/compose-preview/main/renders/<module>/<id>.png
```

The composable baseline gallery includes suggested extra preview artifacts
that the plugin emits as image data products, such as `@ScrollingPreview`
LONG PNGs and GIFs. In CLI JSON these appear as extra `captures[]` rows
with labels like `scroll long` or `scroll gif`, so baseline generation must
consume every capture row rather than only the top-level `pngPath`.

## Branch durability

Both `compose-preview/main` and `compose-preview/pr` are append-only:

- In `baseline` mode `apply` adds one commit per push to `main`
  (parented on the previous tip; skipped when the rendered tree is
  unchanged). A fast-forward push on a serialised concurrency group
  means no rewrites.
- In `comment` mode `apply` appends one commit per PR push to
  `compose-preview/pr` (tree = that PR's changed PNGs). The PR comment
  pins `<img>` URLs to commit SHAs on `compose-preview/main` and
  `compose-preview/pr`, not branch names — so images keep resolving
  after the PR merges and after later PRs advance either branch.

## Local persistent state: `.compose-preview-history/fonts/`

CI keeps long-lived state on the `compose-preview/main` and
`compose-preview/pr` branches. There's also a per-module local cache —
`<module>/.compose-preview-history/fonts/`, deliberately outside
`build/` so it survives `./gradlew clean`. The directory holds the
**downloadable-font cache**, populated automatically the first time a
preview pulls a Google Font — no opt-in needed. Cached here so
repeated renders after `clean` don't re-download, and so
`-PcomposePreview.fontsOffline=true` can serve cache misses without
hitting the network.

The cache is designed to be **committed to git** when reproducibility
matters (network-free renders, byte-stable baselines). The samples in
this repo commit their cached `fonts/` so CI doesn't depend on
`fonts.gstatic.com` being reachable.

If your project doesn't want this, `.gitignore` the directory — the
choice is between local reproducibility and a smaller working tree.
Agents and humans should expect to encounter the directory at the
module root rather than under `build/`; it's the one deliberate
exception to the otherwise-true "writes go under gitignored `build/`"
framing the SKILL uses. (The dirname is historical: an earlier
preview-history feature shared this root; it has since been removed
and the cache is the only writer.)
