# The published catalogs, in the form an insert needs

Everything a `ui_builder_apply` needs to be right: the component ids, the slot
names a child goes into, which properties are required, and the kind of value
each takes. Extracted from
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
[Slots have a cardinality](#slots-have-a-cardinality).

Each property shows the `type` its wrapped value takes: `text: string` is
`{"type": "string", "value": …}`, `steps: int` is `{"type": "int", …}`. A
property with allowed values in brackets is an `enum`. `or` lists the kinds a
property accepts; `object` there is a binding or a structured value, so for a
literal use the other kind (`value: float or object` takes
`{"type": "float", "value": 0.4}`).

## `m3-catalog`

<!-- m3-catalog sha256:a186b4bd8ca83b7bf3abb9a769e9dc52, 132 components -->
| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey: string` | `contentDescription: string or null`, `contentScale` (crop, fit, fillBounds, inside), `alignment: string` |
| `confetti-mobile/confetti-background` | Container | `content` | — | `color: string`, `tonalElevationDp: float` |
| `layout/box` | Container | `children` | — | `contentAlignment: string`, `propagateMinConstraints: bool` |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/flow-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `maxItemsInEachRow: float`, `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/for-each` | Container | `template` (1..1) | `data: object` | `verticalSpacingDp: float` |
| `layout/horizontal-carousel` | Container | `items` (1..*) | `itemWidthDp: float`, `scrollStateKey: string` | `itemSpacingDp: float`, `contentPaddingStartDp: float`, `kind: string`, `span: string` |
| `layout/lazy-column` | Container | `items` | `scrollStateKey: string` | `contentPadding: object`, `verticalSpacingDp: float`, `reverseLayout: bool` |
| `layout/lazy-grid` | Container | `items` | `columns: object`, `scrollStateKey: string` | `horizontalSpacingDp: float`, `verticalSpacingDp: float`, `contentPadding: object`, `itemSpans: object` |
| `layout/lazy-row` | Container | `items` | — | `contentPadding: object`, `horizontalSpacingDp: float`, `scrollStateKey: string`, `span: string`, `stableKey: string` |
| `layout/list-detail-pane-scaffold` | Scaffold | `listPane` (1..1), `detailPane`, `extraPane` | `layoutMode` (adaptive, expandedTwoPane, singlePane, twoPane), `listPaneVisible: bool`, `detailPaneVisible: bool` | `activePaneIndex: int`, `listPanePreferredWidthDp: float`, `detailPanePreferredWidthDp: float`, `paneSpacingDp: float`, `paneSizing` (preferred, fixedStart, fixedEnd, split), `fixedPaneWidthDp: float`, `splitFraction: float`, `extraPanePreferredWidthDp: float`, `activePane` (list, detail, extra) |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalAlignment` (top, center, bottom) |
| `layout/scaffold` | Scaffold | `topBar`, `snackbarHost`, `content` (1..1) | — | `containerColor: color`, `contentWindowInsets: array`, `loading: bool`, `scrollStateKey: string` |
| `layout/supporting-pane-scaffold` | Scaffold | `mainPane` (1..1), `supportingPane` | `layoutMode` (adaptive, expandedTwoPane, singlePane, twoPane), `mainPaneVisible: bool`, `supportingPaneVisible: bool` | `mainPanePreferredWidthDp: float`, `supportingPanePreferredWidthDp: float`, `paneSpacingDp: float`, `paneSizing` (preferred, fixedStart, fixedEnd, split), `fixedPaneWidthDp: float`, `splitFraction: float` |
| `m3/adaptive-sticker` | Container | `content` | — | — |
| `m3/animated-pane` | Container | `dragToResizeHandle`, `content` | — | — |
| `m3/app-bar-with-search` | Container | `inputField`, `navigationIcon`, `actions` | — | `shape: string`, `tonalElevationDp: float`, `shadowElevationDp: float` |
| `m3/assist-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | — | `enabled: bool`, `shape: string` |
| `m3/badge` | Container | `content` | — | `containerColor: color`, `contentColor: color` |
| `m3/bottom-app-bar` | Container | `actions`, `floatingActionButton` | — | `containerColor: color`, `contentColor: color`, `tonalElevationDp: float` |
| `m3/button` | Container | `content` (1..*) | `style` (filled, filledTonal, text, fab) | `enabled: bool`, `selected: bool or string or object`, `containerColor: color`, `onClickAction: object or null`, `shape: string` |
| `m3/card` | Container | `content` (1..*) | — | `containerColor: color`, `shape: string`, `stableKey: string`, `elevationDp: float`, `onClickAction: object or null` |
| `m3/center-aligned-top-app-bar` | Container | `title` | — | `containerColor: color`, `scrolledContainerColor: color`, `scrollBehavior` (pinned, enterAlways, exitUntilCollapsed), `expandedHeightDp: float` |
| `m3/centered-track` | Leaf | — | — | `enabled: bool`, `thumbTrackGapSizeDp: float`, `trackInsideCornerSizeDp: float`, `trackCornerSizeDp: float` |
| `m3/checkbox` | Leaf | — | — | `checked: bool or string or object`, `enabled: bool` |
| `m3/circular-progress-indicator` | Leaf | — | — | `progress: float or object`, `indeterminate: bool`, `color: string`, `strokeWidthDp: float`, `trackColor: color`, `gapSizeDp: float` |
| `m3/circular-wavy-progress-indicator` | Leaf | — | — | `color: string`, `trackColor: color`, `gapSizeDp: float`, `wavelengthDp: float`, `waveSpeedDp: float` |
| `m3/contained-loading-indicator` | Leaf | — | — | `containerColor: color`, `indicatorColor: color`, `containerShape: string` |
| `m3/current-scheme` | Leaf | — | — | — |
| `m3/date-picker` | Leaf | — | `mode` (picker, input), `selectedDate: string` | `showModeToggle: bool` |
| `m3/date-picker-dialog` | Container | `confirmButton`, `dismissButton`, `content` | — | `shape: string`, `tonalElevationDp: float` |
| `m3/date-range-picker` | Container | `title`, `headline` | — | `showModeToggle: bool` |
| `m3/dialog` | Container | `icon`, `title`, `text`, `dismissButton`, `confirmButton` (1..1) | — | `containerColor: color`, `tonalElevationDp: float`, `shapeDp: float`, `shape: string`, `iconContentColor: color`, `titleContentColor: color`, `textContentColor: color` |
| `m3/display-mode-toggle` | Leaf | — | — | — |
| `m3/docked-search-bar` | Container | `inputField`, `content` | `expanded: bool` | `shape: string`, `tonalElevationDp: float`, `shadowElevationDp: float` |
| `m3/dropdown-menu-group` | Container | `content` | — | `containerColor: color`, `tonalElevationDp: float`, `shadowElevationDp: float` |
| `m3/dropdown-menu-item` | Container | `text`, `leadingIcon`, `trailingIcon`, `supportingText` | `shape: string` | `enabled: bool` |
| `m3/elevated-assist-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | — | `enabled: bool`, `shape: string` |
| `m3/elevated-button` | Container | `content` | — | `enabled: bool`, `shape: string` |
| `m3/elevated-card` | Container | `content` (1..*) | — | `containerColor: color`, `shape: string`, `stableKey: string`, `elevationDp: float`, `onClickAction: object or null` |
| `m3/elevated-filter-chip` | Container | `label`, `leadingIcon`, `trailingIcon` | `selected: bool` | `enabled: bool`, `shape: string` |
| `m3/elevated-leading-button` | Container | `content` | — | `enabled: bool` |
| `m3/elevated-suggestion-chip` | Container | `label`, `icon` | — | `enabled: bool`, `shape: string` |
| `m3/elevated-toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/elevated-trailing-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/extended-floating-action-button` | Container | `text`, `icon` | — | `expanded: bool`, `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/filled-icon-button` | Container | `content` (1..1) | — | `enabled: bool`, `selected: bool`, `alignment: string`, `contentDescription: string or null`, `sizeDp: float`, `onClickAction: object or null`, `shape: string` |
| `m3/filled-tonal-button` | Container | `content` | — | `enabled: bool`, `shape: string` |
| `m3/filled-tonal-icon-button` | Container | `content` (1..1) | — | `enabled: bool`, `selected: bool`, `alignment: string`, `contentDescription: string or null`, `sizeDp: float`, `onClickAction: object or null`, `shape: string` |
| `m3/filter-chip` | Container | `label` (1..1), `leadingIcon` | `selected: bool or string or object` | `enabled: bool`, `shape: string`, `onClickAction: object or null` |
| `m3/floating-action-button` | Container | `content` | — | `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/horizontal-centered-hero-carousel` | Container | `content` | — | `maxItemWidthDp: float`, `itemSpacingDp: float`, `userScrollEnabled: bool`, `minSmallItemWidthDp: float`, `maxSmallItemWidthDp: float` |
| `m3/horizontal-divider` | Leaf | — | — | `thicknessDp: float`, `color: string` |
| `m3/horizontal-floating-toolbar` | Container | `content` (1..*) | — | `expanded: bool`, `containerColor: color`, `contentPadding: object`, `alignment: string`, `shape: string`, `expandedShadowElevationDp: float`, `collapsedShadowElevationDp: float` |
| `m3/horizontal-multi-browse-carousel` | Container | `content` | `preferredItemWidthDp: float` | `itemSpacingDp: float`, `userScrollEnabled: bool`, `minSmallItemWidthDp: float`, `maxSmallItemWidthDp: float` |
| `m3/horizontal-uncontained-carousel` | Container | `content` | `itemWidthDp: float` | `itemSpacingDp: float`, `userScrollEnabled: bool` |
| `m3/icon` | Leaf | — | `iconKey: string` | `iconName: string`, `iconStyle` (outlined, rounded, sharp), `iconFill: float`, `iconWeight: float`, `iconGrade: float`, `iconOpticalSize: float`, `iconAutoMirror: bool`, `contentDescription: string or null`, `sizeDp: float`, `color: string`, `tint: string` |
| `m3/icon-button` | Container | `content` (1..1) | — | `enabled: bool`, `selected: bool`, `alignment: string`, `contentDescription: string or null`, `sizeDp: float`, `onClickAction: object or null` |
| `m3/input-chip` | Container | `label`, `leadingIcon`, `avatar`, `trailingIcon` | `selected: bool` | `enabled: bool`, `shape: string` |
| `m3/large-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded: bool`, `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/large-floating-action-button` | Container | `content` | — | `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/large-top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `collapsedHeightDp: float`, `expandedHeightDp: float` |
| `m3/leading-button` | Container | `content` | — | `enabled: bool` |
| `m3/linear-progress-indicator` | Leaf | — | — | `progress: float or object`, `indeterminate: bool`, `color: string`, `trackColor: color`, `gapSizeDp: float` |
| `m3/linear-wavy-progress-indicator` | Leaf | — | — | `color: string`, `trackColor: color`, `gapSizeDp: float`, `stopSizeDp: float`, `wavelengthDp: float`, `waveSpeedDp: float` |
| `m3/list-detail-pane-scaffold` | Container | `listPane`, `detailPane`, `extraPane`, `paneExpansionDragHandle` | — | — |
| `m3/list-item` | Container | `headline` (1..1), `supporting`, `trailing` | — | `startAccentColor: color`, `tonalElevationDp: float`, `shadowElevationDp: float` |
| `m3/loading-indicator` | Leaf | — | — | `color: string` |
| `m3/medium-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded: bool`, `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/medium-floating-action-button` | Container | `content` | — | `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/medium-top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `collapsedHeightDp: float`, `expandedHeightDp: float` |
| `m3/multi-choice-segmented-button-row` | Container | `content` | — | `spaceDp: float` |
| `m3/navigation-suite-item` | Container | `icon` (1..1), `label` | `selected: bool or string or object` | `enabled: bool` |
| `m3/navigation-suite-scaffold` | Scaffold | `navigationItems` (1..*), `primaryAction`, `content` (1..*) | — | `containerColor: color`, `contentColor: color` |
| `m3/outlined-button` | Container | `content` | — | `enabled: bool`, `shape: string` |
| `m3/outlined-card` | Container | `content` (1..*) | — | `containerColor: color`, `shape: string`, `stableKey: string`, `elevationDp: float`, `onClickAction: object or null` |
| `m3/outlined-icon-button` | Container | `content` (1..1) | — | `enabled: bool`, `selected: bool`, `alignment: string`, `contentDescription: string or null`, `sizeDp: float`, `onClickAction: object or null`, `shape: string` |
| `m3/outlined-leading-button` | Container | `content` | — | `enabled: bool` |
| `m3/outlined-text-field` | Container | `label`, `placeholder`, `supportingText`, `leadingIcon`, `trailingIcon` | — | `value: string or object`, `enabled: bool`, `readOnly: bool`, `singleLine: bool`, `isError: bool`, `shape: string` |
| `m3/outlined-toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/outlined-trailing-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/primary-scrollable-tab-row` | Container | `tabs` (1..*) | `selectedIndex: int or object`, `selectedTabIndex: int` | `containerColor: color`, `contentColor: color`, `edgePaddingDp: float`, `minTabWidthDp: float` |
| `m3/primary-tab-row` | Container | `tabs` (1..*) | `selectedIndex: int or object`, `selectedTabIndex: int` | `containerColor: color`, `contentColor: color` |
| `m3/provide-text-style` | Container | `content` | — | — |
| `m3/radio-button` | Leaf | — | — | `selected: bool or string or object`, `enabled: bool` |
| `m3/range-slider` | Leaf | — | — | `enabled: bool`, `steps: int` |
| `m3/search-bar` | Container | `inputField` (1..1), `expandedContent` | `expanded: bool` | `shapeDp: float`, `tonalElevationDp: float`, `shape: string`, `shadowElevationDp: float` |
| `m3/search-input-field` | Container | `placeholder`, `leadingIcon`, `trailingIcon` | `value: object or string` | `enabled: bool`, `readOnly: bool`, `onQueryChangeAction: object or null`, `onSearchAction: object or null`, `shape: string` |
| `m3/secondary-scrollable-tab-row` | Container | `indicator`, `divider`, `tabs` | `selectedTabIndex: int` | `containerColor: color`, `contentColor: color`, `edgePaddingDp: float`, `minTabWidthDp: float` |
| `m3/secondary-tab-row` | Container | `indicator`, `divider`, `tabs` | `selectedTabIndex: int` | `containerColor: color`, `contentColor: color` |
| `m3/segmented-button` | Container | `icon`, `label` | `checked: bool`, `shape: string` | `enabled: bool` |
| `m3/short-navigation-bar` | Container | `content` | — | `containerColor: color`, `contentColor: color` |
| `m3/short-navigation-bar-item` | Container | `icon`, `label` | `selected: bool` | `enabled: bool` |
| `m3/single-choice-segmented-button-row` | Container | `content` | — | `spaceDp: float` |
| `m3/slider` | Leaf | — | `value: float or object` | `valueFrom: float`, `valueTo: float`, `steps: int`, `enabled: bool` |
| `m3/small-extended-floating-action-button` | Container | `text`, `icon` | — | `expanded: bool`, `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/small-floating-action-button` | Container | `content` | — | `shape: string`, `containerColor: color`, `contentColor: color` |
| `m3/snackbar` | Container | `action`, `dismissAction`, `content` | — | `actionOnNewLine: bool`, `shape: string`, `containerColor: color`, `contentColor: color`, `actionContentColor: color`, `dismissActionContentColor: color` |
| `m3/snackbar-host` | Container | `snackbar` | `visible: bool` | `message: string`, `actionLabel: string or null` |
| `m3/split-button-layout` | Container | `leadingButton`, `trailingButton` | — | `spacingDp: float` |
| `m3/suggestion-chip` | Container | `label`, `icon` | — | `enabled: bool`, `shape: string` |
| `m3/supporting-pane-scaffold` | Container | `mainPane`, `supportingPane`, `extraPane`, `paneExpansionDragHandle` | — | — |
| `m3/surface` | Container | `content` | — | `containerColor: color`, `contentColor: color`, `shapeDp: float`, `tonalElevationDp: float`, `themeTypeScale: float`, `themeCornerRadiusDp: float`, `themeDisplayTypeface: string`, `themeHeadlineTypeface: string`, `themeTitleTypeface: string`, `themeBodyTypeface: string`, `themeLabelTypeface: string`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, labelLarge, labelMedium, labelSmall), `shape: string`, `color: string`, `shadowElevationDp: float`, 4 `theme…Color` roles |
| `m3/switch` | Leaf | — | — | `checked: bool or string or object`, `enabled: bool` |
| `m3/tab` | Container | `text` (1..1) | `selected: bool or string or object` | `enabled: bool`, `selectedContentColor: color`, `unselectedContentColor: color` |
| `m3/text` | Leaf | — | `text: string` | `style` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, labelLarge, labelMedium, labelSmall), `fontWeight` (normal, medium, semiBold, bold), `fontStyle` (normal, italic), `color: string`, `fontSizeSp: float`, `lineHeightSp: float`, `letterSpacingSp: float`, `minLines: int`, `maxLines: int`, `softWrap: bool`, `overflow` (clip, ellipsis, visible), `textAlign` (start, center, end, justify), `textDecoration` (none, underline, lineThrough), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float`, `fontVariationSettings: string`, `fontFeatureSettings: string` |
| `m3/text-button` | Container | `content` | — | `enabled: bool`, `shape: string` |
| `m3/text-field` | Container | `label`, `placeholder`, `supportingText`, `leadingIcon`, `trailingIcon` | — | `value: string or object`, `enabled: bool`, `readOnly: bool`, `singleLine: bool`, `isError: bool`, `shape: string` |
| `m3/thumb` | Leaf | — | — | `enabled: bool` |
| `m3/time-input` | Leaf | — | — | — |
| `m3/time-picker` | Leaf | — | `mode` (dial, input), `hour: int`, `minute: int` | `is24Hour: bool` |
| `m3/title` | Leaf | — | — | — |
| `m3/toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/tonal-leading-button` | Container | `content` | — | `enabled: bool` |
| `m3/tonal-toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/tonal-trailing-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `m3/top-app-bar` | Container | `title`, `navigationIcon`, `actions` | — | `expandedHeightDp: float` |
| `m3/track` | Leaf | — | `trackCornerSizeDp: float` | `enabled: bool`, `thumbTrackGapSizeDp: float`, `trackInsideCornerSizeDp: float` |
| `m3/trailing-button` | Container | `content` | — | `enabled: bool` |
| `m3/tri-state-checkbox` | Leaf | — | — | `enabled: bool` |
| `m3/variable-font-text` | Leaf | — | `text: string` | `font` (robotoFlex, googleSansFlex), `wght: float or object`, `wdth: float or object`, `slnt: float or object`, `rond: float or object`, `fontSizeSp: float`, `color: string` |
| `m3/vertical-divider` | Leaf | — | — | `thicknessDp: float`, `color: string` |
| `m3/vertical-floating-toolbar` | Container | `leadingContent`, `trailingContent`, `content` | `expanded: bool` | `shape: string`, `expandedShadowElevationDp: float`, `collapsedShadowElevationDp: float` |
| `m3/vertical-slider` | Container | `thumb`, `track` | — | `enabled: bool`, `reverseDirection: bool` |
| `m3/wide-navigation-rail` | Container | `header`, `content` | — | `shape: string` |
| `m3/wide-navigation-rail-item` | Container | `icon`, `label` | `selected: bool`, `railExpanded: bool` | `enabled: bool` |
| `remote-compose/custom` | Container | `content` | `name: string` | `widthDp: float`, `heightDp: float` |
| `remote-compose/document` | Container | — | — | `documentBase64: string`, `documentUrl: string`, `theme` (inherit, light, dark, system), `namedValues: object` |
| `remote-compose/inline` | Container | `content` | — | `theme` (inherit, light, dark, system) |
| `shape/colour-dot` | Leaf | — | `color: string` | `diameterDp: float` |
| `shape/linear-gradient` | Leaf | — | `startColor: color`, `endColor: color` | `direction: string` |
| `shape/radial-gradient` | Leaf | — | `innerColor: color`, `outerColor: color` | `innerAlpha: float`, `center: string` |

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
        required_flag = kind.endswith('!')
        if name.startswith('theme') and name.endswith('Color'):
            theme += 1
            continue
        kind = kind.rstrip('!')
        # The wrapper `type` a value takes; `object` is a binding or a structured value.
        kinds = [{'boolean': 'bool', 'integer': 'int', 'number': 'float'}.get(k, k) for k in kind.split('|')]
        if name.endswith('Color'):
            kinds = ['color' if k == 'string' else k for k in kinds]
        kind = ' or '.join(kinds)
        cell = f"`{name}` ({allowed.replace('|', ', ')})" if allowed else f"`{name}: {kind}`"
        (required if required_flag else other).append(cell)
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
