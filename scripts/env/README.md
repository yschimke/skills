# `coo.ee/env` — composable environment bootstrapper

A [gitignore.io](https://www.toptal.com/developers/gitignore)-style service for
**dev environments**: you ask for a set of modules in the URL and get back a
single `bash` script that installs them.

```bash
curl -fsSL https://env.coo.ee/java,android | bash
```

The path after the host is a comma-separated module list (order is
canonicalized server-side). The script installs [Nix](https://determinate.systems/)
(daemonless) as a base, then each requested module — e.g. `java` (Temurin JDK
17 + 21) and `android` (`android-tools`, `ANDROID_HOME`). It probes the hosts
each module needs and prints exactly which to allow before doing anything, and
it is idempotent, so re-running is a no-op on a warm box and a repair on a cold
one.

## Source

The service — module fragments, the renderer, routing, and CI — lives in its
own repo, which is the single source of truth:

> **→ [`yschimke/coo-ee-env`](https://github.com/yschimke/coo-ee-env)**

## Wiring it into an agent environment

Because it is one idempotent line, it drops into either layer — a cloud setup
script (runs once, cached) or a `SessionStart` hook in `.claude/settings.json`
(runs in local and cloud sessions):

```bash
curl -fsSL https://env.coo.ee/java,android | bash
```

Make sure the module hosts are on your environment's allowlist — the script
prints exactly which are missing if not. This is the same allowlist discussed in
[`skills/compose-preview/references/agent-cloud.md`](../../skills/compose-preview/references/agent-cloud.md).
