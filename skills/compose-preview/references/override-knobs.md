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

## Parameter knobs, and the `enum` kind

There is a second way to declare a knob that needs no runtime dependency at all:
give the `@Preview` function a **parameter with a default**. Discovery reads the
defaults out of the compiled body and publishes them as knobs, so the preview
still renders standalone and the parameter becomes editable.

```kotlin
@Preview
@Composable
fun BadgePreview(label: String = "New", count: Int = 3, compact: Boolean = false) { … }
```

A `String` parameter is a text box — which is the same loss `previewOverrideString`
has against `previewOverrideChoice`: it shows the current value and hides every
alternative. **Declare an `enum class` instead** and the constants *are* the
closed set:

```kotlin
enum class Emphasis { Filled, Tonal, Outlined }

@Preview
@Composable
fun EmphasisPreview(emphasis: Emphasis = Emphasis.Tonal) { … }
```

Discovery records the kind as `ENUM` with the constants as `options`, both
renderers declare it `optionsExhaustive = true`, and a viewer draws exactly the
picker `previewOverrideChoice` produces. It is better than the string it
replaces on the Kotlin side too: the `when` over it is exhaustive, so a constant
added later is a compile error rather than a branch that quietly falls through.

### `@KnobValue` — when the constant's name is not the value

By default a constant answers to **its own name**, which is right for a knob
written from scratch. It is wrong for one being migrated. A catalog that has been
calling `previewOverrideChoice("iconSize", "default", listOf("default", "large",
"extra-large"))` has that vocabulary written into every
`@OverrideVariant(strings = ["iconSize=extra-large"])` it has accumulated **and**
into the design kit its renders are compared against, where a mismatched value
drops the node from the comparison with no diagnostic anywhere. Rename the value
to `ExtraLarge` and every seed silently falls back to the author default.

Several such values cannot be Kotlin identifiers at all — `12-sided cookie`,
`4-leaf clover`, `0.0`, `24s`. So the constant **declares the text** instead of
being renamed to it:

```kotlin
import ee.schimke.composeai.preview.KnobValue

enum class IconSize {
  @KnobValue("default") Default,
  @KnobValue("large") Large,
  @KnobValue("extra-large") ExtraLarge,
}
```

Everything downstream then speaks one vocabulary — the published `options`, the
viewer's picker, an `@OverrideVariant` seed, and the declared default (read out
of the compiled body as the constant name and translated back). Constants
without the annotation answer to their own names, so the two forms mix freely.

Worth knowing about the shape:

- **The seed crosses the wire as text.** Nothing before the renderer's invoke
  seam holds the enum's `Class`, so the value becomes a constant at the one point
  that can build it. A name matching no constant is dropped and the author
  default renders — the honest answer to a stale client naming a constant that a
  rename removed.
- **Values must be distinct within an enum.** Two constants claiming one seed
  text make the seed ambiguous, so discovery drops that enum's options entirely
  rather than binding whichever it saw first.
- **An enum with no resolvable options is not a knob at all**, rather than a knob
  whose values are unknown: a picker with nothing in it is worse than the text
  box it replaced.
- **The renderers resolve `@KnobValue` by name, not by type**, so no published
  renderer artifact depends on `:preview-annotations` — a consumer that never
  uses the annotation simply has no class by that name.

What parameter knobs still cannot do: there is no `Color` or `Dp` kind (an ARGB
`Long` is the stand-in, and it costs the colour picker), no **indexed** knob (a
parameter list is fixed-arity), and no knob declared outside the `@Preview`
function. Those remain reasons to reach for `previewOverride*`. Full rationale:
[`docs/design/PARAMETER_KNOB_MIGRATION.md`](https://github.com/yschimke/compose-ai-tools/blob/main/docs/design/PARAMETER_KNOB_MIGRATION.md).

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
# (`serve` ships from yschimke/compose-preview-server.)
compose-preview serve --bundle app=./bundle.png
#   → /p/<id>?knob.title=Groceries&knob.size=xl
```

An MCP client seeds the same values through `renderNow.overrides.namedOverrides`
(see [mcp.md](./mcp.md)). Against a **remote** server, they are the `overrides`
object on the catalog MCP's `render_preview` — which refuses an unknown key
rather than ignoring it, and reports `overridesApplied: false` when the bundle it
is serving has no renderer to honour them
(see [catalog-mcp.md](./catalog-mcp.md)).

Because the knob is resolved at render time from a value the *caller* supplies,
one baked bundle re-skins to any of these without going near the source tree —
which is what makes an override knob different from just authoring another
`@Preview`.
