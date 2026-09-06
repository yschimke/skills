# The published catalogs, without the 70 KB call

Everything a `ui_builder_apply` needs to be right: the component ids, the slot
names a child goes into, which properties are required, and which are closed
enums. Extracted from `ui_builder_list_catalogs` against
`https://preview.coo.ee` on **2026-09-06**.

Treat it as a fast path, not as the contract. The server is the authority: a
component here that the server refuses, or one you need that is missing, means
this file has aged — regenerate it with the recipe at the bottom.

Two catalogs are published. A design pins exactly one and cannot mix them.

- **`m3-catalog`** — Material 3 for a phone/tablet screen. 39 components.
- **`remote-m3`** — the Wear widget scaffolds and the handful of components that
  work inside them. 10 components.

`role` decides where a node may go: a `Scaffold` is a root, a `Container` has
slots, a `Leaf` has none. A slot lists what it accepts, so a `Leaf` cannot take
children and the service will say so.

## `m3-catalog`

Pin it as `{"systemId": "m3-catalog", "catalogRevision": "candidate", "capabilityDigest": "candidate", "nativeRuntimeId": "candidate"}`.

| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey` | `contentDescription`, `contentScale`, `alignment` |
| `layout/box` | Container | `children` | — | `contentAlignment`, `propagateMinConstraints` |
| `layout/column` | Container | `children` | — | `verticalArrangement`, `verticalSpacingDp`, `horizontalAlignment`, `alignment`, `weight` |
| `layout/horizontal-carousel` | Container | `items` | `itemWidthDp`, `scrollStateKey` | `itemSpacingDp`, `contentPaddingStartDp`, `kind`, `span` |
| `layout/lazy-column` | Container | `items` | `scrollStateKey` | `contentPadding`, `verticalSpacingDp`, `reverseLayout` |
| `layout/lazy-grid` | Container | `items` | `columns`, `scrollStateKey` | `horizontalSpacingDp`, `verticalSpacingDp`, `contentPadding`, `itemSpans` |
| `layout/lazy-row` | Container | `items` | — | `contentPadding`, `horizontalSpacingDp`, `scrollStateKey`, `span`, `stableKey` |
| `layout/row` | Container | `children` | — | `horizontalArrangement`, `horizontalSpacingDp`, `verticalAlignment` |
| `layout/scaffold` | Scaffold | `topBar`, `snackbarHost`, `content` | — | `containerColor`, `contentWindowInsets`, `loading`, `scrollStateKey` |
| `layout/supporting-pane-scaffold` | Scaffold | `mainPane`, `supportingPane` | `layoutMode`, `mainPaneVisible`, `supportingPaneVisible` | `mainPanePreferredWidthDp`, `supportingPanePreferredWidthDp`, `paneSpacingDp` |
| `m3/button` | Container | `content` | `style` | `enabled`, `selected`, `containerColor`, `onClickAction` |
| `m3/card` | Container | `content` | — | `variant`, `containerColor`, `shape`, `stableKey`, `elevationDp`, `onClickAction` |
| `m3/center-aligned-top-app-bar` | Container | `title` | — | `containerColor`, `scrolledContainerColor`, `scrollBehavior` |
| `m3/checkbox` | Leaf | — | — | `checked`, `enabled` |
| `m3/date-picker` | Leaf | — | `mode`, `selectedDate` | `showModeToggle` |
| `m3/dialog` | Container | `icon`, `title`, `text`, `dismissButton`, `confirmButton` | — | `containerColor`, `tonalElevationDp`, `shapeDp` |
| `m3/filter-chip` | Container | `label`, `leadingIcon` | `selected` | `enabled`, `shape`, `onClickAction` |
| `m3/horizontal-divider` | Leaf | — | — | `thicknessDp`, `color` |
| `m3/horizontal-floating-toolbar` | Container | `content` | — | `expanded`, `containerColor`, `contentPadding`, `alignment` |
| `m3/icon` | Leaf | — | `iconKey` | `contentDescription`, `sizeDp`, `color` |
| `m3/icon-button` | Container | `content` | — | `variant`, `enabled`, `selected`, `alignment`, `contentDescription`, `sizeDp`, `onClickAction` |
| `m3/list-item` | Container | `headline`, `supporting`, `trailing` | — | `startAccentColor` |
| `m3/primary-tab-row` | Container | `tabs` | `selectedIndex` | — |
| `m3/progress-indicator` | Leaf | — | `variant` | `progress`, `indeterminate` |
| `m3/radio-button` | Leaf | — | — | `selected`, `enabled` |
| `m3/search-bar` | Container | `inputField`, `expandedContent` | `expanded` | `shapeDp`, `tonalElevationDp` |
| `m3/search-input-field` | Container | `placeholder`, `leadingIcon`, `trailingIcon` | `value` | `enabled`, `readOnly`, `onQueryChangeAction`, `onSearchAction` |
| `m3/slider` | Leaf | — | `value` | `valueFrom`, `valueTo`, `steps`, `enabled` |
| `m3/snackbar-host` | Container | `snackbar` | `visible` | `message`, `actionLabel` |
| `m3/surface` | Container | `content` | — | `containerColor`, `contentColor`, `shapeDp`, `tonalElevationDp`, `themePrimaryColor`, `themeBackgroundColor`, `themeSurfaceColor`, `themeContentColor`, `themeTypeScale`, `themeCornerRadiusDp` |
| `m3/switch` | Leaf | — | — | `checked`, `enabled` |
| `m3/tab` | Container | `text` | `selected` | — |
| `m3/text` | Leaf | — | `text` | `style`, `fontWeight`, `fontStyle`, `color`, `fontSizeSp`, `lineHeightSp`, `letterSpacingSp`, `minLines`, `maxLines`, `softWrap`, `overflow`, `textAlign`, `textDecoration`, `alignment`, `weight` |
| `m3/text-field` | Container | `label`, `placeholder`, `supportingText`, `leadingIcon`, `trailingIcon` | `variant` | `value`, `enabled`, `readOnly`, `singleLine`, `isError` |
| `m3/time-picker` | Leaf | — | `mode`, `hour`, `minute` | `is24Hour` |
| `remote-compose/document` | Container | — | `documentBase64` | `theme`, `namedValues` |
| `shape/colour-dot` | Leaf | — | `color` | `diameterDp` |
| `shape/linear-gradient` | Leaf | — | `startColor`, `endColor` | `direction` |
| `shape/radial-gradient` | Leaf | — | `innerColor`, `outerColor` | `innerAlpha`, `center` |

### `m3-catalog` enum values

| component | property | allowed values |
| --- | --- | --- |
| `asset/image` | `contentScale` | `crop`, `fit`, `fillBounds`, `inside` |
| `layout/column` | `verticalArrangement` | `top`, `center`, `bottom`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `layout/column` | `horizontalAlignment` | `start`, `center`, `end` |
| `layout/column` | `alignment` | `topStart`, `topCenter`, `topEnd`, `centerStart`, `center`, `centerEnd`, `bottomStart`, `bottomCenter`, `bottomEnd` |
| `layout/row` | `horizontalArrangement` | `start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `layout/row` | `verticalAlignment` | `top`, `center`, `bottom` |
| `layout/supporting-pane-scaffold` | `layoutMode` | `adaptive`, `expandedTwoPane`, `singlePane`, `twoPane` |
| `m3/button` | `style` | `filled`, `filledTonal`, `text`, `fab` |
| `m3/card` | `variant` | `filled`, `elevated`, `outlined` |
| `m3/center-aligned-top-app-bar` | `scrollBehavior` | `pinned`, `enterAlways`, `exitUntilCollapsed` |
| `m3/date-picker` | `mode` | `picker`, `input` |
| `m3/icon` | `iconKey` | `accessTime`, `accountCircle`, `add`, `addCircle`, `arrowBack`, `arrowForward`, `bookmark`, `bookmarkBorder`, `calendarMonth`, `cameraAlt`, `check`, `checkCircle`, `chevronRight`, `close`, `coffee`, `delete`, `download`, `edit`, `email`, `expandMore`, `favorite`, `genres`, `home`, `image`, `info`, `locationOn`, `lock`, `menu`, `moreVert`, `notifications`, `pauseCircle`, `person`, `phone`, `playCircle`, `playlistAdd`, `refresh`, `remove`, `search`, `settings`, `share`, `star`, `stopCircle`, `upload`, `videoLibrary`, `visibility`, `warning` |
| `m3/icon-button` | `variant` | `standard`, `filled`, `tonal`, `outlined` |
| `m3/progress-indicator` | `variant` | `linear`, `circular` |
| `m3/text` | `style` | `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall` |
| `m3/text` | `fontWeight` | `normal`, `medium`, `semiBold`, `bold` |
| `m3/text` | `fontStyle` | `normal`, `italic` |
| `m3/text` | `overflow` | `clip`, `ellipsis`, `visible` |
| `m3/text` | `textAlign` | `start`, `center`, `end`, `justify` |
| `m3/text` | `textDecoration` | `none`, `underline`, `lineThrough` |
| `m3/text` | `alignment` | `topStart`, `topCenter`, `topEnd`, `centerStart`, `center`, `centerEnd`, `bottomStart`, `bottomCenter`, `bottomEnd` |
| `m3/text-field` | `variant` | `filled`, `outlined` |
| `m3/time-picker` | `mode` | `dial`, `input` |
| `remote-compose/document` | `theme` | `inherit`, `light`, `dark`, `system` |

## `remote-m3`

Pin it as `{"systemId": "remote-m3", "catalogRevision": "wear-widget-scaffolds-v1", "capabilityDigest": "candidate", "nativeRuntimeId": "candidate"}`.

| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `remote-m3/widget-container-small` | Scaffold | `background`, `content` | — | `background`, `horizontalPaddingDp`, `verticalPaddingDp`, `cornerRadiusDp` |
| `remote-m3/widget-container-large` | Scaffold | `background`, `content` | — | `background`, `horizontalPaddingDp`, `verticalPaddingDp`, `cornerRadiusDp` |
| `layout/box` | Container | `children` | — | `contentAlignment`, `propagateMinConstraints` |
| `layout/column` | Container | `children` | — | `verticalArrangement`, `verticalSpacingDp`, `horizontalAlignment`, `alignment`, `weight` |
| `layout/row` | Container | `children` | — | `horizontalArrangement`, `horizontalSpacingDp`, `verticalAlignment` |
| `m3/surface` | Container | `content` | — | `containerColor`, `contentColor`, `shapeDp`, `tonalElevationDp`, `themePrimaryColor`, `themeBackgroundColor`, `themeSurfaceColor`, `themeContentColor`, `themeTypeScale`, `themeCornerRadiusDp` |
| `m3/text` | Leaf | — | `text` | `style`, `fontWeight`, `fontStyle`, `color`, `fontSizeSp`, `lineHeightSp`, `letterSpacingSp`, `minLines`, `maxLines`, `softWrap`, `overflow`, `textAlign`, `textDecoration`, `alignment`, `weight` |
| `remote-compose/document` | Container | — | `documentBase64` | `theme`, `namedValues` |
| `shape/linear-gradient` | Leaf | — | `startColor`, `endColor` | `direction` |
| `asset/image` | Leaf | — | `assetKey` | `contentDescription`, `contentScale`, `alignment` |

### `remote-m3` enum values

| component | property | allowed values |
| --- | --- | --- |
| `layout/column` | `verticalArrangement` | `top`, `center`, `bottom`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `layout/column` | `horizontalAlignment` | `start`, `center`, `end` |
| `layout/column` | `alignment` | `topStart`, `topCenter`, `topEnd`, `centerStart`, `center`, `centerEnd`, `bottomStart`, `bottomCenter`, `bottomEnd` |
| `layout/row` | `horizontalArrangement` | `start`, `center`, `end`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `layout/row` | `verticalAlignment` | `top`, `center`, `bottom` |
| `m3/text` | `style` | `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall` |
| `m3/text` | `fontWeight` | `normal`, `medium`, `semiBold`, `bold` |
| `m3/text` | `fontStyle` | `normal`, `italic` |
| `m3/text` | `overflow` | `clip`, `ellipsis`, `visible` |
| `m3/text` | `textAlign` | `start`, `center`, `end`, `justify` |
| `m3/text` | `textDecoration` | `none`, `underline`, `lineThrough` |
| `m3/text` | `alignment` | `topStart`, `topCenter`, `topEnd`, `centerStart`, `center`, `centerEnd`, `bottomStart`, `bottomCenter`, `bottomEnd` |
| `remote-compose/document` | `theme` | `inherit`, `light`, `dark`, `system` |
| `asset/image` | `contentScale` | `crop`, `fit`, `fillBounds`, `inside` |

## Two gates: in the document, and in the export

A component being in the catalog table above means the **document** accepts it.
It does not mean the **Compose exporter** can write it: the generator works from
a separate component record, and a node it does not recognise comes back as an
export diagnostic while the design itself stays perfectly valid, renders, and
shows in the browser.

```json
{"severity": "error", "code": "UNPROVEN_CALL_SITE",
 "message": "no component `m3/list-item` in this catalog"}
```

Measured against `https://preview.coo.ee` on 2026-09-06 — **per deployment**, so
another host may differ. Export early on any design whose Kotlin matters, rather
than at the end.

| | Components |
| --- | --- |
| **Export cleanly** | `layout/box`, `layout/column`, `layout/row`, `layout/scaffold`, `m3/surface`, `m3/text`, `m3/card`, `m3/button`, `m3/icon`, `m3/icon-button`, `m3/switch`, `m3/checkbox`, `m3/radio-button`, `m3/horizontal-divider`, `m3/progress-indicator`, `m3/filter-chip`, `m3/text-field` |
| **Refused by the exporter** | `m3/center-aligned-top-app-bar`, `m3/list-item`, `m3/slider`, `shape/colour-dot`, `asset/image` |
| **Untested** | the lazy containers, `layout/horizontal-carousel`, `layout/supporting-pane-scaffold`, `m3/dialog`, `m3/tab`, `m3/primary-tab-row`, `m3/search-bar`, `m3/search-input-field`, `m3/snackbar-host`, `m3/date-picker`, `m3/time-picker`, `m3/horizontal-floating-toolbar`, the gradients, `remote-compose/document` |

If the Kotlin is the deliverable, build the screen out of the first row. If the
*design* is the deliverable — a mockup, a PNG for a designer — the whole catalog
is available and an export diagnostic is not a problem to solve.

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

`ui_builder_list_catalogs` answers with ~70 KB of JSON — every component's
parameters, Wasm adapter status, SVG parity status and export notes. Do not read
that into the conversation. Save the tool result to a file (most hosts do this
for you when a result is oversized; otherwise `curl` the endpoint) and reduce it:

```sh
python3 - "$SAVED_RESULT" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for c in d['response']['catalogs']:
    b = c['benchmark']
    print('==', b['catalogSystemId'], b['catalogRevision'], b['nativeRuntimeId'])
    for comp in c['components']:
        slots = ','.join(s['name'] for s in comp.get('slots', []))
        req = ','.join(p['name'] for p in comp['properties'] if p.get('required'))
        print(f"  {comp['componentId']:38} {comp['role']:10} slots={slots or '-':24} required={req or '-'}")
PY
```

Add `p['allowedValues']` to that loop for the enum table. The same shape works
for any catalog a host publishes, not just these two.

## What is *not* here

`modifierCapabilities` (which modifiers each component accepts), the `wasm`
adapter status, the `svg` parity status and each component's `code` symbol and
imports all live in the full response. Reach for them when a modifier is refused
or an SVG export is gated; day-to-day authoring does not need them.
