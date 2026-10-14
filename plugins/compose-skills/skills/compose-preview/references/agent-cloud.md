# compose-ai-tools in cloud sandboxes

This guide describes a **portable cloud setup** for running compose-ai-tools in a hosted agent
sandbox, whichever agent runs in it. Settings that belong to one particular host are in
compose-agent-plugins' [host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#cloud-sandboxes).

Use this as the baseline for any ephemeral environment where outbound networking, JDKs, or Android SDK components may be restricted.

## What to configure (all cloud providers)

### 1) Network allowlist

Allow these hosts (plus each platform's default trusted registries):

| Host | Purpose |
| --- | --- |
| `maven.google.com` | AndroidX + AGP artifacts |
| `dl.google.com` | Android SDK cmdline-tools and Google-hosted downloads |
| `fonts.googleapis.com` | Downloadable font metadata |
| `fonts.gstatic.com` | Downloadable font binaries |
| `repo.gradle.org` | Gradle libraries/tooling artifacts |
| `services.gradle.org` | Gradle distributions |
| `api.adoptium.net` | JDK/toolchain provisioning APIs |
| `api.foojay.io` | Java distro metadata used by Gradle toolchain resolution |
| `api.github.com` | GitHub API usage by tooling/scripts |
| `jogamp.org` | Native/graphics dependencies occasionally pulled by desktop stacks |
| `jitpack.io` | Projects published through JitPack |
| `packages.jetbrains.team` | JetBrains-hosted Maven artifacts (Compose, tooling) |
| `cdn.azul.com` | Azul Zulu JDK downloads for toolchain provisioning |
| `*.cloudfront.net` | CDN backing many download/artifact hosts |
| `*.jetbrains.com` | JetBrains downloads, plugins, and Compose artifacts |
| `ziglang.org` | Zig toolchain used by some native cross-compilation paths |
| `*.java.net` | OpenJDK and related Java ecosystem downloads |
| `central.sonatype.com` | Maven Central (Sonatype) artifacts |
| `bb.staticvar.dev` | build-brief install script (fallback when the GitHub release download is blocked) |
| `github.com` | Skill and CLI release downloads (redirect to the asset host) |
| `objects.githubusercontent.com` | GitHub release asset binaries |

The coo.ee bootstrap below also needs `env.coo.ee` and its Nix hosts
(`install.determinate.systems`, `cache.nixos.org`, `channels.nixos.org`). You
don't have to work the list out in advance: it checks every host it needs and
prints any that are blocked.

### 2) Session-start preflight

At the start of each session, check and report before deep work starts:

- network mode (trusted/custom/full equivalent) and whether the hosts above
  are reachable;
- `java -version`: Java 17+ (21 works for many paths; repo builds are
  typically pinned to 17);
- when Android previews are in scope, the Android SDK, with `ANDROID_HOME` or
  `sdk.dir` set;
- `compose-preview doctor` and `./gradlew --version` (the wrapper must reach
  its distribution and dependency hosts).

Report it in one line, for example
`Cloud preflight: network=Custom (hosts ok), JDK=17, Android SDK=/opt/android-sdk, ready for Android + Desktop previews.`
If anything is missing, stop and give the exact remediation steps.

## Generic setup script (cloud bootstrap)

Use one line in the environment's setup script or startup hook:

```bash
set -o pipefail
curl -fsSL https://env.coo.ee/compose | bash
```

`pipefail` matters: without it a blocked or unreachable `env.coo.ee` makes
`curl` fail, `bash` run an empty script, and the line report success.

[coo.ee/env](https://github.com/yschimke/coo-ee-env) provisions what a
Compose preview workflow needs in any agent's shell:

- **The JDK the project pins** for Gradle (`toolchainVersion` in
  `gradle/gradle-daemon-jvm.properties`), else 17 + 21, with the sandbox
  proxy's CA trusted by the JVM and by Chromium.
- **A complete Android SDK.** Request specific platforms with
  `android[36,37.0]`; the package for `compileSdk = 37` is `37.0`.
- **The native libraries Compose Desktop previews load**, such as `libGL`.
- **The `compose-preview` skill and CLI.**
- **[`build-brief`](https://github.com/static-var/build-brief)** for Gradle
  builds, with its usage guide.

Where each agent host picks those up is in compose-agent-plugins'
[host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#skill-install-locations).

Before installing, it probes every host it needs. If any is blocked, it
prints the exact hosts to allow and stops, so the environment is never left
half-installed. Re-running it is a no-op, so a session-start hook can call it
every time.

Without Nix, or to install only the CLI and skills, use the canonical
installer ([setup.md](./setup.md) has its other options) instead:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/yschimke/skills/main/scripts/install.sh \
  | bash -s -- --android-sdk          # add --jdk 17,21 for several JDK majors
```

Its `--android-sdk` installs `cmdline-tools`, `platforms;android-36`,
`platform-tools` and `build-tools;36.0.0`, plus `platforms;android-37.0` on a
best-effort second pass (override with `ANDROID_SDK_PACKAGES` /
`ANDROID_SDK_EXTRA_PACKAGES`). It never reinstalls a JDK found under
`/usr/lib/jvm/` or `/opt/jdk<major>`. It does not install `build-brief`; add
`curl -fsSL https://bb.staticvar.dev/install.sh | bash` for that.

Whichever you use, never hardcode `git config --global user.name/user.email`
in a setup script. Set an identity only from values the user provided.

## Known cloud-sandbox gotchas

Four things that bite in a proxied sandbox and look like unrelated failures:

- **`JAVA_TOOL_OPTIONS` shadows `java -version`.** When a proxy CA truststore
  is injected (common in hosted sandboxes), the JVM prints
  `Picked up JAVA_TOOL_OPTIONS: …` as its *first* line, so any script parsing
  line 1 of `java -version` reads the flag dump instead of the version. Match
  the `version "…"` line, never `head -1`. This broke the installer's own JDK
  detection until [yschimke/skills](https://github.com/yschimke/skills)
  fixed it.
- **`github.com` may be blocked while `api.github.com` is allowed.** Egress
  policies commonly permit the API and deny HTML endpoints, so
  `releases.atom` 403s. The installer falls back to the API automatically; if
  you script releases yourself, do the same. Release *download* URLs usually
  still work, since they redirect to `objects.githubusercontent.com`.
- **`dl.google.com` is often blocked, and that is survivable.** `doctor` flags
  it as an error because Android SDK *platform* downloads go through it. If a
  platform is already installed and the build resolves its AndroidX/AGP
  artifacts from `maven.google.com` (which is usually allowed), builds still
  succeed. Treat it as a warning unless the SDK is genuinely missing.
- **The first Gradle invocation can exceed `doctor`'s timeout.** A cold
  sandbox downloads the whole Gradle distribution inside the model query, and
  `doctor` reports `could not query Gradle project model … cancel requested but
  timed out`, which reads like a broken project. Warm it first, then re-run:

  ```bash
  ./gradlew help          # downloads the distribution once
  compose-preview doctor
  ```

## Rendering a project that compiles against a very new SDK

**SDK > 35 needs JDK 21+** for rendering. A project on `compileSdk = 37` on JDK
17 fails at configuration time with `sdkVersion = N is outside the supported
range`: run on JDK 21+, or pin `composePreview.sdkVersion` as shown in
[setup.md § Apply the Gradle plugin](./setup.md#apply-the-gradle-plugin).

## Optional Android verification

```bash
./gradlew :samples:android:composePreviewRenderAll || true
```
