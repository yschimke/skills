# `wear-m3`: Wear OS app screens

The `wear-m3` catalog in the form an insert needs, extracted from
`ui_builder_list_catalogs` on compose-preview-server 3.121.0 (2026-10-11). How
to read the columns, why a pin is refused and how to regenerate the table are
in [m3-catalog.md](./m3-catalog.md).

A `wear-m3` design is a round watch screen, usually 227×227 dp (large round)
or 192×192 dp (small round). The root is `wear-m3/screen-scaffold`. Its
`content` slot takes one child, typically a `wear-m3/transforming-lazy-column`
whose `items` hold a `wear-m3/list-header` and the buttons or cards. Its
`edgeButton` slot takes the one `wear-m3/edge-button` that hugs the bottom edge.
A button needs a `wear-m3/text` in its `content`, inserted in the same `apply`
call.

The pin has no stable alias: copy `catalogPin` from `ui_builder_list_catalogs`
(see [Pins](./m3-catalog.md#pins)). The starter document is in the skill under
[A document that works](../SKILL.md#a-document-that-works).

<!-- wear-m3 sha256:b37fb7ace974e9cd4b5a068d623487fe, 89 components -->
| `componentId` | role | slots | required | other properties |
| --- | --- | --- | --- | --- |
| `asset/image` | Leaf | — | `assetKey: string` | `contentDescription: string or null`, `contentScale` (crop, fit, fillBounds, inside), `alignment: string` |
| `confetti-wear/confetti-preview-scaffold` | Container | `content` | — | `seedColor: color` |
| `confetti-wear/confetti-theme-fixed` | Container | `content` | — | — |
| `confetti-wear/placeholder-button` | Leaf | — | — | `secondaryLabel: bool`, `hasIcon: bool`, `enabled: bool` |
| `confetti-wear/screen-header` | Leaf | — | `text: string` | — |
| `confetti-wear/section-header` | Leaf | — | `text: string` | — |
| `confetti-wear/session-card` | Container | `timeDisplay` | `isBookmarked: bool` | — |
| `confetti-wear/test-scaffold` | Container | `content` | — | — |
| `layout/box` | Container | `children` | — | `contentAlignment: string`, `propagateMinConstraints: bool` |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp: float`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp: float`, `verticalAlignment` (top, center, bottom) |
| `wear-m3/alert-dialog` | Container | `content`, `confirmButton`, `dismissButton` | `title: string` | `text: string`, `visible: bool or object` |
| `wear-m3/alert-dialog-content` | Container | `confirmButton`, `title`, `dismissButton`, `icon`, `text` | — | — |
| `wear-m3/alert-dialog-edge-button` | Container | `content` | — | — |
| `wear-m3/animated-page` | Container | `content` | `pageIndex: int` | `contentScrimColor: color` |
| `wear-m3/animated-text` | Leaf | — | `text: string` | — |
| `wear-m3/app-card` | Container | `appName`, `title`, `appImage`, `time`, `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/app-scaffold` | Container | `timeText`, `content` | — | `containerColor: color`, `contentColor: color` |
| `wear-m3/arc-progress-indicator` | Leaf | — | — | `startAngle: float`, `endAngle: float`, `strokeWidthDp: float`, `gapSizeDp: float` |
| `wear-m3/button` | Container | `content` (1..*) | — | `variant` (filled, filled-tonal, outlined, child), `enabled: bool`, `containerColor: color`, `contentColor: color`, `onClickAction: object or null`, `onLongClickLabel: string`, `shape: string` |
| `wear-m3/button-group` | Container | `children` | — | `spacingDp: float`, `expansionWidthDp: float` |
| `wear-m3/card` | Container | `content` (1..*) | — | `variant` (title, app, outlined, plain), `stableKey: string`, `onClickAction: object or null`, `containerColor: color`, `contentColor: color`, `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/checkbox-button` | Leaf | — | `label: string` | `secondaryLabel: string`, `checked: bool or object`, `enabled: bool`, `shape: string` |
| `wear-m3/child-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/circular-progress-indicator` | Leaf | — | — | `enabled: bool`, `allowProgressOverflow: bool`, `startAngle: float`, `endAngle: float`, `strokeWidthDp: float`, `gapSizeDp: float` |
| `wear-m3/compact-button` | Container | `icon`, `label` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/confirm-button` | Container | `content` | — | — |
| `wear-m3/confirmation-dialog` | Leaf | — | `text: string` | `variant` (generic, success, failure), `visible: bool or object` |
| `wear-m3/confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/date-picker` | Leaf | — | — | `initialDate: string`, `type` (year-month-day, day-month-year, month-day-year) |
| `wear-m3/decrease-icon` | Leaf | — | — | `contentDescription: string` |
| `wear-m3/dismiss-button` | Container | `content` | — | — |
| `wear-m3/edge-button` | Container | `content` (1..1) | — | `size` (extra-small, small, medium, large), `containerColor: color`, `contentColor: color`, `enabled: bool` |
| `wear-m3/fading-expanding-label` | Leaf | — | `text: string` | `color: string`, `fontSizeSp: float`, `fontStyle: string`, `fontWeight: string`, `letterSpacingSp: float`, `textDecoration: string`, `textAlign: string`, `lineHeightSp: float`, `softWrap: bool`, `maxLines: int`, `minLines: int` |
| `wear-m3/failure-confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/filled-icon-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool` |
| `wear-m3/filled-tonal-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/filled-tonal-icon-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool` |
| `wear-m3/horizontal-page-indicator` | Leaf | — | — | `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color` |
| `wear-m3/horizontal-pager-scaffold` | Container | `pageIndicator`, `content` | — | — |
| `wear-m3/icon` | Leaf | — | `iconKey` (<11431 values; ask for full>) | `sizeDp: float or object`, `contentDescription: string`, `color: string`, `tint: string` |
| `wear-m3/icon-button` | Container | `content` (1..1) | — | `variant` (filled, filled-tonal, filled-variant, outlined, standard), `containerColor: color`, `contentColor: color`, `onLongClickLabel: string`, `enabled: bool` |
| `wear-m3/icon-toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `wear-m3/increase-icon` | Leaf | — | — | `contentDescription: string` |
| `wear-m3/level-indicator` | Leaf | — | — | `enabled: bool`, `strokeWidthDp: float`, `sweepAngle: float`, `reverseDirection: bool` |
| `wear-m3/linear-progress-indicator` | Leaf | — | — | `strokeWidthDp: float`, `enabled: bool` |
| `wear-m3/list-header` | Leaf | — | `text: string` | `maxLines: int`, `overflow` (clip, ellipsis, visible), `backgroundColor: color`, `contentColor: color` |
| `wear-m3/list-sub-header` | Leaf | — | `text: string` | `maxLines: int`, `overflow` (clip, ellipsis, visible), `backgroundColor: color`, `contentColor: color` |
| `wear-m3/one-handed-gesture-click-indicator` | Container | `content` | — | `gestureIndicatorTint: string` |
| `wear-m3/one-handed-gesture-horizontal-page-indicator` | Leaf | — | — | `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color`, `gestureIndicatorTint: string`, `gestureIndicatorBackgroundColor: color` |
| `wear-m3/one-handed-gesture-scroll-indicator` | Leaf | — | — | `gestureIndicatorTint: string`, `gestureIndicatorBackgroundColor: color`, `reverseDirection: bool` |
| `wear-m3/one-handed-gesture-vertical-page-indicator` | Leaf | — | — | `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color`, `gestureIndicatorTint: string`, `gestureIndicatorBackgroundColor: color` |
| `wear-m3/open-on-phone-dialog` | Leaf | — | — | `text: string`, `visible: bool or object` |
| `wear-m3/open-on-phone-dialog-content` | Container | `content` | `durationMillis: int` | — |
| `wear-m3/open-on-phone-dialog-icon` | Leaf | — | — | — |
| `wear-m3/outlined-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/outlined-card` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/outlined-icon-button` | Container | `content` | — | `onLongClickLabel: string`, `enabled: bool` |
| `wear-m3/picker` | Container | `readOnlyLabel`, `option` | — | `readOnly: bool`, `verticalSpacingDp: float`, `gradientRatio: float`, `gradientColor: color`, `userScrollEnabled: bool` |
| `wear-m3/picker-group` | Container | `content` | — | `autoCenter: bool`, `propagateMinConstraints: bool` |
| `wear-m3/picker-group-item` | Container | `readOnlyLabel`, `option` | `selected: bool` | `verticalSpacingDp: float` |
| `wear-m3/placeholder-sticker` | Container | `content` | — | — |
| `wear-m3/primary-action-button` | Container | `icon`, `text` | — | `containerColor: color`, `contentColor: color` |
| `wear-m3/progress-indicator` | Leaf | — | — | `variant` (circular, segmented-circular, linear, arc), `progress: float or object`, `segments: float or object`, `indicatorColor: color`, `trackColor: color` |
| `wear-m3/radio-button` | Leaf | — | `label: string` | `secondaryLabel: string`, `selected: bool or object`, `enabled: bool`, `shape: string` |
| `wear-m3/screen-scaffold` | Scaffold | `content`, `edgeButton`, `overlays` | — | `timeText: string`, `scrollIndicator: bool`, `background: string`, `themeDisplayTypeface: string`, `themeTitleTypeface: string`, `themeBodyTypeface: string`, `themeLabelTypeface: string`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), 23 `theme…Color` roles |
| `wear-m3/scroll-indicator` | Leaf | — | — | `reverseDirection: bool` |
| `wear-m3/secondary-action-button` | Container | `icon` | — | `containerColor: color`, `contentColor: color` |
| `wear-m3/segmented-circular-progress-indicator` | Leaf | — | `segmentCount: int` | `allowProgressOverflow: bool`, `startAngle: float`, `endAngle: float`, `strokeWidthDp: float`, `gapSizeDp: float`, `enabled: bool` |
| `wear-m3/slider` | Leaf | — | — | `value: float or object`, `valueFrom: float or object`, `valueTo: float or object`, `steps: float or object`, `segmented` (segmented, continuous), `enabled: bool`, `shape: string` |
| `wear-m3/split-checkbox-button` | Container | `secondaryLabel`, `label` | `checked: bool` | `toggleContentDescription: string`, `enabled: bool`, `shape: string`, `containerClickLabel: string` |
| `wear-m3/split-radio-button` | Container | `secondaryLabel`, `label` | `selected: bool` | `selectionContentDescription: string`, `enabled: bool`, `shape: string`, `containerClickLabel: string` |
| `wear-m3/split-switch-button` | Container | `secondaryLabel`, `label` | `checked: bool` | `toggleContentDescription: string`, `enabled: bool`, `shape: string`, `containerClickLabel: string` |
| `wear-m3/stepper` | Container | `content` (1..1) | — | `value: float or object`, `valueFrom: float or object`, `valueTo: float or object`, `steps: float or object`, `enabled: bool` |
| `wear-m3/stepper-level-indicator` | Leaf | — | — | `enabled: bool`, `strokeWidthDp: float`, `sweepAngle: float`, `reverseDirection: bool` |
| `wear-m3/success-confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/swipe-to-dismiss-box` | Container | `content` | — | `backgroundScrimColor: color`, `contentScrimColor: color`, `userSwipeEnabled: bool` |
| `wear-m3/swipe-to-reveal` | Container | `primaryAction`, `secondaryAction`, `undoPrimaryAction`, `undoSecondaryAction`, `content` | — | `hasPartiallyRevealedState: bool`, `actionContentSpacingDp: float` |
| `wear-m3/switch-button` | Leaf | — | `label: string` | `secondaryLabel: string`, `checked: bool or object`, `enabled: bool`, `shape: string` |
| `wear-m3/text` | Leaf | — | `text: string` | `style` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, labelLarge, labelMedium, labelSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), `fontWeight` (normal, medium, semiBold, bold), `fontStyle` (normal, italic), `color: string`, `fontSizeSp: float`, `lineHeightSp: float`, `letterSpacingSp: float`, `fontVariationSettings: string`, `fontFeatureSettings: string`, `minLines: int`, `maxLines: int`, `softWrap: bool`, `overflow` (clip, ellipsis, visible), `textAlign` (start, center, end, justify), `textDecoration` (none, underline, lineThrough), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight: float` |
| `wear-m3/text-button` | Container | `content` (1..1) | — | `variant` (filled, filled-tonal, filled-variant, outlined, standard), `onLongClickLabel: string`, `enabled: bool` |
| `wear-m3/text-toggle-button` | Container | `content` | `checked: bool` | `enabled: bool` |
| `wear-m3/time-picker` | Leaf | — | — | `initialTime: string`, `type` (hours-minutes-seconds, hours-minutes-am-pm, hours-minutes-24h) |
| `wear-m3/time-text` | Leaf | — | — | `maxSweepAngle: float`, `backgroundColor: color` |
| `wear-m3/title-card` | Container | `title`, `time`, `subtitle`, `content` | — | `onLongClickLabel: string`, `enabled: bool`, `shape: string` |
| `wear-m3/transforming-lazy-column` | Container | `items` | — | `verticalSpacingDp: float`, `transformation` (spec, none) |
| `wear-m3/variable-font-text` | Leaf | — | `text: string` | `font` (robotoFlex, googleSansFlex), `wght: float or object`, `wdth: float or object`, `slnt: float or object`, `rond: float or object`, `fontSizeSp: float`, `color: string` |
| `wear-m3/vertical-page-indicator` | Leaf | — | — | `selectedColor: color`, `unselectedColor: color`, `backgroundColor: color` |
| `wear-m3/vertical-pager-scaffold` | Container | `pageIndicator`, `content` | — | — |
