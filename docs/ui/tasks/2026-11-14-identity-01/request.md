# Class identity and category navigation icons

Task ID: `2026-11-14-identity-01`

Status: **Ready for implementation**.

Authorization: user explicitly accepted the accent, class-color and category
icon recommendations, then requested this developer handoff. The user relays
the request; file creation does not start implementation.

## Problem and intended outcome

Make selection, character identity and category navigation easier to recognize
while preserving the accepted layout and information hierarchy. Follow EUI's
configured accent; distinguish destination from source through restrained class
color; add readable icons alongside existing category labels.

Authority: [accepted feature decisions](../../../TEMPLATE-BROWSER.md#selection-and-class-identity-review--2026-11-14),
[UI-SPEC.md](../../../UI-SPEC.md), and
[review evidence](../../feedback/2026-11-14-identity-01/observations.md).
The comparison screenshot linked there supplies context, not a requirement to
copy EUI's private navigation artwork. The original accepted PNG illustrates
icon roles; generated icons are not production assets. No additional mockup is
required before this explicitly accepted bounded pass.

## Source and working-tree context

Inspected HEAD: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`. TemplateBrowser.lua
and TemplateStore.lua are untracked; catalogs, managers, tests and packaging
contain substantial unrelated uncommitted work. Inspect current files before
editing; HEAD alone cannot reproduce the reviewed implementation. Preserve the
accepted hierarchy pass, recycled-row alignment, Refresh preview labels and
width, scrollbar fallback, and removal of temporary diagnostics.

Current presentation includes `accentColor`, `selectNavigation`, semantic text
roles and optional public skin application. Buttons create `icon` and
`selectionMarker` before public skin setup and preserve them with keepKeys.
Sidebar destination and category source/date are separate regions.
TemplateStore:SourceDetails exposes provenance but source character and realm
currently share one stored string. Do not duplicate the restore path.

## Required changes

### Follow the existing EUI accent

Use the live public `S.GetAccentColor()` for selected category icon/label and
selection marker, selected specialization label/marker, selected talent marker
and existing primary-action emphasis. Preserve non-color selection cues.
Do not hardcode green or override a configured white accent. Users change
their accent in EUI; no Ruilhenn accent setting is added. Keep the existing
standalone accent fallback. Existing correct accent behavior may be preserved
and verified rather than rewritten. Unselected icons/labels remain neutral.
Do not add a filled selected-row background as part of this request.

### Destination class color

Color the current character name and **class word only** with the standard
game class color. Example: Dineau and Druid orange, Guardian/realm/active text
neutral. Do not color the entire class/spec line or sidebar. Use verified class
color APIs/data for the installed Retail target and localized class text.
Keep text roles/sizes and overall sidebar positions intact. No new toggles.

### Source class color

In category headers and Overview rows, color only the known source character
name with class color blended toward neutral gray at **full opacity**. Realm,
Source label, date and other provenance remain muted neutral. Keep source
identity less vivid than destination identity; source/header prominence still
follows the accepted hierarchy.

Use a shared blend constant/helper. Exact blend is an implementation choice;
report it and verify readable output for darker class colors. Do not implement
this with lowered alpha or simple darkening. Preserve standard destination class
color. Class association must come from reliable template/current-class context,
never a guessed class inferred from a character name. Unknown class/source uses
a neutral fallback and retains honest unknown-date/source wording.

Expose structured presentation fields as needed. Source storage currently
combines name/realm: inspect its actual stored format. A tested split of the
documented storage delimiter is acceptable; parsing localized display text,
guessing legacy formats or fabricating provenance is not. If separation cannot
be established, preserve the original readable text neutrally. No SavedVariables
migration or resave requirement. Escape player text safely and do not let color
markup leak into the realm/date or adjacent regions.

### Category navigation icons

Add small consistent monochrome icons inside the five existing sidebar buttons:

| Destination | Symbol |
| --- | --- |
| Overview | House |
| Talents | Talent tree |
| Action bars | Slot grid |
| Key bindings | Keyboard |
| Click casting | Mouse |

Use a shared icon box, left inset, icon-to-label gap and text start; left-align
the icon+label groups. Retain sidebar/button dimensions, full button hit region,
navigation order and readable English/French labels. Typical icon size is
16–20 logical pixels, a starting choice to validate rather than a fixed pixel
requirement. Icon/label/marker follow accent selection and theme updates.

Use verified native assets if suitable, otherwise small addon-owned monochrome
assets. Do not use private EUI assets, generated PNG artwork or missing atlas
names. Prefer a coherent icon family over mismatched colored game textures.
Preserve icons through public Button styling, lazy setup and subsequent theme
changes. Decorative icons are not separate focus stops. No Utilities navigation,
specialization icons or icons throughout every content row in this pass.

## Scope and exclusions

Expected files: TemplateBrowser.lua, presentation-only additions in
TemplateStore.lua, narrowly relevant tests/fixtures, catalogs only if required
for changed text composition, feature implementation evidence, response.md.
Read AGENTS.md, relevant installed WoW skills and EUI's public SKINNING_API.md.
If new icon assets are packaged, ensure the TOC-driven packager explicitly
includes/verifies them and `.pkgmeta` still excludes developer-only artifacts.

No changes to managers, save/load semantics, storage layout, compatibility/combat
guards, confirmations, talent import lifecycle, scrolling behavior, diagnostics,
or previously accepted labels. No new dependency, preference, logging level,
hero talent resolution, broader redesign or EUI-internal edits. Preserve
RETAIL-API-REVIEW.md and all unrelated changes. Do not edit request.md, review.md
or design references. Do not commit, push or start other agents/communication.

## Observable acceptance criteria

1. With a non-white EUI accent, selection icon/label/marker visibly follows that
   accent; changing accent updates existing/lazy controls. Configured white is
   respected. Standalone remains usable with the existing fallback.
2. Destination name/class word use the correct class color; spec, realm and
   active-state text remain neutral. Verify at least Druid, Paladin and a darker
   class color where available; unknown data falls back safely.
3. Known source names use a consistent subdued full-opacity blend in both
   Overview/header; realm/date/labels stay neutral. Mixed category sources and
   unknown/legacy provenance remain truthful, readable and correctly isolated.
4. All five category controls have coherent, recognizable icons, shared label
   alignment, unchanged hit regions and non-color selection cues. No overlaps
   with markers/labels and no loss on late skin setup/theme refresh.
5. English/French long labels and long character/realm text fit at normal and
   smaller UI scales without clipping. Existing selection/export, refresh,
   confirmation, row reuse and mutation guards retain their behavior.
6. Any new runtime assets exist and are present in the verified release file
   list; developer documents/feedback/drafts remain excluded.

## Checks, client evidence and response

Run stock Lua 5.1 `tests/run.lua` and `python tools/package_release.py --check`.
Use meaningful regression checks for dynamic class/accent roles, neutral reset,
source separation/fallback and late/lazy/theme icon preservation. Do not equate
pixel-coordinate tests or color mocks with a rendered appearance pass.

In game: capture Overview and a category with destination/source visible, plus
selected/inactive specialization and selected talent row. Include EUI accent
value/theme context, language and UI scale. Verify non-white and white accents,
representative class colors, independent/unknown source, French fit and
standalone after reload. Check mouse/keyboard/controller-cursor reachability
and focus with the same whole-button actions; no new input capture/bindings.
Mark unavailable states NOT RUN. Do not mutate backups just to produce captures.

No open product question blocks this accepted scope. Exact asset feasibility,
class-color access, source separation and final blend readability are technical
dependencies to verify. Report a concrete obstacle before expanding scope.
Write response.md here with changed files, icon asset provenance, blend choice,
verification results and remaining captures. Update feature evidence without
rewriting accepted requirements. The user relays your report for UI review.
