# `remote-m3`: Wear widgets

The `remote-m3` catalog in the form an insert needs, extracted from
`ui_builder_list_catalogs` on compose-preview-server 3.121.0 (2026-10-11). How
to read the columns, why a pin is refused and how to regenerate the table are
in [m3-catalog.md](./m3-catalog.md).

A `remote-m3` design is a Wear widget, rendered through Remote Compose. The
root is `remote-m3/widget-container-small` (216×76 dp),
`remote-m3/widget-container-large` (216×124 dp) or
`remote-m3/widget-container-adaptive`. The pin is
`{"systemId": "remote-m3", "catalogRevision": "wear-widget-scaffolds-v1", "capabilityDigest": "candidate", "nativeRuntimeId": "candidate"}`
(see [Pins](./m3-catalog.md#pins)). The starter document is in the skill under
[A document that works](../SKILL.md#a-document-that-works).

<!-- remote-m3 sha256:876b81abc7033b254c184cef5a2cc783, 60 components -->
| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey` | `contentDescription`, `contentScale` (crop, fit, fillBounds, inside), `alignment` |
| `draw/arc` | Leaf | — | — | `xDp`, `yDp`, `widthDp`, `heightDp`, `startAngle`, `sweepAngle`, `useCenter`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/canvas` | Container | `ops` | — | — |
| `draw/circle` | Leaf | — | — | `centerXDp`, `centerYDp`, `radiusDp`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/clip` | Container | `ops` | — | `xDp`, `yDp`, `widthDp`, `heightDp`, `pathData`, `viewportWidth`, `viewportHeight`, `exclude` |
| `draw/group` | Container | `ops` | — | `translateXDp`, `translateYDp`, `rotate`, `scale`, `pivotXDp`, `pivotYDp` |
| `draw/if` | Container | `ops` | — | `condition` |
| `draw/line` | Leaf | — | — | `startXDp`, `startYDp`, `endXDp`, `endYDp`, `color`, `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/morph` | Leaf | — | — | `pathData`, `toPathData`, `progress`, `viewportWidth`, `viewportHeight`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/oval` | Leaf | — | — | `xDp`, `yDp`, `widthDp`, `heightDp`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/path` | Leaf | — | — | `pathData`, `viewportWidth`, `viewportHeight`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/rect` | Leaf | — | — | `xDp`, `yDp`, `widthDp`, `heightDp`, `cornerRadiusDp`, `color`, `style` (fill, stroke), `strokeWidthDp`, `strokeCap` (butt, round, square), `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/repeat` | Container | `ops` | — | `from`, `until`, `step`, `index` |
| `draw/text` | Leaf | — | — | `text`, `xDp`, `yDp`, `textSizeSp`, `align` (start, center, end), `color`, `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/text-circle` | Leaf | — | — | `text`, `centerXDp`, `centerYDp`, `radiusDp`, `angle`, `textSizeSp`, `color`, `alpha`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor` |
| `draw/text-path` | Leaf | — | — | `text`, `pathData`, `startDp`, `offsetDp`, `textSizeSp`, `color`, `alpha` |
| `layout/box` | Container | `children` | — | `contentAlignment`, `propagateMinConstraints` |
| `layout/collapsible-column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/collapsible-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalAlignment` (top, center, bottom) |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/fit-box` | Container | `children` | — | `horizontalAlignment` (start, center, end), `verticalArrangement` (top, center, bottom) |
| `layout/flow-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `maxItemsInEachRow`, `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/for-each` | Container | `template` (1..1) | `data` | `verticalSpacingDp` |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalAlignment` (top, center, bottom) |
| `remote-compose/custom` | Container | `content` | `name` | `widthDp`, `heightDp` |
| `remote-compose/document` | Container | — | — | `documentBase64`, `documentUrl`, `theme` (inherit, light, dark, system), `namedValues` |
| `remote-m3/lottie` | Leaf | — | — | `url`, `json`, `progress` |
| `remote-m3/remote-app-card` | Container | `appName`, `title`, `appImage`, `time`, `content` | — | `enabled` |
| `remote-m3/remote-button` | Container | `content` | — | `containerImageKey`, `enabled`, `borderColor` |
| `remote-m3/remote-button-group` | Container | `content` | — | — |
| `remote-m3/remote-card` | Container | `content` | — | `containerImageKey`, `enabled` |
| `remote-m3/remote-checkbox-button` | Container | `icon`, `secondaryLabel`, `label` | `checked` | `enabled`, `borderColor` |
| `remote-m3/remote-circular-progress-indicator` | Leaf | — | `progress` | `enabled`, `startAngle`, `endAngle` |
| `remote-m3/remote-compact-button` | Container | `icon`, `label` | — | `enabled`, `borderColor` |
| `remote-m3/remote-curved-progress-indicator` | Leaf | — | `progress` | `enabled`, `startAngle`, `sweepAngle`, `gapAngleDegrees`, `dotFadeOutFraction`, `dotCollapsible`, `reverseDirection` |
| `remote-m3/remote-edge-button` | Container | `content` | — | `enabled`, `borderColor` |
| `remote-m3/remote-horizontal-page-indicator` | Leaf | — | — | `pageCount`, `selectedPage`, `selectedColor`, `unselectedColor`, `backgroundColor` |
| `remote-m3/remote-icon` | Leaf | — | — | `imageVector`, `contentDescription`, `tint` |
| `remote-m3/remote-icon-button` | Container | `content` | — | `enabled`, `borderColor` |
| `remote-m3/remote-label-button` | Container | `label`, `secondaryLabel`, `icon` | — | `enabled`, `borderColor`, `containerImageKey` |
| `remote-m3/remote-linear-progress-indicator` | Leaf | — | `progress` | `enabled` |
| `remote-m3/remote-material-theme` | Container | `children` | — | 23 `theme…Color` roles |
| `remote-m3/remote-outlined-card` | Container | `content` | — | `enabled` |
| `remote-m3/remote-radio-button` | Container | `icon`, `secondaryLabel`, `label` | `selected` | `enabled`, `borderColor` |
| `remote-m3/remote-slider` | Container | `decreaseIcon`, `increaseIcon` | `value` | `steps`, `enabled`, `segmented` |
| `remote-m3/remote-split-checkbox-button` | Container | `secondaryLabel`, `label` | `checked` | `toggleContentDescription`, `enabled` |
| `remote-m3/remote-split-radio-button` | Container | `secondaryLabel`, `label` | `selected` | `selectionContentDescription`, `enabled` |
| `remote-m3/remote-split-switch-button` | Container | `secondaryLabel`, `label` | `checked` | `toggleContentDescription`, `enabled` |
| `remote-m3/remote-stepper` | Container | `decreaseIcon`, `increaseIcon`, `content` | `value` | `steps`, `enabled` |
| `remote-m3/remote-switch-button` | Container | `icon`, `secondaryLabel`, `label` | `checked` | `enabled`, `borderColor` |
| `remote-m3/remote-text` | Leaf | — | `text` | `style` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), `fontSize`, `color`, `textAlign` (start, center, end, justify), `maxLines`, `fontVariationSettings`, `fontFeatureSettings`, `fontStyle`, `fontWeight`, `overflow` |
| `remote-m3/remote-text-button` | Container | `content` | — | `enabled`, `borderColor` |
| `remote-m3/remote-time-text` | Leaf | — | — | `leadingText`, `trailingText`, `separator`, `textSizeSp`, `color` |
| `remote-m3/remote-title-card` | Container | `title`, `time`, `subtitle`, `content` | — | `enabled` |
| `remote-m3/remote-vertical-page-indicator` | Leaf | — | — | `pageCount`, `selectedPage`, `selectedColor`, `unselectedColor`, `backgroundColor` |
| `remote-m3/theme-specimen` | Leaf | — | `name` | — |
| `remote-m3/widget-container-adaptive` | Scaffold | `background`, `headline`, `supporting`, `action` | — | `background`, `themeDisplayTypeface`, `themeTitleTypeface`, `themeBodyTypeface`, `themeLabelTypeface`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `remote-m3/widget-container-large` | Scaffold | `background`, `content` | — | `background`, `themeDisplayTypeface`, `themeTitleTypeface`, `themeBodyTypeface`, `themeLabelTypeface`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `remote-m3/widget-container-small` | Scaffold | `background`, `content` | — | `background`, `themeDisplayTypeface`, `themeTitleTypeface`, `themeBodyTypeface`, `themeLabelTypeface`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `shape/linear-gradient` | Leaf | — | `startColor`, `endColor` | `direction` |
