# `coo.ee/env` — demo snapshot

A [gitignore.io](https://www.toptal.com/developers/gitignore)-style service for
**dev environments**: you ask for a set of modules in the URL and get back a
single `bash` script that installs them.

```bash
curl -fsSL https://env.coo.ee/java,android | bash
```

The path after the host is a comma-separated module list; the service renders a
script by concatenating a fixed preamble with each requested module.

## This directory is just a runnable demo

The service itself — the `modules/` fragments, the Vercel renderer, and the
routing — now lives in its own repo, which is the single source of truth:

> **→ [`yschimke/coo-ee-env`](https://github.com/yschimke/coo-ee-env)**

What remains here is one **pre-rendered** artifact, [`java,android`](./java,android),
so you can see and run the idea straight from a `skills` checkout:

```bash
./scripts/env/java,android
```

It installs [Nix](https://determinate.systems/) (daemonless) as a base, then the
`java` (Temurin JDK 17 + 21) and `android` (`android-tools`, `ANDROID_HOME`)
modules. It checks host reachability first and is idempotent, so re-running is a
no-op on a warm box and a repair on a cold one. This snapshot can drift from the
live service — treat `coo-ee-env` as authoritative.

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
