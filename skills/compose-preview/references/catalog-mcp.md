# The catalog MCP (a remote preview server's tool surface)

A `compose-preview serve` deployment can expose every catalog it hosts through
one **remote MCP endpoint** at `/mcp`. That is a different product from the
local daemon MCP in [`mcp.md`](./mcp.md), and the two are easy to confuse —
they share tool names (`render_preview`, `render_matrix`, `diff_semantics`,
`list_data_products`) because they answer the same questions about the same
previews.

| | **Daemon MCP** ([`mcp.md`](./mcp.md)) | **Catalog MCP** (this file) |
|---|---|---|
| Where it runs | On your machine, out of the `compose-preview` CLI | On someone's preview server |
| Transport | stdio, registered by `compose-preview mcp install` | Streamable HTTP at `https://<host>/mcp` |
| Needs | A checkout, a Gradle build, a daemon JVM per module | A URL and a grant. **No checkout** |
| Credential | none — it is your own process | A short-lived bearer from the agent-grant flow |
| Owns | Source registration, file watching, builds, daemon lifecycle | Catalog discovery, published renders, made-to-order renders, history |
| Ships from | [`compose-ai-tools`](https://github.com/yschimke/compose-ai-tools) | [`compose-preview-server`](https://github.com/yschimke/compose-preview-server) |
| Tools | `register_project`, `watch`, `notify_file_changed`, `record_preview`, … | `status`, `list_projects`, `list_previews`, `list_devices`, `history_*`, … |

Reach for the catalog MCP when the previews you care about are **published on a
server** — `preview.coo.ee/<system>/`, a team's box, a catalog from a repo you
have not cloned. Reach for the daemon MCP when you are editing source and want
the render to follow your edits; nothing on a server can see your working tree.

If all you have is a server URL and a `404`, start at
[`server-access.md`](./server-access.md) — the grant flow below is the same one,
just driven from inside MCP.

## Connect

The endpoint is opt-in and **always** requires agent grants, even where the
catalog pages themselves are public: an operator runs
`compose-preview serve --agent-grants --catalog-mcp` (or `SERVE_CATALOG_MCP=1`
on the published image), and `--catalog-mcp` without a working grant lane is
refused at startup rather than exposing an anonymous machine API.

```text
URL:           https://preview.example/mcp
Authorization: Bearer <short-lived grant>
```

Put the bearer in the host's secret store or environment facility — never in a
URL, never in checked-in config.

Nothing about the endpoint is catalog-specific: `list_projects` discovers the
current catalog set, catalog-scoped tools take a `catalog` argument beside
`previewId`, and resource URIs carry both
(`compose-preview://catalog/<catalog>/<preview-id>`). Catalogs come and go
without an MCP client reconfiguration. Storybook-compatible ids are qualified as
`<catalog>::<preview-id>` so equal preview ids in two catalogs cannot collide.

An unauthenticated call answers `401` with `WWW-Authenticate: Bearer` and an
`X-Compose-Preview-Agent-Access` header (also in the JSON body) naming the
absolute grant-request URL — so a host that meets the 401 can walk its user
into the grant flow instead of dead-ending.

## Getting a credential without leaving MCP

`compose-preview auth request` ([`server-access.md`](./server-access.md)) is the
CLI route. `request_access` / `poll_access` are the same two HTTP routes as MCP
tools — same JSON, same per-address rate limit, same two secrets — for an agent
that has the MCP transport and not a shell:

1. **`request_access`** (optionally `scope`, `ttlSeconds`, `capabilities`,
   `label`) returns `approveUrl`, `userCode`, and a `deviceSecret` to keep.
2. **Show the link *and* the code to your human, verbatim.** They open the page
   and check the code matches before approving. The link is not the credential —
   it carries a request id and nothing else — so it is safe to paste into chat
   and useless for skipping the approval.
3. **`poll_access`** with `requestId` + `deviceSecret` answers `approved` with
   the bearer. It **waits** for the decision rather than returning `pending`
   immediately, because every poll here costs a model round-trip: `waitSeconds`
   defaults to 8 and may be raised to 30 by a client that tolerates longer
   calls. A wait that times out answers `pending` — call again, don't spin.

`initialize`, `ping`, `tools/list`, `request_access` and `poll_access` need no
credential. **Everything that reads a catalog does**, and the gate is per
message rather than per endpoint, so anything the server does not recognise is
closed until someone deliberately opens it.

Ask for the least that does the job — `preview` for browsing published renders,
`live` only when the server must render *for* you (scopes are cumulative). Give
`--label`/`label` an issue number and a purpose; it is what the approver reads.

**This is also the recovery path mid-task.** Grants live in memory, so a
redeploy of the host invalidates every bearer regardless of remaining TTL. A
sudden `401` is not a bug to retry — ask for a new grant the same way you asked
for the first.

## The tool surface

Streamable HTTP, protocol versions `2025-06-18` and `2025-03-26`. Calls are
independent, so the server allocates no sessions and advertises no
subscriptions: JSON-RPC goes over `POST`, notifications get `202`, and `GET`/SSE
and `DELETE` answer `405`. There is no `resources/subscribe` here — that is a
daemon-MCP feature and it does not exist on a stateless endpoint.

| Tool | Scope | What it answers |
| --- | --- | --- |
| `initialize`, `ping`, `tools/list` | none | Handshake and discovery |
| `request_access`, `poll_access` | none | Get a grant from inside MCP (above) |
| `status` | `preview` | Readiness and the aggregate catalog set |
| `resources/list`, `resources/read` | `preview` | List and read published preview PNGs |
| `list_projects` | `preview` | Which catalogs this server hosts |
| `list_previews` | `preview` | One catalog's previews and their metadata |
| `render_preview` | `live` | Render with overrides (see `observe`, below) |
| `render_matrix` | `live` | One preview across a cross-product of override axes |
| `list_devices` | `preview` | The `device` override's accepted vocabulary |
| `history_list` | `preview` | One preview's render timeline |
| `history_diff` | `preview` | Whether two of its recorded renders differ |
| `history_read` | `preview` | One historical render's pixels, by commit or blob |
| `diff_semantics` | `live` | Two previews' semantics compared by `testTag` |
| `list_data_products` | `preview` | Which structured products previews expose |
| `get_preview_data` | `live` | Accessibility / Compose annotation data |
| `list-all-documentation`, `get-documentation-for-story` | `preview` | Storybook-MCP-compatible discovery aliases |
| `preview-stories` | `live` | Storybook-MCP-compatible rendering alias |

A grant short of what a tool needs comes back naming the scope it lacks. That is
the signal to ask for a wider grant, not to retry.

### `render_preview` and what comes back

`observe` decides what the render costs you:

| `observe` | Returns | Needs |
|---|---|---|
| *(default)* | Semantics / hash — token-frugal | |
| `png` | Base64 pixels | |
| `svg` | `compose/figma-svg` **markup as text** | `svgAvailable` |
| `scroll-png` | `render/scroll/long` — the whole scrollable screen | `scrollAvailable` |
| `scroll-svg` | `compose/figma-svg-long` | `scrollAvailable` |

`observe=svg` returns SVG **source** in a `text` block, not a base64 `image`
block: almost no MCP client renders SVG from an image block, and a vector
consumer (a Figma round-trip, a diff, a DOM capture) wants the markup. The
vector and scroll lanes exist only where the host can produce them — a static
bundle carrying `figma/<slug>.svg`, or a daemon-backed session — so
`list_previews` reports `svgAvailable` and `scrollAvailable` per preview and you
can pick the lane without asking for it and reading the refusal. A catalog with
neither is refused **by name**, not reported as a missing preview. Both share the
render semaphore with the PNG lane; enabling MCP creates no unmetered renderer.

The scroll lanes re-render a virtualised `LazyColumn` at an expanded viewport so
every row composes, rather than cropping the viewport. A non-scrolling preview
just yields its ordinary output.

**Check that your override actually landed.** Every observation carries
`generation` — what produced the bytes — and, when the call supplied
`overrides`, `requestedOverrides` and `overridesApplied` beside it. A `baked`
generation sets `overridesApplied: false` with an `overridesIgnoredReason`: the
published bundle has no renderer, so those overrides are **not** in the returned
pixels. Without reading this you cannot tell an override that applied and moved
nothing from one that was never honoured — and two overrides producing identical
PNGs is the normal case, not the pathological one. `observe=png` keeps its bare
single-image reply for an override-free browse and adds the provenance as a
second `text` block once `overrides` is non-empty.

**Unknown override keys are refused here**, unlike on `GET /render` where a URL
may carry a cache-buster beside the axes. An `overrides` object has no
passengers, so an unrecognised key is a caller error and the error lists the
supported keys.

### `list_devices` — before you guess a device name

An unrecognised `device` value is **not** an error on the render path: it falls
through to the default frame, which from your side is indistinguishable from a
device that happens to render like the default. `list_devices` publishes the
accepted vocabulary with each frame's dp size and density, from the same catalog
the render path resolves against.

### `render_matrix` — does this axis move anything?

Give it `axes` mapping an override key to the values to sweep; it renders the
cross-product and reports one cell per combination with its overrides, `sha256`,
dimensions and `generation` (`observe=png` adds pixels per cell). Base
`overrides` are the floor each cell starts from; an axis value with the same key
wins for that cell.

`distinctRenders` counts the distinct hashes over the whole matrix — the one
number that answers *do these axes move the pixels at all*. Cells are capped at
**24 per call**, enforced before any rendering. Each cell takes the render permit
individually, so a matrix queues behind browser traffic rather than reserving the
renderer.

### History: `history_list` / `history_diff` / `history_read`

`history_list` answers in one of three `mode`s, and the field is load-bearing —
reading them as interchangeable turns "this server has no timeline for you" into
"this preview has never changed":

| `mode` | When | What you get |
|---|---|---|
| `published` | the catalog came from a delivery branch | the timeline inline, plus `manifestUrl`, `repo`, `branch`, `renderUrlTemplate` |
| `local` | project mode — `serve` against a checkout | the timeline inline, each version carrying a `renderUrl` |
| `none` | an uploaded bundle with neither | a **`reason`**, not an empty list |

The `published` timeline is answered from the copy the catalog load already
holds, pinned to the same commit as `catalog.json` — so it is exactly as fresh
as the catalog being served, and there is no separate staleness to manage.
Answering inline matters: one catalog's manifest is ~1 MB across 1336 previews
while one preview's slice is ~500 bytes, and an agent behind an allowlist often
cannot reach `raw.githubusercontent.com` at all even while the MCP endpoint is
reachable. `manifestUrl` is still there if you want the whole timeline.

A timeline is **not** a commit list. Adjacent commits whose render bytes are
identical collapse into one version, and a preview that keeps returning to a
render it had moved away from is reported `unstable` with a `flapCount`.

`history_diff` compares two recorded renders, defaulting to the two newest —
*did the last publish move this preview?* It is a **metadata** comparison: the
versions are already collapsed distinct renders, so the content ids answer it
without fetching either image. It reports `unstable` alongside and says so
explicitly when set — which is worth reaching for, because on an unstable
preview a byte difference is not evidence of a real change. That is the question
[`compose-preview-review`'s stability triage](../../compose-preview-review/references/stability.md)
otherwise settles with a repeat-render oracle; here it is precomputed.

`history_read` returns one historical render's pixels through this server,
addressed by `commit` or `blob` (a prefix is enough). It is `preview` scope, not
`live`: it replays published bytes and commissions no render. A version the
branch will not hand over is reported as such, distinctly from one that does not
exist.

### `diff_semantics` — two previews, no pixels

Reports tags present on only one side, tags whose bounds moved, and tags whose
occupancy `count` changed. Identity is the **authored `testTag`**, deliberately
not a `SemanticsRefs` ref: a ref indexes siblings under an anchor
(`r/role:Button[0]`), so inserting a Button ahead of it silently retargets the
same string at different pixels and the diff would report "unchanged" for exactly
the edit you needed to see. A `testTag` either survives an edit or stops
resolving, and both are reported. Two previews carrying no tags at all get an
explicit note rather than an `identical` verdict they did not earn.

## Not this endpoint

- **The UI-builder MCP** is a separate product on the same host (a configurable
  path such as `/ui-builder/mcp`), with `ui-builder-read` / `-write` / `-export`
  capabilities and a **stateful** collaborative design session. It shares this
  endpoint's authentication, approval, TTL and revocation — nothing else. The
  catalog endpoint has no authoring state and stays stateless on purpose.
- **The ingest lanes.** `POST /bundles/{name}` and `POST /docs` take the
  operator's own token and refuse grants outright, whatever scope you hold. No
  MCP tool fronts them.
- **Anything needing your working tree** — registering a project, watching
  files, telling a daemon a source file changed, recording an interaction to a
  Compose UI test. That is [`mcp.md`](./mcp.md), locally.

## Operational notes

- Browser-originated calls must carry an `Origin` matching the request host
  (DNS-rebinding defence); non-browser clients normally omit it.
- Request bodies are capped at 1 MiB; responses disable caching.
- Renders share the server-wide semaphore and queue timeout with browser
  traffic.
- Authorization is evaluated **per call**, so an expiry or a revocation takes
  effect immediately without any session teardown.

## See also

- [`server-access.md`](./server-access.md) — the CLI side of the same grant
  flow, the scope table, and what to do when the lane 404s.
- [`mcp.md`](./mcp.md) — the local daemon MCP.
- [`data-products.md`](./data-products.md) — the kinds `list_data_products` /
  `get_preview_data` return.
- [`docs/design/CATALOG_MCP.md`](https://github.com/yschimke/compose-preview-server/blob/main/docs/design/CATALOG_MCP.md)
  — the server's own design and setup guide.
