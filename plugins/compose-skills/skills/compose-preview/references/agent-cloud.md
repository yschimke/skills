# compose-ai-tools in cloud sandboxes

This guide describes a **portable cloud setup** for running compose-ai-tools in a hosted agent
sandbox, whichever agent runs in it. Settings that belong to one particular host are in
compose-agent-plugins' [host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#cloud-sandboxes).

Use this as the baseline for any ephemeral environment where outbound networking, JDKs, or Android SDK components may be restricted.

## What to configure (all cloud providers)

### 1) Network allowlist

Allow these hosts (plus each platform's default trusted registries):

- `maven.google.com`
- `dl.google.com`
- `fonts.googleapis.com`
- `fonts.gstatic.com`
- `repo.gradle.org`
- `services.gradle.org`
- `api.adoptium.net`
- `api.foojay.io`
- `api.github.com`
- `jogamp.org`
- `jitpack.io`
- `packages.jetbrains.team`
- `cdn.azul.com`
- `*.cloudfront.net`
- `*.jetbrains.com`
- `ziglang.org`
- `*.java.net`
- `central.sonatype.com`
- `bb.staticvar.dev`
- `github.com`
- `objects.githubusercontent.com`

Recommended rationale:

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

### 2) Toolchain prerequisites

Agents should verify:

- **JDK installed** (Java 17+ recommended; Java 21 works for many paths but repo builds are typically pinned to 17)
- **Android SDK installed** when Android previews are needed
- `ANDROID_HOME` or `sdk.dir` is configured when Android modules are present
- Gradle wrapper can reach distribution and dependency hosts

### 3) Session-start checks agents should run

At the beginning of each session, agents should:

1. Confirm network mode/allowlist includes all required hosts.
2. Confirm `java -version` succeeds and reports expected major version.
3. Confirm Android SDK presence when Android builds are in scope.
4. Run a quick project health check (`compose-preview doctor` and/or a Gradle noop task).
5. Flag missing prerequisites **immediately** to the user before deep work starts.

## Agent behavior requirements (flag to user at start)

At session start, agents should proactively report:

- Current network mode (trusted/custom/full equivalent)
- Whether required hosts appear reachable
- JDK version detected
- Android SDK status (installed/missing, path)
- Any blockers likely to cause build/render failures later

Suggested one-liner status format:

- `Cloud preflight: network=Custom (hosts ok), JDK=17, Android SDK=/opt/android-sdk, ready for Android + Desktop previews.`

If anything is missing, agents should stop and provide exact remediation steps.

## Generic setup script (cloud bootstrap)

Use one line in the environment's setup script or startup hook:

```bash
curl -fsSL https://env.coo.ee/compose | bash
```

[coo.ee/env](https://github.com/yschimke/coo-ee-env) provisions what a
Compose preview workflow needs in any agent's shell:

- **The JDK the project pins** for Gradle (`toolchainVersion` in
  `gradle/gradle-daemon-jvm.properties`), else 17 + 21, with the sandbox
  proxy's CA trusted by the JVM and by Chromium.
- **A complete Android SDK.** Request specific platforms with
  `android[36,37.0]`; the package for `compileSdk = 37` is `37.0`.
- **The native libraries Compose Desktop previews load**, such as `libGL`.
- **The `compose-preview` skill**, linked into each agent's skills directory.
- **[`build-brief`](https://github.com/static-var/build-brief)** for Gradle
  builds, plus a usage guide written to each agent's global rules file.

Before installing, it probes every host it needs. If any is blocked, it
prints the exact hosts to allow and stops, so the environment is never left
half-installed. Re-running it is a no-op, so a session-start hook can call it
every time.

Without Nix, or to install only the CLI and skills, use the canonical
installer instead:

```bash
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

`composePreview.sdkVersion` auto-detects from `android.compileSdk`, but the
Robolectric render range is narrower than the compile range: **SDK > 35 needs
JDK 21+**. A project on `compileSdk = 37` running on JDK 17 therefore fails at
configuration time with `sdkVersion = N is outside the supported range`. Either
run on JDK 21+, or pin the render SDK explicitly:

```kotlin
composePreview {
    variant.set("debug")
    sdkVersion.set(35)   // pinned: compileSdk 37 is outside the render range on JDK 17
}
```

## Recommended quick verification commands

Run after bootstrap:

```bash
java -version
compose-preview doctor || true
./gradlew --version
```

Optional Android verification:

```bash
./gradlew :samples:android:composePreviewRenderAll || true
```

## Provider-specific hints

Per-host network modes and sandbox settings are in compose-agent-plugins'
[host setup notes](https://github.com/yschimke/compose-agent-plugins/blob/main/docs/host-setup.md#cloud-sandboxes).
