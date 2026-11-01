# Run the UI Builder locally

Part of the [compose-ui-builder skill](../SKILL.md).

## No host? Run one locally

The rest of [the skill](../SKILL.md) assumes somebody is hosting the builder. If nobody is, you can
be the host — the editor, the design service and the MCP endpoint all ship
inside the server distribution `compose-preview` fetches on first use. This is
the path agents most often get wrong, so the wiring is spelled out.

### Start it

```sh
compose-preview ui-builder --no-project --no-open
#   Local:   http://127.0.0.1:8723/?token=…
#   Builder: http://127.0.0.1:8723/ui-builder/m3-catalog/?token=…
```

`--no-project` opens the builder against the **packaged** catalogs
(`m3-catalog`, `remote-m3`) with no Gradle project and no build host. Without
it, the server wants a project and a build host and says so. `--no-open` prints
the URL instead of launching a browser. Designs persist under
`~/.compose-preview/ui-builder-state`; `--ui-builder-state-dir <dir>` moves
that, and `--ui-builder-state-dir none` serves the editor with no design API.
PNG and SVG export need the JVM to be **Java 21+**; on an older JVM everything
else works and the startup log says which version it found.

The port is the server's default (`8723`) unless taken, in which case the next
free one is used — **read the printed URL, don't assume the port**.

### Reaching it from another device

The server binds **loopback** by default, so the printed `127.0.0.1` URL works
only on the machine that started it. Add `--lan` to bind all interfaces and
print the network URL too:

```sh
compose-preview ui-builder --no-project --no-open --lan
#   Local:   http://127.0.0.1:8723/?token=…
#   Network: http://192.168.0.36:8723/?token=…
```

Both URLs answer, including the machine's own name (`http://<host>.local:8723/`)
where mDNS resolves it. Two things to know before sharing one:

- **The token in the link is the only gate.** `--lan` prints a warning saying so;
  share the link only with people you would let see the previews.
- **A LAN address is not a secure context.** `localhost`, `127.0.0.1` and
  `*.localhost` are trusted by browsers; a machine name or a raw LAN IP over
  plain HTTP is not. Browser APIs that require a secure context — clipboard
  writes, `crypto.subtle`, service workers — are unavailable there, so a feature
  that works on the local URL can fail only on the network one. If the editor is
  blank or a control misbehaves on the machine name and works on `127.0.0.1`,
  check that before anything else. An HTTPS front (a reverse proxy or a tunnel)
  is what makes the network URL a secure context; `--lan` alone cannot.

### The flag that decides whether MCP works at all

A local session is closed by default:

| Symptom | Cause | Fix |
| --- | --- | --- |
| `POST /mcp` 404s | the aggregate MCP endpoint was never enabled | start with `--catalog-mcp`, which also requires `--agent-grants` |
| `/mcp` lists every `ui_builder_*` tool but each call answers *"the presented identity lacks the UI-builder read capability"* | the grant store's capability ceiling is empty, so no approval can carry them | add `--agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export` and restart |
| the approval page shows scopes but no capability checkboxes | same ceiling, seen from the human's side | same flag; the page will then offer them (and name them as withheld when it cannot) |

So the full local command is:

```sh
compose-preview ui-builder --no-project --no-open \
  --agent-grants --catalog-mcp \
  --agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export
```

The `?token=` in the printed Builder URL is the **operator** credential: it
authorizes browser routes and the approval page, and it is what makes you the
approver. It is not the MCP bearer and should not be sent as one.

### Get a grant

Same device-code flow as a deployed host, pointed at the local port:

```sh
compose-preview auth request --server http://127.0.0.1:8723 \
  --capability ui-builder-read --capability ui-builder-write --capability ui-builder-export \
  --label "local authoring session"
# prints approveUrl + userCode; open the URL, confirm the code, approve
```

Open the `approveUrl` with the operator token appended
(`?token=<the token from the Builder URL>`) when the box is gated, approve, and
the waiting command stores the grant. `compose-preview auth status --server …`
shows it; `compose-preview auth token --server …` prints it for anything else.
The request expires in ten minutes and a server restart drops the grant — a
sudden refusal after a restart is that, not a bug.

### Two ways to attach your MCP client

**Server aggregate MCP (Streamable HTTP).** `POST http://127.0.0.1:8723/mcp`
with `Authorization: Bearer <grant>` (a bare `GET /mcp` answers 405 — POST is
the transport). Tool names are the `ui_builder_*` family this skill uses
throughout, so the rest of the skill applies unchanged.

**Standalone stdio MCP.** `compose-preview mcp serve --ui-builder-url
http://127.0.0.1:8723`, with `COMPOSE_PREVIEW_UI_BUILDER_TOKEN` exported — it is
read from the environment and **never accepted as an argv value**. This server
speaks the versioned v1 design API, and its tools are named differently from the
aggregate endpoint:

| Tool | What it does |
| --- | --- |
| `list_components` | catalogs and capability schemas — read the current pin before creating |
| `create_design` | a whole v1 document, never overwriting an existing id |
| `open_design` | the latest committed snapshot |
| `apply_design_operations` | one v1 batch (shape below) |
| `render_design` / `export_svg` / `export_compose` | revision-pinned artifacts (the committed revision is required, as on the aggregate tools) |
| `get_revision_diff` | durable events after a sequence cursor |

`apply_design_operations` takes `{"submission": …}` and the submission is the
**batch envelope**: the `type` discriminator is required, `clientId` is required
(any stable string naming your session), and `actorId` must be **omitted** — it
is bound to the authenticated actor, and a different one is refused:

```json
{"type": "batch", "designId": "my-design", "operationId": "op-1",
 "clientId": "my-session", "baseRevision": 0,
 "operations": [
   {"type": "insertNode",
    "node": {"id": "col", "componentId": "layout/column", "slots": {"children": []}},
    "location": {"parent": {"nodeId": "root", "slot": "content"}}}]}
```

A decoder error naming a class discriminator, or `Field 'clientId' is required`,
means exactly those two fields — the same operations work once they are present.

### The shell verbs, against the local session

`compose-preview design list|get|render|export` are clients: they talk to a
server that is already up and exit. Point them at the session explicitly:

```sh
compose-preview design list --server http://127.0.0.1:8723
compose-preview design export my-widget -o Widget.kt --server http://127.0.0.1:8723
```

Two traps. The verbs read `$COMPOSE_PREVIEW_TOKEN` (or the older
`$COMPOSE_PREVIEW_UI_BUILDER_TOKEN`) rather than the `auth` store, so export the
token unless your CLI is new enough to bridge a stored grant for an explicit
`--server`. And with no credential they start an interactive device flow and
**wait** — pass `--no-authorize` in CI so they fail fast instead. The default
`--server` is the server's default port, so an auto-picked port needs the flag.

### Creating and rendering without MCP at all

The browser routes accept the operator token as `?token=`, which is enough for a
smoke test:

```sh
curl -X POST 'http://127.0.0.1:8723/ui-builder/designs?token=<operator-token>' \
  -d 'catalog=remote-m3&designId=my-widget&template=weather-widget'   # 303 → the design URL
curl -o design.svg \
  'http://127.0.0.1:8723/api/ui-builder/v1/designs/my-widget/export.svg?token=<operator-token>'
```

Template ids: `blank` for `m3-catalog`; `wear-widget-small`, `wear-widget-large`,
`hello-widget` and `weather-widget` for `remote-m3` — the last two are finished
worked designs, useful as a known-good starting document.
