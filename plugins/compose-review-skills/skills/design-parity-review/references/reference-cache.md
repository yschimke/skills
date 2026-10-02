# The reference cache

**Import the design side on its own schedule; read it during the run.**

Wire this before the parity workflow, not after.

## Why the naive version fails quietly

A parity run that fetches every reference live pays the full reference cost
on every commit — for a side that did not move — against a rate limiter that
is **per token**.

Observed on a 77-component catalog: **18 components produced a verdict**. The
other 59 reported:

```
Adapter/diff error (failed soft): figma: rate limited (429) for
  /v1/files/…/nodes?ids=53923%3A28845.
```

Three things compounded, and the third is what made it damaging:

1. Fetches were per component — ~2–3 requests × N, in a burst.
2. A 429 threw immediately.
3. **Publishing replaced the branch**, so a component that rate-limited
   *this* run had its previous report deleted rather than kept.

So a run covering a quarter of the catalog looked exactly like one covering
all of it — and which quarter changed run to run. That is the failure to
design against: not an error, a **silently reduced scope**.

Retries, batched reads, and carry-forward publishing all reduce the symptom.
None removes the coupling. Splitting the cadences does.

|  | Cadence | Figma calls | Failure mode |
|---|---|---|---|
| **Import** (`design-parity import`) | Scheduled / dispatched / on kit change | 1 per unchanged file; 2 per stale node | Partial — costs freshness, loses nothing |
| **Parity run** (`design-parity run`) | Every commit | **Zero** | Cache miss on a named component |

The cache is a directory committed to a branch, exactly like the artifacts —
no hosted dependency, no live source at run time, and a diff that is
reproducible because the reference is *pinned* rather than re-fetched.

## What's on disk

```
design-parity/reference          ← a branch, one commit per import
├── index.json                   ← the manifest
└── <fileKey>/
    ├── variables.json           ← one per file, not one per node
    └── <nodeId>/                ← `1:42` is spelled `1-42` (filesystem-safe)
        ├── node.json            ← the structure the tokens come from
        └── image.svg            ← the rendered reference
```

`index.json` carries, per node, the file `version` in effect when it was
fetched and the `fetchedAt` timestamp. **Those two fields are the whole
mechanism**: `fileVersion` says whether an entry is stale, `fetchedAt` says
what to refresh first.

## Why it converges under a rate limit

- **A metadata short-circuit.** `GET /v1/files/:key?depth=1` carries
  `version`, which changes on any edit. One request answers "can *any*
  reference in this file have moved?" — so an unchanged kit costs one
  request, not 154.
- **Oldest-first.** What couldn't be fetched this time is the oldest thing in
  the cache next time, so it goes to the front of the queue. An import that
  only ever gets through half the catalog still reaches all of it — in two
  runs rather than never. `--max` makes this explicit for a kit too large for
  one job.
- **Nothing is deleted because a request failed.** A failed node keeps the
  entry it had, blobs included, *and keeps its old `fileVersion`* — so it
  stays stale and stays queued. A node refreshes only when **both** its
  structure and its image arrived, so a half-updated entry never reaches the
  branch. On a 429 the import stops that file rather than spending its retry
  budget proving the limiter is still there.

Publishing is a commit, not a force-push: the branch is diffable over time
and a bad import is one revert away. An import that changed nothing doesn't
commit.

**The import is allowed to be partial and exits 0 having done what it
could.** That is the design, not a tolerated failure — the alternative (fail
the job, publish nothing) is exactly the all-or-nothing behaviour that lost
the previous results. Don't "fix" it by adding a failure gate.

## Turning it on

Two workflows in the consumer repo. The import:

```yaml
# .github/workflows/design-parity-import.yml
on:
  schedule: [{ cron: '0 6 * * *' }]
  workflow_dispatch:
jobs:
  import:
    uses: yschimke/design-parity/.github/workflows/design-parity-import-reusable.yml@main
    permissions:
      contents: write
    secrets:
      figma-token: ${{ secrets.FIGMA_TOKEN }}
```

…and the parity run pointed at the same branch:

```yaml
jobs:
  parity:
    uses: yschimke/design-parity/.github/workflows/design-parity-reusable.yml@main
    permissions:
      contents: write
    with:
      module: ':catalog'
      reference-cache-branch: design-parity/reference
```

A cache miss on a named component is the run-side failure mode: the
component reports "no reference available" rather than silently passing.
That is the signal to dispatch an import, not to re-enable live fetching.

## Canonical reference

[`docs/REFERENCE_CACHE.md`](https://github.com/yschimke/design-parity/blob/main/docs/REFERENCE_CACHE.md)
— and [`docs/reference-cache.md`](https://github.com/yschimke/design-parity/blob/main/docs/reference-cache.md)
for the cache's *structural* half (component properties and variant axes as
ordinary cache entries, and what a cache-only run can answer offline).
