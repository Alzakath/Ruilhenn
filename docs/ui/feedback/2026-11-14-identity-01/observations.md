# Selection, class identity and navigation icons

New design review: `2026-11-14-identity-01`. Status: recommendations accepted;
no implementation request yet. The user accepted the previous development and
requested a separate UI refinement discussion.

Evidence: [EUI/Ruilhenn comparison](../Screenshot%202026-11-14%20013400.png).
English; Dineau, Druid / Guardian selected and active, two already-present talent
loadouts, one selected with export visible. EUI v9.8.4 settings are shown beside
Ruilhenn. Exact client build, capture revision and Ruilhenn rendering scale are
not independently recorded; EUI's UI Scale setting visibly reads 0.64.

## Observed and inferred

### Implementation captures and user feedback

New evidence: [Click casting 021208](../Screenshot%202026-11-14%20021208.png)
and [Overview 021223](../Screenshot%202026-11-14%20021223.png). User is happy
with the color choices; icon recognizability remains in question. Capture shows
orange Druid destination name/class and a quieter source name with neutral realm
and dates, consistent with the accepted direction. No full task acceptance or
complete class/theme/locale matrix is inferred.

Reviewer assessment: action-slot grid and keyboard are recognizable; Overview
reads more like a forked/tower symbol than a conventional house, Talents resembles
a crown/tray rather than a branching talent tree, and the tiny mouse silhouette
is visually noisy. Developer response describes runtime solid-texture line
construction; asset-free implementation does not by itself establish semantic
clarity. Proposal: refine house/tree/mouse silhouettes using a coherent icon
family, retaining labels, alignment and current successful color roles. This
refinement is not yet authorized as a new task.

EUI has a green/teal logo and some green action accents; selected General tab
has a white underline and the selected left navigation row has a neutral fill.
Ruilhenn selection text/markers are white in this capture. The visible UI Accent
Color controls include a white swatch, but the screenshot does not establish the
precise value returned by the public GetAccentColor getter. Branding green must
not be assumed identical to the user's selected accent.

Ruilhenn currently has no visible category icons. The accepted original PNG
includes them, but the written first-slice scope made navigation icons optional.
Restoring them now is a new refinement, not a defect in the accepted first pass.

## Accepted direction

Subsequent decision: user explicitly accepted following EUI's configured accent;
users change that preference in EUI when they want another color. The accent
recommendation below is now accepted, with no separate Ruilhenn color setting.
User subsequently accepted the class-color and icon recommendations, including
the later subdued source-name treatment. Authoritative decision:
[feature record](../../../TEMPLATE-BROWSER.md#selection-and-class-identity-review--2026-11-14).

- Selection uses the **live user EUI accent**, not hardcoded green. Apply it to
  selected category icon/label and marker, selected specialization marker/label,
  and selected build marker. Keep a non-color marker. A subtle selected-row
  treatment can be explored if achievable through public styling without
  fighting the optional skin; do not promise a filled green tab yet.
- Keep unselected icons/labels neutral. Users choose another accent in EUI;
  no separate Ruilhenn accent preference.
- Use standard character class color for the **current character's name** and
  the class word only; realm, specialization and active-state text remain neutral.
  Example: orange Dineau and Druid, neutral Guardian/KirinTor. This provides
  class identity without making the whole sidebar a competing color block.
  Source names use class color blended toward gray at full opacity, consistently
  in Overview and category headers; realm/date stay neutral. This later decision
  supersedes the earlier recommendation to keep source identity fully neutral.
  Maintain readable contrast for all classes; avoid transparency/darkening.
- Add small consistent monochrome icons to the five existing category controls:
  house/overview, talent tree/talents, slot grid/action bars, keyboard/key bindings,
  mouse/click casting. Left-align the icon+label group with a shared text start.
  Use packaged or verified native assets; do not extract generated art or private
  EUI assets. Icons reinforce visible labels and are not separate focus targets.
  No new Utilities destination. Optional specialization icons are deferred.

The installed EUI public API documents GetAccentColor as the user's live accent;
S.Button leaves label color untouched. Exact icon assets, styling geometry and
font/skin callbacks require implementation research after scope agreement.
No runtime behavior, localization catalogs or tests were changed in this review.

Next: prepare a focused developer request for the accepted scope. A filled
selection background remains exploratory, not required. Preserve hierarchy, restoration
semantics and prior screenshot evidence. Feature requirements/status belong in
[TEMPLATE-BROWSER.md](../../../TEMPLATE-BROWSER.md#selection-and-class-identity-review--2026-11-14).
