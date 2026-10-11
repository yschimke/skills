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
| `asset/image` | Leaf | — | `assetKey` | `contentDescription`, `contentScale` (crop, fit, fillBounds, inside), `alignment` |
| `confetti-wear/confetti-preview-scaffold` | Container | `content` | — | `seedColor` |
| `confetti-wear/confetti-theme-fixed` | Container | `content` | — | — |
| `confetti-wear/placeholder-button` | Leaf | — | — | `secondaryLabel`, `hasIcon`, `enabled` |
| `confetti-wear/screen-header` | Leaf | — | `text` | — |
| `confetti-wear/section-header` | Leaf | — | `text` | — |
| `confetti-wear/session-card` | Container | `timeDisplay` | `isBookmarked` | — |
| `confetti-wear/test-scaffold` | Container | `content` | — | — |
| `layout/box` | Container | `children` | — | `contentAlignment`, `propagateMinConstraints` |
| `layout/column` | Container | `children` | — | `verticalArrangement` (top, center, bottom, spaceBetween, spaceAround, spaceEvenly), `verticalSpacingDp`, `horizontalAlignment` (start, center, end), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `layout/row` | Container | `children` | — | `horizontalArrangement` (start, center, end, spaceBetween, spaceAround, spaceEvenly), `horizontalSpacingDp`, `verticalAlignment` (top, center, bottom) |
| `wear-m3/alert-dialog` | Container | `content`, `confirmButton`, `dismissButton` | `title` | `text`, `visible` |
| `wear-m3/alert-dialog-content` | Container | `confirmButton`, `title`, `dismissButton`, `icon`, `text` | — | — |
| `wear-m3/alert-dialog-edge-button` | Container | `content` | — | — |
| `wear-m3/animated-page` | Container | `content` | `pageIndex` | `contentScrimColor` |
| `wear-m3/animated-text` | Leaf | — | `text` | — |
| `wear-m3/app-card` | Container | `appName`, `title`, `appImage`, `time`, `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/app-scaffold` | Container | `timeText`, `content` | — | `containerColor`, `contentColor` |
| `wear-m3/arc-progress-indicator` | Leaf | — | — | `startAngle`, `endAngle`, `strokeWidthDp`, `gapSizeDp` |
| `wear-m3/button` | Container | `content` (1..*) | — | `variant` (filled, filled-tonal, outlined, child), `enabled`, `containerColor`, `contentColor`, `onClickAction`, `onLongClickLabel`, `shape` |
| `wear-m3/button-group` | Container | `children` | — | `spacingDp`, `expansionWidthDp` |
| `wear-m3/card` | Container | `content` (1..*) | — | `variant` (title, app, outlined, plain), `stableKey`, `onClickAction`, `containerColor`, `contentColor`, `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/checkbox-button` | Leaf | — | `label` | `secondaryLabel`, `checked`, `enabled`, `shape` |
| `wear-m3/child-button` | Container | `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/circular-progress-indicator` | Leaf | — | — | `enabled`, `allowProgressOverflow`, `startAngle`, `endAngle`, `strokeWidthDp`, `gapSizeDp` |
| `wear-m3/compact-button` | Container | `icon`, `label` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/confirm-button` | Container | `content` | — | — |
| `wear-m3/confirmation-dialog` | Leaf | — | `text` | `variant` (generic, success, failure), `visible` |
| `wear-m3/confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/date-picker` | Leaf | — | — | `initialDate`, `type` (year-month-day, day-month-year, month-day-year) |
| `wear-m3/decrease-icon` | Leaf | — | — | `contentDescription` |
| `wear-m3/dismiss-button` | Container | `content` | — | — |
| `wear-m3/edge-button` | Container | `content` (1..1) | — | `size` (extra-small, small, medium, large), `containerColor`, `contentColor`, `enabled` |
| `wear-m3/fading-expanding-label` | Leaf | — | `text` | `color`, `fontSizeSp`, `fontStyle`, `fontWeight`, `letterSpacingSp`, `textDecoration`, `textAlign`, `lineHeightSp`, `softWrap`, `maxLines`, `minLines` |
| `wear-m3/failure-confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/filled-icon-button` | Container | `content` | — | `onLongClickLabel`, `enabled` |
| `wear-m3/filled-tonal-button` | Container | `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/filled-tonal-icon-button` | Container | `content` | — | `onLongClickLabel`, `enabled` |
| `wear-m3/horizontal-page-indicator` | Leaf | — | — | `selectedColor`, `unselectedColor`, `backgroundColor` |
| `wear-m3/horizontal-pager-scaffold` | Container | `pageIndicator`, `content` | — | — |
| `wear-m3/icon` | Leaf | — | `iconKey` (<11431 values; ask for full>) | `sizeDp`, `contentDescription`, `color`, `tint` |
| `wear-m3/icon-button` | Container | `content` (1..1) | — | `variant` (filled, filled-tonal, filled-variant, outlined, standard), `containerColor`, `contentColor`, `onLongClickLabel`, `enabled` |
| `wear-m3/icon-toggle-button` | Container | `content` | `checked` | `enabled` |
| `wear-m3/increase-icon` | Leaf | — | — | `contentDescription` |
| `wear-m3/level-indicator` | Leaf | — | — | `enabled`, `strokeWidthDp`, `sweepAngle`, `reverseDirection` |
| `wear-m3/linear-progress-indicator` | Leaf | — | — | `strokeWidthDp`, `enabled` |
| `wear-m3/list-header` | Leaf | — | `text` | `maxLines`, `overflow` (clip, ellipsis, visible), `backgroundColor`, `contentColor` |
| `wear-m3/list-sub-header` | Leaf | — | `text` | `maxLines`, `overflow` (clip, ellipsis, visible), `backgroundColor`, `contentColor` |
| `wear-m3/one-handed-gesture-click-indicator` | Container | `content` | — | `gestureIndicatorTint` |
| `wear-m3/one-handed-gesture-horizontal-page-indicator` | Leaf | — | — | `selectedColor`, `unselectedColor`, `backgroundColor`, `gestureIndicatorTint`, `gestureIndicatorBackgroundColor` |
| `wear-m3/one-handed-gesture-scroll-indicator` | Leaf | — | — | `gestureIndicatorTint`, `gestureIndicatorBackgroundColor`, `reverseDirection` |
| `wear-m3/one-handed-gesture-vertical-page-indicator` | Leaf | — | — | `selectedColor`, `unselectedColor`, `backgroundColor`, `gestureIndicatorTint`, `gestureIndicatorBackgroundColor` |
| `wear-m3/open-on-phone-dialog` | Leaf | — | — | `text`, `visible` |
| `wear-m3/open-on-phone-dialog-content` | Container | `content` | `durationMillis` | — |
| `wear-m3/open-on-phone-dialog-icon` | Leaf | — | — | — |
| `wear-m3/outlined-button` | Container | `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/outlined-card` | Container | `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/outlined-icon-button` | Container | `content` | — | `onLongClickLabel`, `enabled` |
| `wear-m3/picker` | Container | `readOnlyLabel`, `option` | — | `readOnly`, `verticalSpacingDp`, `gradientRatio`, `gradientColor`, `userScrollEnabled` |
| `wear-m3/picker-group` | Container | `content` | — | `autoCenter`, `propagateMinConstraints` |
| `wear-m3/picker-group-item` | Container | `readOnlyLabel`, `option` | `selected` | `verticalSpacingDp` |
| `wear-m3/placeholder-sticker` | Container | `content` | — | — |
| `wear-m3/primary-action-button` | Container | `icon`, `text` | — | `containerColor`, `contentColor` |
| `wear-m3/progress-indicator` | Leaf | — | — | `variant` (circular, segmented-circular, linear, arc), `progress`, `segments`, `indicatorColor`, `trackColor` |
| `wear-m3/radio-button` | Leaf | — | `label` | `secondaryLabel`, `selected`, `enabled`, `shape` |
| `wear-m3/screen-scaffold` | Scaffold | `content`, `edgeButton`, `overlays` | — | `timeText`, `scrollIndicator`, `background`, `themeDisplayTypeface`, `themeTitleTypeface`, `themeBodyTypeface`, `themeLabelTypeface`, `themeTextStyle` (displayLarge, displayMedium, displaySmall, titleLarge, titleMedium, titleSmall, labelLarge, labelMedium, labelSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), 23 `theme…Color` roles |
| `wear-m3/scroll-indicator` | Leaf | — | — | `reverseDirection` |
| `wear-m3/secondary-action-button` | Container | `icon` | — | `containerColor`, `contentColor` |
| `wear-m3/segmented-circular-progress-indicator` | Leaf | — | `segmentCount` | `allowProgressOverflow`, `startAngle`, `endAngle`, `strokeWidthDp`, `gapSizeDp`, `enabled` |
| `wear-m3/slider` | Leaf | — | — | `value`, `valueFrom`, `valueTo`, `steps`, `segmented` (segmented, continuous), `enabled`, `shape` |
| `wear-m3/split-checkbox-button` | Container | `secondaryLabel`, `label` | `checked` | `toggleContentDescription`, `enabled`, `shape`, `containerClickLabel` |
| `wear-m3/split-radio-button` | Container | `secondaryLabel`, `label` | `selected` | `selectionContentDescription`, `enabled`, `shape`, `containerClickLabel` |
| `wear-m3/split-switch-button` | Container | `secondaryLabel`, `label` | `checked` | `toggleContentDescription`, `enabled`, `shape`, `containerClickLabel` |
| `wear-m3/stepper` | Container | `content` (1..1) | — | `value`, `valueFrom`, `valueTo`, `steps`, `enabled` |
| `wear-m3/stepper-level-indicator` | Leaf | — | — | `enabled`, `strokeWidthDp`, `sweepAngle`, `reverseDirection` |
| `wear-m3/success-confirmation-dialog-content` | Container | `content` | — | — |
| `wear-m3/swipe-to-dismiss-box` | Container | `content` | — | `backgroundScrimColor`, `contentScrimColor`, `userSwipeEnabled` |
| `wear-m3/swipe-to-reveal` | Container | `primaryAction`, `secondaryAction`, `undoPrimaryAction`, `undoSecondaryAction`, `content` | — | `hasPartiallyRevealedState`, `actionContentSpacingDp` |
| `wear-m3/switch-button` | Leaf | — | `label` | `secondaryLabel`, `checked`, `enabled`, `shape` |
| `wear-m3/text` | Leaf | — | `text` | `style` (displayLarge, displayMedium, displaySmall, headlineLarge, headlineMedium, headlineSmall, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, bodyExtraSmall, labelLarge, labelMedium, labelSmall, numeralExtraLarge, numeralLarge, numeralMedium, numeralSmall, numeralExtraSmall), `fontWeight` (normal, medium, semiBold, bold), `fontStyle` (normal, italic), `color`, `fontSizeSp`, `lineHeightSp`, `letterSpacingSp`, `fontVariationSettings`, `fontFeatureSettings`, `minLines`, `maxLines`, `softWrap`, `overflow` (clip, ellipsis, visible), `textAlign` (start, center, end, justify), `textDecoration` (none, underline, lineThrough), `alignment` (topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd), `weight` |
| `wear-m3/text-button` | Container | `content` (1..1) | — | `variant` (filled, filled-tonal, filled-variant, outlined, standard), `onLongClickLabel`, `enabled` |
| `wear-m3/text-toggle-button` | Container | `content` | `checked` | `enabled` |
| `wear-m3/time-picker` | Leaf | — | — | `initialTime`, `type` (hours-minutes-seconds, hours-minutes-am-pm, hours-minutes-24h) |
| `wear-m3/time-text` | Leaf | — | — | `maxSweepAngle`, `backgroundColor` |
| `wear-m3/title-card` | Container | `title`, `time`, `subtitle`, `content` | — | `onLongClickLabel`, `enabled`, `shape` |
| `wear-m3/transforming-lazy-column` | Container | `items` | — | `verticalSpacingDp`, `transformation` (spec, none) |
| `wear-m3/variable-font-text` | Leaf | — | `text` | `font` (robotoFlex, googleSansFlex), `wght`, `wdth`, `slnt`, `rond`, `fontSizeSp`, `color` |
| `wear-m3/vertical-page-indicator` | Leaf | — | — | `selectedColor`, `unselectedColor`, `backgroundColor` |
| `wear-m3/vertical-pager-scaffold` | Container | `pageIndicator`, `content` | — | — |
