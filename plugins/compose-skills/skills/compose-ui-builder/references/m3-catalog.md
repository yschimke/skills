# The published catalogs, in the form an insert needs

Everything a `ui_builder_apply` needs to be right: the component ids, the slot
names a child goes into, which properties are required, and which are closed
enums (their allowed values follow the property in brackets). Extracted from
`ui_builder_list_catalogs` on compose-preview-server 3.121.0 (preview.coo.ee,
2026-10-11).

Treat it as a fast path, not as the contract. The server is the authority: a
component here that the server refuses, or one you need that is missing, means
this file has aged behind the catalog — regenerate it with the recipe at the
bottom.

A design pins exactly one catalog and cannot mix them. The three this skill
covers:

| Catalog | For | Table |
| --- | --- | --- |
| **`m3-catalog`** | Material 3 for a phone, tablet or desktop screen. 132 components. | below |
| **`wear-m3`** | A Wear OS app screen: screen scaffold, transforming lazy column, edge button, cards, pickers. 89 components. | [wear-m3-catalog.md](./wear-m3-catalog.md) |
| **`remote-m3`** | A Wear widget: the widget scaffolds and what renders inside them. 60 components. | [remote-m3-catalog.md](./remote-m3-catalog.md) |

The same host also lists `remote-widgets`, `a2ui-catalog` and
`glimmer-catalog` (glasses). Read those out of `ui_builder_list_catalogs` when
a task names one.

## Pins

A document's `catalogPin` must name a catalog revision the server serves, and a
pin you invent is refused (`catalogUnavailable`). Verified against 3.121.0:

| Catalog | `catalogRevision` | `nativeRuntimeId` |
| --- | --- | --- |
| `m3-catalog` | `"candidate"` | `"candidate"` |
| `remote-m3` | `"wear-widget-scaffolds-v1"` | `"candidate"` |
| `wear-m3` | none that is stable: copy `catalogPin` from `ui_builder_list_catalogs` | the same |

`wear-m3` has no `candidate` alias, and `"candidate"` is refused. Its pin is a
content hash (`sha256:…`) that changes with every catalog release, so read the
whole `catalogPin` object out of the `wear-m3` entry of `ui_builder_list_catalogs`
and paste it unchanged. Do the same for any catalog whose pin above stops
working. `capabilityDigest` is `"candidate"` throughout.

`role` decides where a node may go: a `Scaffold` is a root, a `Container` has
slots, a `Leaf` has none. A slot lists what it accepts, so a `Leaf` cannot take
children and the service will say so. A slot that needs at least one child shows
its count in brackets (`content (1..*)`); see
[Slots have a cardinality](#slots-have-a-cardinality). A property with no
allowed values takes its value kind from its name: `…Color` is a `color`, `…Dp`
and `…Sp` are a `float`, `enabled` is a `bool`.

## `m3-catalog`

<!-- m3-catalog sha256:a186b4bd8ca83b7bf3abb9a769e9dc52, 132 components -->
| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey` | `contentDescription`, `contentScale` (crop, fit, fillBounds, inside), `alignment` |
| `confetti-mobile/confetti-background` | Container | `content` | — | `color`, `tonalElevationDp` |
| `layout/box` | Container | `children` | — | `contentAlignment`, `propagateMinConstraints` |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/flow-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `maxItemsInEachRow`, `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/for-each` | Container | `template` (1..1) | `data` | `verticalSpacingDp` |
| `layout/horizontal-carousel` | Container | `items` (1..*) | `itemWidthDp`, `scrollStateKey` | `itemSpacingDp`, `contentPaddingStartDp`, `kind`, `span` |
| `layout/lazy-column` | Container | `items` | `scrollStateKey` | `contentPadding`, `verticalSpacingDp`, `reverseLayout` |
| `layout/lazy-grid` | Container | `items` | `columns`, `scrollStateKey` | `horizontalSpacingDp`, `verticalSpacingDp`, `contentPadding`, `itemSpans` |
| `layout/lazy-row` | Container | `items` | — | `contentPadding`, `horizontalSpacingDp`, `scrollStateKey`, `span`, `stableKey` |
| `layout/list-detail-pane-scaffold` | Scaffold | `listPane` (1..1), `detailPane`, `extraPane` | `layoutMode` (adaptive, expandedTwoPane, singlePane, twoPane), `listPaneVisible`, `detailPaneVisible` | `activePaneIndex`, `listPanePreferredWidthDp`, `detailPanePreferredWidthDp`, `paneSpacingDp`, `paneSizing` (preferred, fixedStart, fixedEnd, split), `fixedPaneWidthDp`, `splitFraction`, `extraPanePreferredWidthDp`, `activePane` (list, detail, extra) |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalAlignment` (top, center, bottom) |
| `layout/scaffold` | Scaffold | `topBar`, `snackbarHost`, `content` (1..1) | — | `containerColor`, `contentWindowInsets`, `loading`, `scrollStateKey` |
| `layout/supporting-pane-scaffold` | Scaffold | `mainPane` (1..1), `supportingPane` | `layoutMode` (adaptive, expandedTwoPane, singlePane, twoPane), `mainPaneVisible`, `supportingPaneVisible` | `mainPanePreferredWidthDp`, `supportingPanePreferredWidthDp`, `paneSpacingDp`, `paneSizing` (preferred, fixedStart, fixedEnd, split), `fixedPaneWidthDp`, `splitFraction` |
| `m3/adaptive-sticker` | Container | `content` | — | — |
| `m3/animated-pane` | Container | `dragToResizeHandle`, `content` | — | — |
| `m3/app-bar-with-search` | Container | `inputField`, `navigationIcon`, `actions` | — | `shape`, `tonalElevationDp`, `shadowElevationDp` |
| `m3/assist-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | — | `enabled`, `shape` |
| `m3/badge` | Container | `content` | — | `containerColor`, `contentColor` |
| `m3/bottom-app-bar` | Container | `actions`, `floatingActionButton` | — | `containerColor`, `contentColor`, `tonalElevationDp` |
| `m3/button` | Container | `content` (1..*) | `style` (filled, filledTonal, text, fab) | `enabled`, `selected`, `containerColor`, `onClickAction`, `shape` |
| `m3/card` | Container | `content` (1..*) | — | `containerColor`, `shape`, `stableKey`, `elevationDp`, `onClickAction` |
| `m3/center-aligned-top-app-bar` | Container | `title` | — | `containerColor`, `scrolledContainerColor`, `scrollBehavior` (pinned, enterAlways, exitUntilCollapsed), `expandedHeightDp` |
| `m3/centered-track` | Leaf | — | — | `enabled`, `thumbTrackGapSizeDp`, `trackInsideCornerSizeDp`, `trackCornerSizeDp` |
| `m3/checkbox` | Leaf | — | — | `checked`, `enabled` |
| `m3/circular-progress-indicator` | Leaf | — | — | `progress`, `indeterminate`, `color`, `strokeWidthDp`, `trackColor`, `gapSizeDp` |
| `m3/circular-wavy-progress-indicator` | Leaf | — | — | `color`, `trackColor`, `gapSizeDp`, `wavelengthDp`, `waveSpeedDp` |
| `m3/contained-loading-indicator` | Leaf | — | — | `containerColor`, `indicatorColor`, `containerShape` |
| `m3/current-scheme` | Leaf | — | — | — |
| `m3/date-picker` | Leaf | — | `mode` (picker, input), `selectedDate` | `showModeToggle` |
| `m3/date-picker-dialog` | Container | `confirmButton`, `dismissButton`, `content` | — | `shape`, `tonalElevationDp` |
| `m3/date-range-picker` | Container | `title`, `headline` | — | `showModeToggle` |
| `m3/dialog` | Container | `icon`, `title`, `text`, `dismissButton`, `confirmButton` (1..1) | — | `containerColor`, `tonalElevationDp`, `shapeDp`, `shape`, `iconContentColor`, `titleContentColor`, `textContentColor` |
| `m3/display-mode-toggle` | Leaf | — | — | — |
| `m3/docked-search-bar` | Container | `inputField`, `content` | `expanded` | `shape`, `tonalElevationDp`, `shadowElevationDp` |
| `m3/dropdown-menu-group` | Container | `content` | — | `containerColor`, `tonalElevationDp`, `shadowElevationDp` |
| `m3/dropdown-menu-item` | Container | `text`, `leadingIcon`, `trailingIcon`, `supportingText` | `shape` | `enabled` |
| `m3/elevated-assist-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | — | `enabled`, `shape` |
| `m3/elevated-button` | Container | `content` | — | `enabled`, `shape` |
| `m3/elevated-card` | Container | `content` (1..*) | — | `containerColor`, `shape`, `stableKey`, `elevationDp`, `onClickAction` |
| `m3/elevated-filter-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | `selected` | `enabled`, `shape` |
| `m3/elevated-leading-button` | Container | `content` | — | `enabled` |
| `m3/elevated-suggestion-chip` | Container | `label`, `icon` | — | `enabled`, `shape` |
| `m3/elevated-toggle-button` | Container | `content` | `checked` | `enabled` |
| `m3/elevated-trailing-button` | Container | `content` | `checked` | `enabled` |
| `m3/extended-floating-action-button` | Container | `text`, `icon` | — | `expanded`, `shape`, `containerColor`, `contentColor` |
| `m3/filled-icon-button` | Container | `content` (1..1) | — | `enabled`, `selected`, `alignment`, `contentDescription`, `sizeDp`, `onClickAction`, `shape` |
| `m3/filled-tonal-button` | Container | `content` | — | `enabled`, `shape` |
| `m3/filled-tonal-icon-button` | Container | `content` (1..1) | — | `enabled`, `selected`, `alignment`, `contentDescription`, `sizeDp`, `onClickAction`, `shape` |
| `m3/filter-chip` | Container | `label` (1..1), `leadingIcon` | `selected` | `enabled`, `shape`, `onClickAction` |
| `m3/floating-action-button` | Container | `content` | — | `shape`, `containerColor`, `contentColor` |
| `m3/horizontal-centered-hero-carousel` | Container | `content` | — | `maxItemWidthDp`, `itemSpacingDp`, `userScrollEnabled`, `minSmallItemWidthDp`, `maxSmallItemWidthDp` |
| `m3/horizontal-divider` | Leaf | — | — | `thicknessDp`, `color` |
| `m3/horizontal-floating-toolbar` | Container | `content` (1..*) | — | `expanded`, `containerColor`, `contentPadding`, `alignment`, `shape`, `expandedShadowElevationDp`, `collapsedShadowElevationDp` |
| `m3/horizontal-multi-browse-carousel` | Container | `content` | `preferredItemWidthDp` | `itemSpacingDp`, `userScrollEnabled`, `minSmallItemWidthDp`, `maxSmallItemWidthDp` |
| `m3/horizontal-uncontained-carousel` | Container | `content` | `itemWidthDp` | `itemSpacingDp`, `userScrollEnabled` |
| `m3/icon` | Leaf | — | `iconKey` | `iconName`, `iconStyle` (outlined, rounded, sharp), `iconFill`, `iconWeight`, `iconGrade`, `iconOpticalSize`, `iconAutoMirror`, `contentDescription`, `sizeDp`, `color`, `tint` |
| `m3/icon-button` | Container | `content` (1..1) | — | `enabled`, `selected`, `alignment`, `contentDescription`, `sizeDp`, `onClickAction` |
| `m3/input-chip` | Container | `label`, `leadingIcon`, `avatar`, `trailingIcon` | `selected` | `enabled`, `shape` |
| `m3/large-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded`, `shape`, `containerColor`, `contentColor` |
| `m3/large-floating-action-button` | Container | `content` | — | `shape`, `containerColor`, `contentColor` |
| `m3/large-top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `collapsedHeightDp`, `expandedHeightDp` |
| `m3/leading-button` | Container | `content` | — | `enabled` |
| `m3/linear-progress-indicator` | Leaf | — | — | `progress`, `indeterminate`, `color`, `trackColor`, `gapSizeDp` |
| `m3/linear-wavy-progress-indicator` | Leaf | — | — | `color`, `trackColor`, `gapSizeDp`, `stopSizeDp`, `wavelengthDp`, `waveSpeedDp` |
| `m3/list-detail-pane-scaffold` | Container | `listPane`, `detailPane`, `extraPane`, `paneExpansionDragHandle` | — | — |
| `m3/list-item` | Container | `headline` (1..1), `supporting`, `trailing` | — | `startAccentColor`, `tonalElevationDp`, `shadowElevationDp` |
| `m3/loading-indicator` | Leaf | — | — | `color` |
| `m3/medium-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded`, `shape`, `containerColor`, `contentColor` |
| `m3/medium-floating-action-button` | Container | `content` | — | `shape`, `containerColor`, `contentColor` |
| `m3/medium-top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `collapsedHeightDp`, `expandedHeightDp` |
| `m3/multi-choice-segmented-button-row` | Container | `content` | — | `spaceDp` |
| `m3/navigation-suite-item` | Container | `icon` (1..1), `label` | `selected` | `enabled` |
| `m3/navigation-suite-scaffold` | Scaffold | `navigationItems` (1..*), `primaryAction`, `content` (1..*) | — | `containerColor`, `contentColor` |
| `m3/outlined-button` | Container | `content` | — | `enabled`, `shape` |
| `m3/outlined-card` | Container | `content` (1..*) | — | `containerColor`, `shape`, `stableKey`, `elevationDp`, `onClickAction` |
| `m3/outlined-icon-button` | Container | `content` (1..1) | — | `enabled`, `selected`, `alignment`, `contentDescription`, `sizeDp`, `onClickAction`, `shape` |
| `m3/outlined-leading-button` | Container | `content` | — | `enabled` |
| `m3/outlined-text-field` | Container | `label`, `placeholder`, `supportingText`, `leadingIcon`, `trailingIcon` | — | `value`, `enabled`, `readOnly`, `singleLine`, `isError`, `shape` |
| `m3/outlined-toggle-button` | Container | `content` | `checked` | `enabled` |
| `m3/outlined-trailing-button` | Container | `content` | `checked` | `enabled` |
| `m3/primary-scrollable-tab-row` | Container | `tabs` (1..*) | `selectedIndex`, `selectedTabIndex` | `containerColor`, `contentColor`, `edgePaddingDp`, `minTabWidthDp` |
| `m3/primary-tab-row` | Container | `tabs` (1..*) | `selectedIndex`, `selectedTabIndex` | `containerColor`, `contentColor` |
| `m3/provide-text-style` | Container | `content` | — | — |
| `m3/radio-button` | Leaf | — | — | `selected`, `enabled` |
| `m3/range-slider` | Leaf | — | — | `enabled`, `steps` |
| `m3/search-bar` | Container | `inputField` (1..1), `expandedContent` | `expanded` | `shapeDp`, `tonalElevationDp`, `shape`, `shadowElevationDp` |
| `m3/search-input-field` | Container | `placeholder`, `leadingIcon`, `trailingIcon` | `value` | `enabled`, `readOnly`, `onQueryChangeAction`, `onSearchAction`, `shape` |
| `m3/secondary-scrollable-tab-row` | Container | `indicator`, `divider`, `tabs` | `selectedTabIndex` | `containerColor`, `contentColor`, `edgePaddingDp`, `minTabWidthDp` |
| `m3/secondary-tab-row` | Container | `indicator`, `divider`, `tabs` | `selectedTabIndex` | `containerColor`, `contentColor` |
| `m3/segmented-button` | Container | `icon`, `label` | `checked`, `shape` | `enabled` |
| `m3/short-navigation-bar` | Container | `content` | — | `containerColor`, `contentColor` |
| `m3/short-navigation-bar-item` | Container | `icon`, `label` | `selected` | `enabled` |
| `m3/single-choice-segmented-button-row` | Container | `content` | — | `spaceDp` |
| `m3/slider` | Leaf | — | `value` | `valueFrom`, `valueTo`, `steps`, `enabled` |
| `m3/small-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded`, `shape`, `containerColor`, `contentColor` |
| `m3/small-floating-action-button` | Container | `content` | — | `shape`, `containerColor`, `contentColor` |
| `m3/snackbar` | Container | `action`, `dismissAction`, `content` | — | `actionOnNewLine`, `shape`, `containerColor`, `contentColor`, `actionContentColor`, `dismissActionContentColor` |
| `m3/snackbar-host` | Container | `snackbar` | `visible` | `message`, `actionLabel` |
| `m3/split-button-layout` | Container | `leadingButton`, `trailingButton` | — | `spacingDp` |
| `m3/suggestion-chip` | Container | `label`, `icon` | — | `enabled`, `shape` |
| `m3/supporting-pane-scaffold` | Container | `mainPane`, `supportingPane`, `extraPane`, `paneExpansionDragHandle` | — | — |
| `m3/surface` | Container | `content` | — | `containerColor`, `contentColor`, `shapeDp`, `tonalElevationDp`, `themeTypeScale`, `themeCornerRadiusDp`, `themeDisplayTypeface`, `themeHeadlineTypeface`, `themeTitleTypeface`, `themeBodyTypeface`, `themeLabelTypeface`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, labelLarge, labelMedium, labelSmall), `shape`, `color`, `shadowElevationDp`, 4 `theme…Color` roles |
| `m3/switch` | Leaf | — | — | `checked`, `enabled` |
| `m3/tab` | Container | `text` (1..1) | `selected` | `enabled`, `selectedContentColor`, `unselectedContentColor` |
| `m3/text` | Leaf | — | `text` | `style` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, labelLarge, labelMedium, labelSmall), `fontWeight` (normal, medium, semiBold, bold), `fontStyle` (normal, italic), `color`, `fontSizeSp`, `lineHeightSp`, `letterSpacingSp`, `minLines`, `maxLines`, `softWrap`, `overflow` (clip, ellipsis, visible), `textAlign` (start, center, end, justify), `textDecoration` (none, underline, lineThrough), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight`, `fontVariationSettings`, `fontFeatureSettings` |
| `m3/text-button` | Container | `content` | — | `enabled`, `shape` |
| `m3/text-field` | Container | `label`, `placeholder`, `supportingText`, `leadingIcon`, `trailingIcon` | — | `value`, `enabled`, `readOnly`, `singleLine`, `isError`, `shape` |
| `m3/thumb` | Leaf | — | — | `enabled` |
| `m3/time-input` | Leaf | — | — | — |
| `m3/time-picker` | Leaf | — | `mode` (dial, input), `hour`, `minute` | `is24Hour` |
| `m3/title` | Leaf | — | — | — |
| `m3/toggle-button` | Container | `content` | `checked` | `enabled` |
| `m3/tonal-leading-button` | Container | `content` | — | `enabled` |
| `m3/tonal-toggle-button` | Container | `content` | `checked` | `enabled` |
| `m3/tonal-trailing-button` | Container | `content` | `checked` | `enabled` |
| `m3/top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `expandedHeightDp` |
| `m3/track` | Leaf | — | `trackCornerSizeDp` | `enabled`, `thumbTrackGapSizeDp`, `trackInsideCornerSizeDp` |
| `m3/trailing-button` | Container | `content` | — | `enabled` |
| `m3/tri-state-checkbox` | Leaf | — | — | `enabled` |
| `m3/variable-font-text` | Leaf | — | `text` | `font` (robotoFlex, googleSansFlex), `wght`, `wdth`, `slnt`, `rond`, `fontSizeSp`, `color` |
| `m3/vertical-divider` | Leaf | — | — | `thicknessDp`, `color` |
| `m3/vertical-floating-toolbar` | Container | `leadingContent`, `trailingContent`, `content` | `expanded` | `shape`, `expandedShadowElevationDp`, `collapsedShadowElevationDp` |
| `m3/vertical-slider` | Container | `thumb`, `track` | — | `enabled`, `reverseDirection` |
| `m3/wide-navigation-rail` | Container | `header`, `content` | — | `shape` |
| `m3/wide-navigation-rail-item` | Container | `icon`, `label` | `selected`, `railExpanded` | `enabled` |
| `remote-compose/custom` | Container | `content` | `name` | `widthDp`, `heightDp` |
| `remote-compose/document` | Container | — | — | `documentBase64`, `documentUrl`, `theme` (inherit, light, dark, system), `namedValues` |
| `remote-compose/inline` | Container | `content` | — | `theme` (inherit, light, dark, system) |
| `shape/colour-dot` | Leaf | — | `color` | `diameterDp` |
| `shape/linear-gradient` | Leaf | — | `startColor`, `endColor` | `direction` |
| `shape/radial-gradient` | Leaf | — | `innerColor`, `outerColor` | `innerAlpha`, `center` |

### Text fields

`m3/text-field` (filled) and `m3/outlined-text-field` are separate components;
neither takes a `variant`. Put the label text in an `m3/text` in the `label`
slot. As of 3.121.0, prefer `m3/text-field`:

- `m3/outlined-text-field` passes `ui_builder_check_design`, but the editor
  canvas draws it as "Unsupported component". Look at it with
  `ui_builder_view` before you keep one.
- Both declare `singleLine`, but the Compose export gate refuses it on the
  outlined field, in a finding with no `nodeId`. Leave it unset.

Neither has a password mode, so a password field is a plain text field with a
comment saying so.

## The exporter is a second opinion

A component being in the table above means the **document** accepts it. Whether
the Compose generator can write it is a separate question, answered per node by
`ui_builder_export`:

```json
{"severity": "error", "code": "UNPROVEN_CALL_SITE",
 "message": "no component `m3/list-item` in this catalog"}
```

Nothing is wrong with the design when this happens — it renders, it opens in the
browser, a designer can carry on with it. Only the Kotlin for that node is
withheld. Which components a given host can write changes as the generator's
records grow, so there is no list here worth trusting: **export once after the
first structural batch** and let the diagnostics tell you, while a swap is still
one operation.

## Slots have a cardinality

A slot can require a child. `m3/button`'s `content` is `min: 1`, so inserting an
empty button is refused:

```json
{"code": "invalidDocument", "message": "slot content has 0 children; expected 1..unbounded",
 "nodeId": "p-button", "field": "content"}
```

Insert the container and its child in the **same** `apply` call — the batch is
atomic, so the pair either lands together or nothing lands at all.

## Regenerating this file

`ui_builder_list_catalogs` answers with every catalog, its `catalogPin`, its
modifiers, and each component's slots (`name[min..max]:accepted`) and
properties (`name:kind`, `!` for required, `=a|b|c` for the allowed values) —
far more than is worth reading into a conversation. Save the result to a file
(most hosts do this for you when a result is oversized) and print one catalog
as the table above:

```sh
python3 - "$SAVED_RESULT" m3-catalog <<'EOF'
import json, sys
text = open(sys.argv[1]).read()
catalogs = json.loads(text[text.index('{'):])['catalogs']
catalog = next(c for c in catalogs if c['systemId'] == sys.argv[2])
print(f"<!-- {catalog['systemId']} {catalog['catalogPin']['catalogRevision']}, {len(catalog['components'])} components -->")
print("| `componentId` | role | slots | required | other properties |")
print("| --- | --- | --- | --- | --- |")
for comp in sorted(catalog['components'], key=lambda c: c['id']):
    slots = []
    for slot in comp.get('slots', []):
        name, cardinality = slot.split('[')[0], slot.split('[')[1].split(']')[0]
        slots.append(f"`{name}`" + ("" if cardinality.startswith('0..') else f" ({cardinality})"))
    required, other, theme = [], [], 0
    for p in comp.get('properties', []):
        name, _, rest = p.partition(':')
        kind, _, allowed = rest.partition('=')
        if name.startswith('theme') and name.endswith('Color'):
            theme += 1
            continue
        cell = f"`{name}`" + (f" ({allowed.replace('|', ', ')})" if allowed else "")
        (required if kind.endswith('!') else other).append(cell)
    if theme:
        other.append(f"{theme} `theme…Color` roles")
    print(f"| `{comp['id']}` | {comp['role']} | {', '.join(slots) or '—'} | "
          f"{', '.join(required) or '—'} | {', '.join(other) or '—'} |")
EOF
```

The same script prints `wear-m3`, `remote-m3`, or any other catalog the host
publishes.

## What is *not* here

`modifierCapabilities` (which modifiers each component accepts), the `wasm`
adapter status, the `svg` parity status and each component's `code` symbol and
imports all live in the full response. Reach for them when a modifier is refused
or an SVG export is gated; day-to-day authoring does not need them.
