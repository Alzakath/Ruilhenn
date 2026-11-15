# Overview and Talents information hierarchy review

Review ID: `2026-11-13-hierarchy-01`. Date: 2026-11-13.

## Evidence and user feedback

Original screenshots remain at their supplied locations, unchanged:

- [Overview](../Screenshot%202026-11-13%20223203.png).
- [Talents](../Screenshot%202026-11-13%20223333.png).

English UI; destination Gravarn, Paladin / Protection; Protection selected and
marked Active. The views show four saved categories and five talent builds,
all marked already present. Locale is visible from copy; client build, UI scale,
EUI/theme settings and exact code revision at capture were not supplied.
Screenshot dimensions are 1253 × 816 and 1244 × 821 respectively; these are
image dimensions, not proof of the client's display resolution.

User: spacing and positioning seem OK compared with the initial mockup, but
information seems placed without purpose, with no hierarchy or contrast.
Treat the existing layout as the working baseline for this review. The user
has not yet accepted the corrections proposed below.

## Prioritized observed findings

| ID | Priority | Observation and journey impact |
| --- | --- | --- |
| H01 | High | Most information uses similarly small, bright, heavy text: category/build names, status, provenance and instructions. The main category title is somewhat larger, but within each region little identifies what to read first. This affects both scanning a backup and deciding what to load. |
| H02 | High | Talents repeats “Already present — kept unchanged” five times with prominence close to the build names. The summary says only “5 loadouts”, leaving the player to infer that all five exist and loading imports none. Load talents remains visually prominent. Its actual response in this state is not established by the capture. |
| H03 | Medium | Overview puts source plus a full numeric timestamp beneath every category in the same bright weight as the main row. Counts sit partway across wide rows and the small chevron immediately follows the count; navigation affordance is weak compared with the repeated metadata. Independent category provenance must be retained. |
| H04 | Medium | The destination character is compressed into a small all-bold block. The label CURRENT CHARACTER, character identity, class/spec and Active specialization compete with each other. Character identity should lead this block. |
| H05 | Medium | On Talents the source/time is one unstructured bright line inside a large panel. “Source” is labeled but date meaning is implicit; source identity and saved time have no visual separation in importance. |
| H06 | Medium | The long Talents instruction paragraph combines restore effect, existing-name policy, editor prerequisites and unspent-point instructions at equal emphasis. The Overview helper says “below” while sitting below the list. Instructions need a defined role and accurate placement language. |

Contrast here means relative emphasis and hierarchy. Bright text on a dark
background is present; these images do not establish a measured contrast-ratio
failure. The dark framed rows are visually similar to one another; additional
borders alone would not solve the text hierarchy problem.

## Proposed correction direction — not yet accepted

Preserve the shell, columns, navigation, major anchors and manager behavior.
Assign each piece of information a role before tuning its appearance:

1. **Primary:** current category, character identity and row names. Use a clearly
   larger or stronger treatment for these identities. Reserve the strongest
   body emphasis for the selectable category/build name.
2. **Secondary:** selected class/spec, content counts and useful status. Use
   ordinary readable body text; make status short and adjacent to what it describes.
3. **Supporting:** source labels, saved time and general guidance. Use a quieter
   neutral tone and regular weight, still readable. Avoid making all text smaller
   or dimming the entire interface. Exact font sizes/colors require a visual pass.
4. **Action and exception:** reserve accent for selection/primary action and
   amber for an actual issue requiring attention. Keep text equivalents. Routine
   “already present” is neutral, not a warning or a restoration-success claim.

Overview proposal: category name leads each row; count/snapshot state is secondary;
source and clearly labeled saved time are tertiary. Keep all category-specific
provenance and distinguish missing/empty. Put a consistent chevron at the row's
trailing edge. Retain “4 of 4 categories saved” as a concise summary. Remove the
generic helper if navigation is self-evident, or use concise position-neutral
copy such as “Choose a category to inspect its saved configuration.”

Talents proposal: summary derived from real inspection data, e.g. in this capture
“5 saved builds · All already on this character”. Build name leads; shorten the
row status to “Already present” with the unchanged-name policy stated once.
For mixed data, distinguish present and available-to-import using words and
counts, never a fabricated completion state. Keep selection/export discoverable.
The exact terminology (“build” versus “loadout”) and copy need agreement and
English/French review before implementation.

Keep one concise persistent effect line: importing missing builds does not
activate them or replace existing names. Group prerequisites as supporting
guidance; elevate an actual blocking reason where relevant. Do not hide the
native editor/point prerequisites solely in a confirmation. Do not change Load
enablement or manager semantics in this typography pass without a separate
explicit decision; a truthful “nothing missing” summary can clarify this state.

Source proposal: emphasize source character, then show a subdued “Saved …”
line. Destination proposal: small quiet CURRENT CHARACTER label, prominent
character name, secondary class/spec, understated active-state text. Preserve
the active-versus-selected distinction when browsing another specialization.

## Unverified behavior and next review

Optional addition: hero talent tree identification is recorded as **Nice to
have** in [the feature document](../../../TEMPLATE-BROWSER.md#optional-hero-talent-identification).
Recommended row placement is a secondary line under the left-aligned build
name, with import status remaining separate at the right. This is a positioning
proposal; the current mockup has not been revised to include it, and it must
not block the core hierarchy pass.

Draft visual proposal: `docs/ui/drafts/hierarchy-preview.html` previews Overview
and Talents with selectable navigation, using the supplied example data.
It illustrates typography/color hierarchy, quieter provenance, shorter statuses,
trailing chevrons and the intended flat scrollbar appearance. It is not accepted
artwork or verified EUI rendering. Save/Load are inert preview controls; scrollbar
art is illustrative. No production behavior or new export workflow is implied.
The full date remains in Talents; Overview's shortened date presentation is a
proposal to review, not an accepted change. Await user feedback before handoff.

### Follow-up: color approval and scrollbar appearance

User explicitly agreed the proposed color choices. The accepted policy now
lives in [the feature record](../../../TEMPLATE-BROWSER.md#accepted-color-policy);
other hierarchy/copy proposals above remain proposals.

User also questioned the Talents scrollbar. **Observed:** decorative native-like
arrow/button art remains at the list's right edge. **Source evidence:** installed
EllesmereUI/SKINNING_API.md documents `S.ScrollBar(scrollBar)` as fading
arrows/track art and painting a thin white thumb strip without changing scroll
behavior. Ruilhenn's `scroll` helper already calls
`UI:Style(frame.ScrollBar, "ScrollBar")` for its UIPanelScrollFrameTemplate.
This does not prove the primitive successfully styled the displayed parts.

**Inference:** the visible result is inconsistent with the documented intended
treatment; an integration/lifecycle or control-shape mismatch is plausible.
Whether EUI skinning is enabled for this capture, whether the callback ran,
which child regions it handled and whether native code restored artwork are
unverified. Do not blame or modify EUI internals, or promise a specific fix,
without diagnosis. No runtime code was changed in this review.

These captures do not verify hover/focus, selection/export, inactive or combat
states, French layout, standalone/EUI differences, scrolling operation or load
outcomes. The Talents list appears to approach the bottom of its viewport;
test scrolling separately before calling any partial row a defect.

Next: agree the hierarchy/content direction and then prepare a bounded
presentation request (or mockup if needed). Do not send implementation yet.
Compare later captures using the same views/data where possible; names should
be readable first, status second and provenance third without removing useful
information. Feature status belongs in
[TEMPLATE-BROWSER.md](../../../TEMPLATE-BROWSER.md#overview-and-talents-hierarchy-review--2026-11-13).
