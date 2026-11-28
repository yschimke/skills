# Running an app's androidTest suite in the simulator

An existing instrumentation suite (`src/androidTest`, `AndroidJUnit4`, `ActivityScenario`,
Espresso, Compose test rules) runs in Robolectric's simulator, with no emulator or device, and
reports per-test results as JSON. Use it to check an app change against the tests it already has,
somewhere an emulator can't run, such as a cloud sandbox or CI without KVM. Upstream reference:
[Instrumentation tests](https://github.com/yschimke/android-simulator/blob/main/docs/SIMULATOR.md#instrumentation-tests).

**Availability.**

- `--instrument` and the Gradle task `simulator<Variant>AndroidTest` ship in CLI and Gradle plugin
  v2.104.0.
- The releases after it add:
  - the test APK's own context and assets (`InstrumentationRegistry.getContext()`);
  - audio codecs for Media3 and `MediaCodec` tests;
  - `--shards`;
  - `--pool`.
- Check `compose-preview android-simulator --help` before relying on a flag.
- The simulator needs a Java 21+ JDK: pass `--java <jdk>`, set `COMPOSE_PREVIEW_SIMULATOR_JAVA`, or
  in Gradle set `-PcomposePreview.simulatorJava=<jdk>`.

## From Gradle (the default)

With the `ee.schimke.composeai.preview` plugin applied to an app module that has `androidTest`
sources:

```sh
./gradlew :app:simulatorDebugAndroidTest
./gradlew :app:simulatorDebugAndroidTest --tests com.example.LoginTest --tests 'com.example.CartTest#checkout'
```

The task builds both APKs and runs every test. It fails when any test fails, naming each failed
test in the build output.

Results are in `app/build/outputs/androidTest-results/simulator/debug/`:

- `results.json`, for you to read;
- `TEST-simulator.xml`, JUnit XML for CI.

`results.json`:

```json
{"tests":8,"passed":7,"failed":1,"skipped":0,"durationMs":6046,
 "cases":[{"class":"com.example.LoginTest","method":"wrongPassword","status":"failed",
           "durationMs":812,"message":"…","trace":"…"}, …]}
```

A run that cannot start its tests writes `"error"` with the reason and no cases. Examples are an
unknown `--tests` class or method, or a crash before the first test.

| Gradle property | Does |
| --- | --- |
| `composePreview.simulatorSdk` | the Android API level to simulate (default: the CLI's) |
| `composePreview.simulatorShards` | split the suite across N simulators at once |
| `composePreview.simulatorPool` | `true`: run in a simulator started ahead of the run |
| `composePreview.simulatorJava` | the Java 21+ JDK the simulator runs on |
| `composePreview.cli` | the `compose-preview` launcher (default `COMPOSE_PREVIEW_CLI`, then `PATH`) |

## From the CLI

```sh
./gradlew :app:assembleDebug :app:assembleDebugAndroidTest
compose-preview android-simulator app/build/outputs/apk/debug/app-debug.apk \
  --instrument app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --tests com.example.LoginTest,com.example.CartTest#checkout \
  --test-json build/simulator-tests/results.json
```

- **`--tests`** takes classes and `Class#method`s, comma-separated. Every selector must match, or
  the run fails before any test starts. A class named whole runs all its tests, and a
  parameterised method runs every parameter.
- **Without `--tests`**, the run finds the test APK's own test classes. It leaves out suites and
  the libraries the APK bundles (`androidx.`, `com.google.`, `kotlin.`); name such a class with
  `--tests` to run it.
- **Exit code:** 0 when every test passed.

## Making repeated runs fast

Each run boots the app in a new simulator. That boot is most of a small suite's time: about 9 s
for an 8-test suite on four cores, from warm caches.

- **`--pool`** (Gradle `-PcomposePreview.simulatorPool=true`) is the one to use when running the
  suite again and again, as in an edit, rebuild, test loop.
  - The first run starts a background pool and boots as usual. It leaves a simulator started for
    the next run, so start-up drops out of every later run (9.1 s to 7.2 s for that suite).
  - Changing `--tests` between runs still uses the started simulator.
  - A rebuilt APK boots once, then is warm again.
  - The pool exits after 30 idle minutes. `compose-preview android-simulator --pool-stop` ends it at
    once.
  - Each started simulator is an idle JVM of a few hundred MB. Skip the pool on a machine short of
    memory.
- **`--shards N`** (Gradle `-PcomposePreview.simulatorShards=N`) runs N simulators at once. Each
  takes its share of the tests, as AndroidJUnitRunner's `numShards` does, and the reports are
  merged into one.
  - Every shard pays its own boot, which is mostly CPU, so sharding only helps when the tests take
    longer than a boot. A Compose UI suite with 35 s of tests went from 50 s to 42 s with 2 shards;
    8- and 13-test suites got slower.
  - Keep N at or below the number of cores. It combines with `--pool`, which keeps N simulators
    started.

## What works, what doesn't

The tests run on their own thread while the main thread keeps looping, as on a device. So these
behave as they do on a device:

- `runOnMainSync`, `ActivityScenario` (including `recreate()`, with ViewModels kept for
  Hilt/Koin/Metro-built activities);
- Espresso (`onView`, clicks through `InputManager`);
- `createAndroidComposeRule`, `waitUntil`;
- `InstrumentationRegistry` (target and test contexts, the test APK's assets).

Known gaps. Treat a failure in one of these as the simulator's, not the app's:

- **Arguments:** `InstrumentationRegistry.getArguments()` is empty (no `-e` arguments).
- **Not supported:** orchestrator, `@SdkSuppress` filtering, and `UiAutomator` / `UiDevice`. The
  test APK's uiautomator classes are not loaded.
- **Compose screenshots:** `captureToImage()` (`PixelCopy`) from the test thread fails.
- **Main-thread crash:** a crash on the main thread ends the run without per-test results, as it
  ends the process on a device.
- **Clock:** the simulated clock can fall behind wall time while the UI animates. Tests that wait a
  wall-clock timeout for a `delay`-based retry may need a longer wait.

To see a failing test's screen, run the app with `compose-preview launch` instead
([simulator.md](./simulator.md)): it gives screenshots and a semantics tree.
