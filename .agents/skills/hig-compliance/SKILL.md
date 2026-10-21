---
name: hig-compliance
description: Apply Apple's current Human Interface Guidelines when writing or modifying any user-facing Apple-platform UI, including views, navigation, gestures, controls, layout, and accessibility.
---

# HIG Compliance

Treat the Human Interface Guidelines as a requirement, not final polish.

Before changing user-facing UI:

1. Identify the affected components, interactions, and platform.
2. Read the relevant current HIG section at <https://developer.apple.com/design/human-interface-guidelines/> using the available web or browser tool.
3. Design and implement against that source. Do not rely on memory when current documentation is available.

Prefer first-party Apple components and system behaviors. Build custom UI only when no native option meets the requirement, and state why.

## Accessibility requirements

These are part of the same requirement. Apply them while writing the UI, not as a later pass. Sources: HIG [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) and [Typography](https://developer.apple.com/design/human-interface-guidelines/typography); re-read them when in doubt.

### Dynamic Type: use Text Styles from the start

- Use semantic text styles: `.font(.largeTitle)`, `.title`, `.headline`, `.body`, `.subheadline`, `.footnote`, `.caption`. Text with no `.font` modifier already uses `.body`.
- Never use a static font size: no `.font(.system(size: 17))`, no `Font.custom("Name", size: 17)` without scaling, no `UIFont.systemFont(ofSize:)`. To tweak a style, use weight or design (`.font(.headline.weight(.semibold))`, `.font(.system(.body, design: .rounded))`).
- For a custom typeface, scale it with a text style: `Font.custom("Name", size: 17, relativeTo: .body)`.
- Size things that sit next to text (icon frames, spacing, padding) with `@ScaledMetric`. Prefer SF Symbols, which scale with the text.
- Do not fix the height of anything that holds text. Do not use `.minimumScaleFactor` or `.lineLimit(1)` to dodge large sizes; let text wrap and keep truncation to a minimum.
- Adapt the layout at accessibility sizes (`@Environment(\.dynamicTypeSize)`, `dynamicTypeSize.isAccessibilitySize`, or `ViewThatFits`): for example stack an `HStack` vertically so text is not crowded.
- Verify before finishing: add a `#Preview` at `.dynamicTypeSize(.accessibility5)` (and the default size), and check the running app with Larger Accessibility Sizes on. Nothing may be clipped, overlapped or unreachable.

### Color contrast

- Minimum contrast ratio (WCAG AA, as used by Accessibility Inspector): **4.5:1** for text up to 17 pt, **3:1** for text at 18 pt and larger, and **3:1** for bold text of any size. Hold icons and meaningful controls to the same standard.
- Check both Light and Dark appearance. If the default colors fall short, provide a higher-contrast variant for Increase Contrast.
- Prefer system colors (`.primary`, `.secondary`, `Color(.systemBackground)`) because they adapt to Dark Mode and Increase Contrast. For custom colors, define them in the asset catalog with Any/Dark and High Contrast variants; do not hard-code `Color(red:green:blue:)` in views.
- Do not rely on `.secondary`, opacity or gray-on-gray for text that carries meaning; verify the resulting ratio.
- Never convey information by color alone. Pair it with a shape, icon or text.
- Verify before finishing: measure foreground/background pairs with Accessibility Inspector (Color Contrast Calculator) in Light, Dark and with Increase Contrast on.

### Related basics

- Interactive controls are at least 44×44 pt.
- Icon-only buttons need a `Label` or `.accessibilityLabel` that says what they do.
