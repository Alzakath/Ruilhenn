# Implementation report — 2026-11-14-identity-01

Status: **Implemented locally; UI review and in-game visual verification pending.**

## Behavior and changed files

- `TemplateBrowser.lua`: destination character name and class word use the
  current class color via `C_ClassColor.GetClassColor`. Realm, specialization
  and active-state text retain neutral roles. Source names in the category
  header and Overview rows use the same subdued class blend; source realm and
  saved date remain neutral. Unknown class values and unseparated legacy source
  strings stay neutral. Player-provided names are escaped before color markup.
- `TemplateStore.lua`: exposes source name/realm only when the exact stored
  ` — ` delimiter separates both fields. It associates the class from the
  catalog entry and retains the existing `character` field and storage format.
- `TemplateBrowser.lua`: adds house, talent-tree, slot-grid, keyboard and mouse
  glyphs in one left-side icon box, with a common left-aligned label start.
  Glyphs, labels and the existing non-color marker follow the live EUI accent;
  the existing standalone accent fallback remains. The named texture regions
  are passed to public `S.Button` keep keys. Button dimensions, navigation order
  and the whole-button action remain intact.
- `tests/AddonFixture.lua`, `tests/UIFixture.lua`,
  `tests/TemplateBrowserTest.lua`: add class-color, source parsing/fallback,
  icon alignment, EUI keep-key, live accent/white accent and darker-class
  blend regressions.
- `docs/TEMPLATE-BROWSER.md`: records the implementation evidence and current
  verification status.

## Asset and color choices

Icons use no added asset files. Each monochrome line glyph is assembled at
runtime from rotated solid textures using Blizzard's native
`Interface\Buttons\WHITE8X8` texture. No generated PNGs, atlas guesses,
private EUI artwork or EUI changes are involved.

Source RGB is a linear channel blend: **55% class color + 45% neutral gray
(0.72, 0.76, 0.78)**. It is emitted with full-opacity `|cffRRGGBB` markup;
there is no lowered font alpha or simple class-color darkening. The dark
Demon Hunter fixture yields `#AC72C8`; this is an automated color calculation,
not a rendered contrast check. Destination colors remain unblended.

The class-color call follows the bundled Retail 12.1.5.70783 API declaration
for `C_ClassColor.GetClassColor`, which returns a `colorRGB`/`ColorMixin`.
Runtime availability and appearance were not tested in the game client here.

## Checks

- `lua tests/run.lua` — **176 passed, 0 failed**.
- `python tools/package_release.py --check` — **passed**, 28 files, interface
  120105. No new packaged assets were needed.
- `git diff --check` — **passed**. Git printed existing LF-to-CRLF
  working-copy warnings for unrelated modified files.
- No manager, restore lifecycle, storage schema, scroll behavior or saved
  backup was changed. Source parsing adds presentation fields only.
- No commit or push was performed. The task started from a broad uncommitted
  worktree; unrelated edits were preserved. Starting source revision recorded
  by the request: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`.

## Remaining in-game verification

Actual rendering and input checks remain **NOT RUN**. In particular, English
and French sidebar label fit at normal and smaller UI scales is unverified.
Capture Overview and a saved category with known and legacy/unknown sources;
include the selected/inactive specialization and selected talent row. Check
Druid, Paladin and a darker class, non-white and white EUI accents, then change
the accent without reloading and confirm lazy/late skin controls retain icons.
Repeat with EUI skinning disabled. Verify class/source contrast, name/realm/date
isolation, French label fit, lower UI scale, and mouse, keyboard and native
controller-cursor reachability. Existing screenshots and mocked tests do not
establish clipping, rendering, focus behavior or client-side API availability.

No product requirement was changed or deferred. Source values not matching the
documented delimiter intentionally remain readable and uncolored; this follows
the accepted fallback behavior.
