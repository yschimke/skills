# Editable knobs (`previewOverride*`)

A `@Preview` takes no arguments, so everything it shows is baked at authoring
time. **Override knobs** are the opt-in escape hatch: name a value in the
composable, and it becomes editable — re-renderable from the CLI, the preview
server's viewer, or an MCP client — **without a source rebuild**.

```kotlin
// build.gradle.kts
implementation("ee.schimke.composeai:data-preview-overrides-runtime:<version>")
```

```kotlin
@Preview(showBackground = true)
@Composable
fun ShoppingListPreview() {
    val title = previewOverrideString("title", default = "Shopping list")
    val accent = previewOverrideColor("accent", default = Color(0xFF3366FF))
    val rows = previewOverrideInt("rowCount", default = 3)

    Column {
        Text(title, color = accent)
        repeat(rows) { i ->
            // An INDEXED knob: one editable value per row, not one shared by all.
            Text(previewOverrideString("rowLabel", default = "Item ${i + 1}", index = i))
        }
    }
}
```

Each lookup returns the seeded value, or the author's default when nothing is
seeded — so the preview renders identically to a plain one until someone edits
it. Nothing is mocked and no DI is involved; this is orthogonal to
[state hoisting](./state-hoisting.md), which is about making a composable
previewable at all.

## The helpers

| Helper | Type | Notes |
| --- | --- | --- |
| `previewOverrideString(key, default, index)` | `String` | Free text. |
| `previewOverrideInt` / `Float` | `Int` / `Float` | Number field. A count fed into `repeat(n)` is the usual case. |
| `previewOverrideBoolean` | `Boolean` | Checkbox. |
| `previewOverrideColor` | `Color` | Carried as `#AARRGGBB`. |
| `previewOverrideDp` | `Dp` | Carried as a float. |
| `previewOverrideFont(key, default, suggestions, googleFonts)` | `String` | Family name, autocompleting over `suggestions` and (by default) the full Google Fonts list, while staying free-text. |
| `previewOverrideChoice(key, default, options)` | `String` | **Closed value set** — see below. |

`index` is null for a scalar knob. Pass `0, 1, 2, …` inside a `repeat` to get
one editable value per item; the wire key becomes `rowLabel[2]`.

## Closed value sets

A plain string knob publishes its *current* value and nothing about what else it
could be. A size axis renders as a text field reading `s` — correct, and useless
for discovering that `xs` / `m` / `l` / `xl` exist. You either read the source or
guess the spelling and watch the render refuse to move.

`previewOverrideChoice` declares the alphabet alongside the value, and a viewer
renders it as a picker instead:

```kotlin
val size = previewOverrideChoice(
    "size",
    default = "s",
    options = listOf(
        PreviewOverrideOption("xs", "Extra small"),
        PreviewOverrideOption("s", "Small"),
        PreviewOverrideOption("m", "Medium"),
    ),
)
```

The label is what the control shows; the **wire value stays the slug** the
composable reads, so seeding and any existing links are unaffected. When the
values already read as words, pass them bare:

```kotlin
val shape = previewOverrideChoice("shape", default = "round", values = listOf("round", "square"))
```

Two things worth knowing:

- **Nothing enforces the set at render time.** A seed outside it still reaches
  the composable, and the viewer adds it to the picker rather than dropping it —
  so a stale link keeps rendering what it says instead of failing or silently
  snapping to another value.
- **Use it for an axis, not for prose.** A closed set is right for a size, a
  shape, a state, a density. A label or a title is free text and should stay
  `previewOverrideString`.

## Driving them

The declared set travels with the render as the `compose/overrides` data product
— a `previews/<id>.overrides.json` sidecar in a packed bundle — so a consumer
can enumerate *what is editable* before editing anything.

```sh
# Re-render a PUBLISHED bundle with new values. No source, no Gradle, no rebuild.
compose-preview bundle render ./bundle.png --knob title="Groceries" --knob size=xl -o out/
```

```sh
# Serve it and edit interactively: the viewer's Overrides panel lists every
# declared knob, and each edit re-renders. The same values work as URL params.
compose-preview serve --bundle app=./bundle.png
#   → /p/<id>?knob.title=Groceries&knob.size=xl
```

An MCP client seeds the same values through `renderNow.overrides.namedOverrides`
(see [mcp.md](./mcp.md)).

Because the knob is resolved at render time from a value the *caller* supplies,
one baked bundle re-skins to any of these without going near the source tree —
which is what makes an override knob different from just authoring another
`@Preview`.
