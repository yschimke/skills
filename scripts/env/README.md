# `coo.ee/env` — composable environment bootstrapper (simulation)

A [gitignore.io](https://www.toptal.com/developers/gitignore)-style service for
**dev environments** instead of `.gitignore` files. You ask for a set of
modules in the URL and get back a single `bash` script that installs them:

```bash
curl -fsSL https://coo.ee/env/java,android | bash
```

Like gitignore.io's `/api/java,android`, the path after `/env/` is a
comma-separated list of modules. The service renders a script by concatenating
a fixed preamble with each requested module and streaming the result.

> **This directory is a simulation.** `coo.ee` is not wired up yet. The file
> [`java,android`](./java,android) is the **hardcoded, pre-rendered** response
> for the `java,android` request, so you can see and run the idea today:
>
> ```bash
> # from a checkout
> ./scripts/env/java,android
> # or, the shape the real service would take
> curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/env/java,android | bash
> ```

## What the script does

1. **Checks preconditions first.** Verifies `curl`/OS, then probes every host
   the requested modules need. If any are blocked it prints exactly which
   hosts to allow and where to set them (Claude Code, Codex, Antigravity /
   Gemini Managed Agents), then **stops** — no half-installed environment.
   Override with `COOEE_IGNORE_HOST_CHECK=1` to try anyway.
2. **Installs [Nix](https://determinate.systems/)** (daemonless) as the base.
3. **Installs each module** through Nix: `java` → Temurin JDK 17 + 21,
   `android` → platform-tools + `ANDROID_HOME`.
4. **Persists the environment** to `~/.config/coo-ee/env.sh` and, when running
   inside a harness, to `$CLAUDE_ENV_FILE` / `$GITHUB_ENV`.

### Idempotent by design

Re-running is safe. The base install is skipped when `nix` is already present,
and packages go through `nix_ensure`, which installs only what's missing and
treats an already-present package as success. So a second run is a **no-op**
on a warm box and a **repair** on a cold or partially-broken one.

## Modules

| Module    | Installs                                  | Needs network access to |
| --------- | ----------------------------------------- | ----------------------- |
| `base`    | Nix (Determinate, daemonless)             | `install.determinate.systems`, `cache.nixos.org`, `channels.nixos.org`, `github.com`, `objects.githubusercontent.com` |
| `java`    | Temurin JDK 17 + 21, `JAVA_HOME`          | `cache.nixos.org` |
| `android` | `android-tools` (adb/fastboot), `ANDROID_HOME` | `cache.nixos.org`, `dl.google.com`, `maven.google.com` |

`base` is always included; it is the implicit preamble for every request.

## How rendering works

The served script is just a concatenation, so it is trivial to host (see
"Hosting roadmap" below):

```
_header.sh  +  base.sh  +  <module>.sh ...  +  _footer.sh
```

The [`modules/`](./modules) directory holds the source fragments. To re-render
the checked-in artifact after editing them:

```bash
cd scripts/env
cat modules/_header.sh modules/base.sh modules/java.sh \
    modules/android.sh modules/_footer.sh > 'java,android'
bash -n 'java,android'   # syntax check
```

To preview a different combination, concatenate a different set of module
files in the same order.

## Wiring it into an agent environment

Because it is one idempotent line, it drops into either layer:

**Cloud setup script** (Claude Code on the web environment, Codex setup
script) — runs once, result is cached:

```bash
curl -fsSL https://coo.ee/env/java,android | bash
```

**Project config / `SessionStart` hook** (`.claude/settings.json`) — runs in
both local and cloud sessions; idempotency keeps it cheap:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command",
        "command": "curl -fsSL https://coo.ee/env/java,android | bash" } ] }
    ]
  }
}
```

Either way, make sure the module hosts above are on your environment's
allowlist — the script tells you precisely which are missing if not. This is
the same allowlist discussed in
[`skills/compose-preview/references/agent-cloud.md`](../../skills/compose-preview/references/agent-cloud.md).

## Hosting roadmap

- **M1 — hardcoded.** The checked-in [`java,android`](./java,android) is a
  pre-rendered artifact. Zero infrastructure; demonstrates the contract.
- **M2 — dynamic renderer (built, see [`api/`](./api)).** A Vercel Node
  function parses `/env/:modules`, canonicalizes the list, concatenates the
  `modules/` fragments, and streams `text/x-shellscript`.
- **M3 — domain.** `env.coo.ee/<modules>` (see "Domain" below).

## M2 — the dynamic service

This directory is **self-contained and extraction-ready**: its contents are
exactly what graduates into the standalone `coo-ee-env` repo (see below).

```
modules/            shell fragments — the single source of truth
api/env/render.js   pure renderer: canonicalize + concatenate (unit-testable)
api/env/[modules].js  Vercel handler wrapping render()
vercel.json         routes /env/:modules and /:modules -> the function
java,android        M1 pre-rendered sample (kept as a runnable demo)
```

`render()` sorts + dedupes modules and always puts `base` first, so
`java,android` and `android,java` produce byte-identical output and share one
CDN cache entry. Unknown modules return `400` with the available list.

**Run it locally:**

```bash
node -e 'process.stdout.write(require("./api/env/render").render("java,android").body)' | bash -n -
npx vercel dev        # serves http://localhost:3000/env/java,android
```

## Publishing (recommended: a new repo + Vercel Git integration)

The service does not belong in the `skills` content repo long-term — `skills`
is content-only and documents tools that live elsewhere (the same way
`compose-preview` documents the CLI shipped from `compose-ai-tools`). Plan:

1. **New repo `coo-ee-env`** = the contents of this directory
   (`modules/`, `api/`, `vercel.json`, this README). `skills` keeps only the
   M1 demo + a link.
2. **Vercel Git integration**: import the repo once. Push to `main` →
   production deploy; PRs → preview URLs. No tokens stored in the repo.
3. **Domain**: add `env.coo.ee` as a custom domain on the Vercel project
   (CNAME → `cname.vercel-dns.com`).
4. **CI in the new repo** (allowed there, unlike here) — a tiny check:

   ```yaml
   # .github/workflows/render.yml
   name: render
   on: [push, pull_request]
   jobs:
     check:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-node@v4
           with: { node-version: 22 }
         - run: |
             for m in base java android java,android; do
               node -e "process.stdout.write(require('./api/env/render').render('$m').body)" | bash -n -
             done
   ```

### Extraction runbook (skills → coo-ee-env)

This directory is the staging source and is push-ready as-is — it already
carries `.github/workflows/render.yml` and `.gitignore`. The repo
[`yschimke/coo-ee-env`](https://github.com/yschimke/coo-ee-env) exists, so
clone it and copy this directory in:

```bash
# 1. Clone the (already-created) target and copy the service in.
git clone https://github.com/yschimke/coo-ee-env.git ../coo-ee-env
cp -a scripts/env/. ../coo-ee-env/        # README, modules, api, vercel.json, CI
cd ../coo-ee-env

# 2. Commit and push (uses your gh login, not this session).
git add .
git commit -m "Initial import: coo.ee/env service"
git push

# 3. Vercel Git integration: import the repo at https://vercel.com/new
#    (push-to-main then auto-deploys; PRs get preview URLs).

# 4. Domain: Vercel project -> Settings -> Domains -> add env.coo.ee,
#    then DNS: CNAME  env -> cname.vercel-dns.com
```

Once `coo-ee-env` is live, slim this directory back to the M1 demo
(`java,android` + a short README that links to the new repo) so the fragments
have a single home.

## Domain

`env.coo.ee/<modules>` is the recommended shape:

- **Subdomain, not apex path** — isolates the curl-serving app, gets its own
  Vercel project + TLS, and avoids apex→www redirect chains that break
  `curl | bash`. Keep the apex `coo.ee` for a human landing page.
- **Comma path** is fine (the gitignore.io precedent); order is canonicalized
  server-side so it caches well.
- **Keep the curl path pure** — a bare `curl` prints the script for review; a
  browser (`Accept: text/html`) can show help. HTTPS only.
- **Later:** version pinning (`/java,android@v1`) for reproducible installs.
