# Gotchas

Part of the [compose-ui-builder skill](../SKILL.md).

## Gotchas

- **A local session is closed until you open it.** `--agent-grants --catalog-mcp
  --agent-grant-capabilities ui-builder-read,ui-builder-write,ui-builder-export`
  is the difference between a working local MCP endpoint and one that 404s or
  refuses every call — see [No host? Run one locally](local-host.md#no-host-run-one-locally).
- **Capabilities, not scope.** `live` does not include `ui-builder-read`.
- **`list_designs` can legitimately be empty.** It lists what *your actor* can
  see, not what is on the server.
- **A design id must be path-safe** and is chosen by you; creation never
  overwrites, so an id that exists answers "already exists" rather than replacing
  a design.
- **Presence never wakes `await_design`.** Somebody looking at the design, or
  moving their cursor, is deliberately not a change.
- **The tools are absent, not failing, on a box with no builder.** Read
  `tools/list`; `ui_builder_render_native` is likewise absent where the host
  cannot compile.
- **`setModifiers` replaces the whole list** for a node — there is no
  add-one-modifier operation, so send the modifiers you want the node to end up
  with.
- **An `assetKey` has to resolve on the host.** `asset/image` names an asset the
  server holds; on a host with no asset store there is nothing to name, and a
  coloured `layout/box` is the honest stand-in for a photograph in a mockup.
- **The frame's ground comes from `environment.theme`.** A surface's
  `containerColor` colours that surface; going dark is
  `{"type": "updateEnvironment", "changes": [{"type": "setTheme", "value": "dark"}]}`.
