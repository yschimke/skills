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

**Exporting is not the same as running in a widget.** Some components here export
Kotlin with no diagnostic yet sit outside the Glance Wear widget profile, and
the generated code only says so in a comment ("outside the Glance Wear widget
profile… throws"): `layout/collapsible-column` is one. Read the exported source
for that comment before handing a widget over, and prefer `layout/column`.
Likewise `remote-m3/remote-icon`'s `imageVector` is a free string: keys that
resolve to icons only `material-icons-extended` ships (`pauseCircle`,
`playCircle`, `stopCircle`) export cleanly but fail to compile where that
artifact is missing. `ui_builder_render_native` is the check for both.

<!-- remote-m3 sha256:876b81abc7033b254c184cef5a2cc783, 60 components -->
| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey: string` | `contentDescription: string or null`, `contentScale` (crop, fit, fillBounds, inside), `alignment: string` |
| `draw/arc` | Leaf | — | — | `xDp: float or object`, `yDp: float or object`, `widthDp: float or object`, `heightDp: float or object`, `startAngle: float or object`, `sweepAngle: float or object`, `useCenter: bool`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/canvas` | Container | `ops` | — | — |
| `draw/circle` | Leaf | — | — | `centerXDp: float or object`, `centerYDp: float or object`, `radiusDp: float or object`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/clip` | Container | `ops` | — | `xDp: float or object`, `yDp: float or object`, `widthDp: float or object`, `heightDp: float or object`, `pathData: string`, `viewportWidth: float or object`, `viewportHeight: float or object`, `exclude: bool` |
| `draw/group` | Container | `ops` | — | `translateXDp: float or object`, `translateYDp: float or object`, `rotate: float or object`, `scale: float or object`, `pivotXDp: float or object`, `pivotYDp: float or object` |
| `draw/if` | Container | `ops` | — | `condition: bool` |
| `draw/line` | Leaf | — | — | `startXDp: float or object`, `startYDp: float or object`, `endXDp: float or object`, `endYDp: float or object`, `color: string`, `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/morph` | Leaf | — | — | `pathData: string`, `toPathData: string`, `progress: float or object`, `viewportWidth: float or object`, `viewportHeight: float or object`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/oval` | Leaf | — | — | `xDp: float or object`, `yDp: float or object`, `widthDp: float or object`, `heightDp: float or object`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/path` | Leaf | — | — | `pathData: string`, `viewportWidth: float or object`, `viewportHeight: float or object`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/rect` | Leaf | — | — | `xDp: float or object`, `yDp: float or object`, `widthDp: float or object`, `heightDp: float or object`, `cornerRadiusDp: float or object`, `color: string`, `style` (fill, stroke), `strokeWidthDp: float or object`, `strokeCap` (butt, round, square), `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/repeat` | Container | `ops` | — | `from: float or object`, `until: float or object`, `step: float or object`, `index: string` |
| `draw/text` | Leaf | — | — | `text: string`, `xDp: float or object`, `yDp: float or object`, `textSizeSp: float or object`, `align` (start, center, end), `color: string`, `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/text-circle` | Leaf | — | — | `text: string`, `centerXDp: float or object`, `centerYDp: float or object`, `radiusDp: float or object`, `angle: float or object`, `textSizeSp: float or object`, `color: string`, `alpha: float or object`, `gradient` (horizontal, vertical, radial, sweep), `gradientColor: color` |
| `draw/text-path` | Leaf | — | — | `text: string`, `pathData: string`, `startDp: float or object`, `offsetDp: float or object`, `textSizeSp: float or object`, `color: string`, `alpha: float or object` |
| `layout/box` | Container | `children` | — | `contentAlignment: string`, `propagateMinConstraints: bool` |
| `layout/collapsible-column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/collapsible-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalAlignment` (top, center, bottom) |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/fit-box` | Container | `children` | — | `horizontalAlignment` (start, center, end), `verticalArrangement` (top, center, bottom) |
| `layout/flow-row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `maxItemsInEachRow: float`, `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/for-each` | Container | `template` (1..1) | `data: object` | `verticalSpacingDp: float` |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalAlignment` (top, center, bottom) |
| `remote-compose/custom` | Container | `content` | `name: string` | `widthDp: float`, `heightDp: float` |
| `remote-compose/document` | Container | — | — | `documentBase64: string`, `documentUrl: string`, `theme` (inherit, light, dark, system), `namedValues: object` |
| `remote-m3/lottie` | Leaf | — | — | `url: string`, `json: string`, `progress: float or object` |
| `remote-m3/remote-app-card` | Container | `appName`, `title`, `appImage`, `time`, `content` | — | `enabled: bool or object` |
| `remote-m3/remote-button` | Container | `content` | — | `containerImageKey: string`, `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-button-group` | Container | `content` | — | — |
| `remote-m3/remote-card` | Container | `content` | — | `containerImageKey: string`, `enabled: bool or object` |
| `remote-m3/remote-checkbox-button` | Container | `icon`, `secondaryLabel`, `label` | `checked: bool or object` | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-circular-progress-indicator` | Leaf | — | `progress: float or object` | `enabled: bool or object`, `startAngle: float or object`, `endAngle: float or object` |
| `remote-m3/remote-compact-button` | Container | `icon`, `label` | — | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-curved-progress-indicator` | Leaf | — | `progress: float or object` | `enabled: bool or object`, `startAngle: float or object`, `sweepAngle: float or object`, `gapAngleDegrees: float or object`, `dotFadeOutFraction: float or object`, `dotCollapsible: bool or object`, `reverseDirection: bool or object` |
| `remote-m3/remote-edge-button` | Container | `content` | — | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-horizontal-page-indicator` | Leaf | — | — | `pageCount: int`, `selectedPage: int or object`, `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color` |
| `remote-m3/remote-icon` | Leaf | — | — | `imageVector: string`, `contentDescription: string or object`, `tint: string` |
| `remote-m3/remote-icon-button` | Container | `content` | — | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-label-button` | Container | `label`, `secondaryLabel`, `icon` | — | `enabled: bool or object`, `borderColor: color`, `containerImageKey: string` |
| `remote-m3/remote-linear-progress-indicator` | Leaf | — | `progress: float or object` | `enabled: bool or object` |
| `remote-m3/remote-material-theme` | Container | `children` | — | 23 `theme…Color` roles |
| `remote-m3/remote-outlined-card` | Container | `content` | — | `enabled: bool or object` |
| `remote-m3/remote-radio-button` | Container | `icon`, `secondaryLabel`, `label` | `selected: bool or object` | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-slider` | Container | `decreaseIcon`, `increaseIcon` | `value: float or object` | `steps: int`, `enabled: bool or object`, `segmented: bool` |
| `remote-m3/remote-split-checkbox-button` | Container | `secondaryLabel`, `label` | `checked: bool or object` | `toggleContentDescription: string or object`, `enabled: bool or object` |
| `remote-m3/remote-split-radio-button` | Container | `secondaryLabel`, `label` | `selected: bool or object` | `selectionContentDescription: string or object`, `enabled: bool or object` |
| `remote-m3/remote-split-switch-button` | Container | `secondaryLabel`, `label` | `checked: bool or object` | `toggleContentDescription: string or object`, `enabled: bool or object` |
| `remote-m3/remote-stepper` | Container | `decreaseIcon`, `increaseIcon`, `content` | `value: float or object` | `steps: int`, `enabled: bool or object` |
| `remote-m3/remote-switch-button` | Container | `icon`, `secondaryLabel`, `label` | `checked: bool or object` | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-text` | Leaf | — | `text: string or object` | `style` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), `fontSize: float`, `color: string`, `textAlign` (start, center, end, justify), `maxLines: int`, `fontVariationSettings: string`, `fontFeatureSettings: string`, `fontStyle: string`, `fontWeight: string`, `overflow: string` |
| `remote-m3/remote-text-button` | Container | `content` | — | `enabled: bool or object`, `borderColor: color` |
| `remote-m3/remote-time-text` | Leaf | — | — | `leadingText: string`, `trailingText: string`, `separator: string`, `textSizeSp: float`, `color: string` |
| `remote-m3/remote-title-card` | Container | `title`, `time`, `subtitle`, `content` | — | `enabled: bool or object` |
| `remote-m3/remote-vertical-page-indicator` | Leaf | — | — | `pageCount: int`, `selectedPage: int or object`, `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color` |
| `remote-m3/theme-specimen` | Leaf | — | `name: string` | — |
| `remote-m3/widget-container-adaptive` | Scaffold | `background`, `headline`, `supporting`, `action` | — | `background: string`, `themeDisplayTypeface: string`, `themeTitleTypeface: string`, `themeBodyTypeface: string`, `themeLabelTypeface: string`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `remote-m3/widget-container-large` | Scaffold | `background`, `content` | — | `background: string`, `themeDisplayTypeface: string`, `themeTitleTypeface: string`, `themeBodyTypeface: string`, `themeLabelTypeface: string`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `remote-m3/widget-container-small` | Scaffold | `background`, `content` | — | `background: string`, `themeDisplayTypeface: string`, `themeTitleTypeface: string`, `themeBodyTypeface: string`, `themeLabelTypeface: string`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall) |
| `shape/linear-gradient` | Leaf | — | `startColor: color`, `endColor: color` | `direction: string` |
