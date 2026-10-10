# Changelog

## [0.1.10](https://github.com/yschimke/skills/compare/v0.1.9...v0.1.10) (2026-10-05)


### Bug Fixes

* code quality sweep of scripts and docs ([a03713c](https://github.com/yschimke/skills/commit/a03713c6a9709ff2be81e13788d313a39289330e))
* **install:** parse the JDK major past JAVA_TOOL_OPTIONS noise ([7d29db6](https://github.com/yschimke/skills/commit/7d29db6127d55f30eccc8bf3cf702c40873ec2b2))
* **review:** fail fast when the audit sample MCP reader dies ([fda414e](https://github.com/yschimke/skills/commit/fda414ea354878c58a5660b073a8796847747607))
* **scripts:** compare generated bundles byte-for-byte ([d54594b](https://github.com/yschimke/skills/commit/d54594b40e1692af63e21f54c1c85eeb6807de5a))

## [0.1.9](https://github.com/yschimke/skills/compare/v0.1.8...v0.1.9) (2026-10-05)


### Features

* generated skill bundles for targeted installs ([3afae94](https://github.com/yschimke/skills/commit/3afae94f2051664c2a36e7636598b58714bd9b9c))
* generated skill bundles for targeted installs ([e4f1880](https://github.com/yschimke/skills/commit/e4f188034efa6d600222c7ba2272c699a586c8c9))


### Bug Fixes

* **compose-preview:** ask on a variantChoice, and keep sweep pixels out of the main context ([7b8b998](https://github.com/yschimke/skills/commit/7b8b998fcb0d97e01fd44601a551ab95e0037528))
* **compose-preview:** ask on a variantChoice, and keep sweep pixels out of the main context ([06ef4cc](https://github.com/yschimke/skills/commit/06ef4cc2dddbadb5d8eb5d498cace4d08474145a))

## [0.1.8](https://github.com/yschimke/skills/compare/v0.1.7...v0.1.8) (2026-10-01)


### Bug Fixes

* **compose-preview:** render first, route library components to the catalog ([0ddaa49](https://github.com/yschimke/skills/commit/0ddaa4978d151dfd9174053783b175194e568e72))
* **compose-preview:** render first, route library components to the catalog ([304fd82](https://github.com/yschimke/skills/commit/304fd823345b0824b18ba3b614e0fc7d8ddfa25a))

## [0.1.7](https://github.com/yschimke/skills/compare/v0.1.6...v0.1.7) (2026-09-30)


### Bug Fixes

* **install:** don't touch shell startup files when ~/.local/bin is already on PATH ([d575d92](https://github.com/yschimke/skills/commit/d575d92c79aed6104d3158f0154e4bd215322d37))
* **install:** don't touch shell startup files when ~/.local/bin is already on PATH ([1fa22b4](https://github.com/yschimke/skills/commit/1fa22b4bae6b903450658be6556c9870ae25689b)), closes [#108](https://github.com/yschimke/skills/issues/108)
* **install:** repair versioned MCP host entries after upgrading ([#104](https://github.com/yschimke/skills/issues/104)) ([bfb349e](https://github.com/yschimke/skills/commit/bfb349eaa767dd32ed2da4ab0b8ba8c27e9e490e))
* never fake a preview render with a hand-built mock ([#106](https://github.com/yschimke/skills/issues/106)) ([3a53a38](https://github.com/yschimke/skills/commit/3a53a38fe6a036dd39f2e548dc8efe0ab24c2e1a))

## [0.1.6](https://github.com/yschimke/skills/compare/v0.1.5...v0.1.6) (2026-09-27)


### Features

* **install:** default to compose-preview + compose-ui-builder; npx-less skill updates ([#100](https://github.com/yschimke/skills/issues/100)) ([920475f](https://github.com/yschimke/skills/commit/920475fd3be6d1415cf5e89dd3ff81b9b3e44498))


### Bug Fixes

* **install:** keep the CLI out of npx-managed skill folders ([#101](https://github.com/yschimke/skills/issues/101)) ([90f0553](https://github.com/yschimke/skills/commit/90f05538d8275577fd9cecaf1cb88158247c1cf5))
* **install:** let compose-preview update handle npx-managed skills ([#98](https://github.com/yschimke/skills/issues/98)) ([790662e](https://github.com/yschimke/skills/commit/790662e8a700ff89a9e9456dea35786d56166d04))
* **install:** put ~/.local/bin on PATH and drop old CLI versions ([#95](https://github.com/yschimke/skills/issues/95)) ([d1871c2](https://github.com/yschimke/skills/commit/d1871c20466fa1a5bec8842ad90c40131315b8e6))

## [0.1.5](https://github.com/yschimke/skills/compare/v0.1.4...v0.1.5) (2026-09-27)


### Bug Fixes

* **install:** retry skill bundle downloads ([7eb60ae](https://github.com/yschimke/skills/commit/7eb60ae638ca000099f2aa285cc8b5aea85d95c2))
* **install:** retry skill bundle downloads ([aef3c46](https://github.com/yschimke/skills/commit/aef3c4635cea0a7ac795042dae2057ad4477ef36))

## [0.1.4](https://github.com/yschimke/skills/compare/v0.1.3...v0.1.4) (2026-09-06)


### Features

* **compose-ui-builder:** a skill for authoring a design over MCP ([c6d72b1](https://github.com/yschimke/skills/commit/c6d72b185800c560939d24d30dd06842f39846d5))
* **compose-ui-builder:** a skill for authoring a design over MCP ([9d403cb](https://github.com/yschimke/skills/commit/9d403cb7e4d8fa15de374c5659cedffec0bad89b))

## [0.1.3](https://github.com/yschimke/skills/compare/v0.1.2...v0.1.3) (2026-08-22)


### Features

* add compose-preview-ci skill, covering the fork-safe two-stage split ([93f67e7](https://github.com/yschimke/skills/commit/93f67e77740c7d2a9d40a0a7c596832d02401fe8))
* add design-parity-review skill for the design-to-code direction ([62062b1](https://github.com/yschimke/skills/commit/62062b14f2792a692ae16248a833db170c7d44f1))
* freshness sweep, plus compose-preview-ci and design-parity-review skills ([2c7aabf](https://github.com/yschimke/skills/commit/2c7aabf552922a4568363950c3716928431b1921))


### Bug Fixes

* correct CLI commands, cross-repo links and install URLs that had rotted ([e32e161](https://github.com/yschimke/skills/commit/e32e1619679166b3faefdf49cb723f3132de619f))

## [0.1.2](https://github.com/yschimke/skills/compare/v0.1.1...v0.1.2) (2026-08-14)


### Features

* **design-board:** ship a reference build-design-board.py beside the skill ([98b1405](https://github.com/yschimke/skills/commit/98b14054fcc85b5569f31122ff79ce1bbf87af9b))
* **figma-catalog-import:** add the Figma catalog import skill ([d48769f](https://github.com/yschimke/skills/commit/d48769f726c51e44050ad532e53f6c6ef9bb0423))
* **figma-catalog-import:** add the Figma catalog import skill ([21a50ea](https://github.com/yschimke/skills/commit/21a50eaad77a0f15ddb6c5a9139e6bc268d24118))


### Bug Fixes

* gate installs on Maven readiness ([5b19461](https://github.com/yschimke/skills/commit/5b1946112e3f5cace17bd307caeb990533497881))
* gate installs on Maven readiness ([cea5b13](https://github.com/yschimke/skills/commit/cea5b135c56759446236d36461b1a726b7f75719))
* **install:** fall back to the API asset endpoint when github.com is blocked ([9b00380](https://github.com/yschimke/skills/commit/9b0038005cd164e1e37ad45d412de79dff16ee1d))
* **install:** probe releases with a ranged GET, and fall back to the repo-scoped API ([7e3cdb9](https://github.com/yschimke/skills/commit/7e3cdb9662843f30f9b30da4d1d43560dd314d51))
* **install:** probe releases with a ranged GET, and fall back to the repo-scoped API ([7c7dae7](https://github.com/yschimke/skills/commit/7c7dae7669f4c31db07e98932c5d1dd1cd861a6b))
* **install:** stop the JDK precondition from gating --android-sdk ([4eeb52e](https://github.com/yschimke/skills/commit/4eeb52ee6f8dda4436f0961415d573c3ff31c880))
* **install:** stop the JDK precondition from gating --android-sdk ([3bdea47](https://github.com/yschimke/skills/commit/3bdea4722b05bb948f38fe00686db9cd3a27f5a6))
* **install:** survive proxied sandboxes, and document the adoption gaps found cataloguing compose-samples ([f48cb5d](https://github.com/yschimke/skills/commit/f48cb5d63dba22303a18e284375ea90d90580f27))
* portable find in install.sh, and sync skills with upstream ([5f3b5cc](https://github.com/yschimke/skills/commit/5f3b5cca8f6961ea4515b8a375576033c0e9f20c))
* require CLI plugin availability ([de215b5](https://github.com/yschimke/skills/commit/de215b5be6f12c6f8aa9aa5722bae7b14da21e93))
* resolve latest CLI release via releases.atom feed ([90b829b](https://github.com/yschimke/skills/commit/90b829b5429cad058db2d2c6b9ca19f36e0a42de))
* resolve latest CLI release via releases.atom feed ([6221e37](https://github.com/yschimke/skills/commit/6221e372575172a31e4858678b87a4c51f79e838))
* skip incomplete CLI releases ([9b5c441](https://github.com/yschimke/skills/commit/9b5c441c86a1ad1b5f130db57823f223914b65ed))
* skip incomplete CLI releases ([305eff1](https://github.com/yschimke/skills/commit/305eff1708654532de2b658112aba55c776d4cce))
* use portable find in install.sh skill refresh ([b8c75fa](https://github.com/yschimke/skills/commit/b8c75fa31b29f373ccb0733b9056c55e05f6bab0))
* verify plugin implementation availability ([337cabd](https://github.com/yschimke/skills/commit/337cabdaab6aaa2877b5f7610f8b78189340c663))

## [0.1.1](https://github.com/yschimke/skills/compare/v0.1.0...v0.1.1) (2026-05-14)


### Features

* import scripts/install.sh ([577543f](https://github.com/yschimke/skills/commit/577543f813fe557bed7cd550474f18a488a04d43))
* initial import of compose-preview skills ([8cfbe0d](https://github.com/yschimke/skills/commit/8cfbe0d09c4bc7d310528d6911d208d973571644))
