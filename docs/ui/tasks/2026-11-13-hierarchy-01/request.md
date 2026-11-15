# Overview and Talents hierarchy pass

Task ID: `2026-11-13-hierarchy-01`

Status: **Ready for implementation**.

Authorization: user asked to prepare development instructions for “our choices”
following screenshot review, color approval, mockup discussion and explicit
classification of hero talent names as nice to have. This request bounds that
handoff; the user relays it to Lua Codex. File creation does not start work.

## Problem, outcome and sources

Overview and Talents have acceptable overall spacing/positioning, but metadata,
names, status and instructions compete at similar weight/brightness. Improve
scan order: identity first, status/count second, provenance/guidance third.
Preserve the current shell and restoration semantics.

Source HEAD: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`. Browser/store files
are untracked and catalogs/managers/tests/packaging already contain extensive
local changes. HEAD alone is not the reviewed implementation. Preserve all
unrelated work and the accepted Refresh preview rename/152-pixel button.

Read AGENTS.md, UI-SPEC.md, TEMPLATE-BROWSER.md, RESTORE-FIXES.md and the
applicable installed WoW skills. Feature authority:
[hierarchy review](../../../TEMPLATE-BROWSER.md#overview-and-talents-hierarchy-review--2026-11-13),
[color policy](../../../TEMPLATE-BROWSER.md#accepted-color-policy),
[optional hero identification](../../../TEMPLATE-BROWSER.md#optional-hero-talent-identification).

Evidence: [observations and original screenshot links](../../feedback/2026-11-13-hierarchy-01/observations.md).
Visual guide: `docs/ui/drafts/hierarchy-preview.html` (Overview and Talents).
It is a proposal illustrating hierarchy, not pixel-perfect accepted artwork or
proof of EUI capabilities. Preserve live dimensions/anchors over mockup geometry.
The mockup's inert Save/Load controls and decorative scrollbar are not behavior
requirements. Do not infer hero trees from its illustrative build names.

## Required scope

### Typography and color roles

- Prominent off-white category title, character identity and category/build names.
- Light neutral gray for counts, selected class/spec and normal descriptions.
- Muted but readable gray, ordinary weight for source labels, dates and guidance.
- User EUI accent for selected navigation/spec markers and primary action.
- Green for verified availability where meaningful; amber for skips/actionable
  conditions; red for actual failures. Routine “Already present”, source identity
  and disabled states remain neutral. Retain text equivalents for status colors.
- Implement semantic text roles that survive optional skin application, lazy
  creation, theme updates and recycled rows. Inspect current `skin.Font` calls:
  they must not flatten the intended hierarchy after roles have been assigned.
  Exact shades/sizes are implementation choices subject to capture review.

### Overview

Keep four navigable rows and real saved-category count including saved-empty.
Make category name the leading text; count/snapshot state secondary. Keep each
category's own source and saved time as quieter supporting information. Label
the date's meaning (“Saved …”), preserve unknown values honestly, and retain
the full date/year rather than copying the mockup's abbreviated Overview date.
Use one consistently trailing chevron per row, not attached to the count.
Remove the generic bottom helper that says “below”; row navigation remains
apparent. Keep no Save/Load on Overview.

### Talents

Build name leads the row; compact neutral status is a distinct right-hand field.
Use “Already present” / “Available to import” (natural French equivalents).
State the existing-name policy once in the effect guidance rather than on
every row. Derive a useful saved/present/missing summary from the same inspected
builds. For the captured all-present state show the meaning of “5 saved loadouts
· All already on this character”; handle mixed, all-missing, saved-empty and
inactive-spec states honestly. On inactive specs, do not claim current-character
presence/availability from another spec's config map.

Retain selection/export/individual loading and whole-row activation. Keep a
visible instruction for selecting a build to inspect/copy its export. Preserve
current Load behavior/enablement even when no names are missing; improve the
summary without inventing a new disabled state.

Separate persistent restore-effect guidance (imports missing names, no activation,
existing names preserved) from quieter prerequisites (resolve native draft,
close native talent window, spend available points). Actual blocking reasons
remain visible and readable. Do not hide prerequisites exclusively in tooltips
or confirmations. Do not add an inline pending/success layer.

### Destination and provenance

Keep the current destination in the sidebar: quiet section label, prominent
character name, supporting realm/class/spec and active-state indication.
In the existing source region, separate the source character identity from
the quieter explicitly labeled saved date. Preserve independent category
provenance, binding-set information and honest unknown values. Presentation
adapters may expose structured fields; do not parse localized combined strings.

### Scrollbar diagnosis and bounded integration fix

The Talents capture shows ornamental arrow/button art. The installed sibling
EllesmereUI public SKINNING_API.md describes S.ScrollBar as fading arrows/track
art and painting a thin white thumb strip. Ruilhenn already registers its
frame.ScrollBar with this primitive. Diagnose enablement, object shape and
lifecycle before claiming a cause. Fix Ruilhenn's public integration if possible;
retain wheel, thumb and visible control operation and usable standalone behavior.
Do not alter EUI or copy private skin internals. If the public interface cannot
produce the documented appearance for this widget, report the specific boundary
and leave it an explicit unresolved finding rather than improvising a wider rewrite.

## Optional: hero talent identification

Nice to have; must not block the required hierarchy pass. If read-only resolution
is reliable, show a secondary left-aligned “Hero talents: Lightsmith” line under
the build name, with availability still at the right. No extra badge/color or
Overview field. Use localized game names and English/French catalog labels.

Derive the selection from the saved export, never from free-form build names or
the destination's active hero choice. Verify the relevant Retail API contracts
and metadata access. The existing decoder handles SubTreeSelection, but needs
valid config/tree context; do not assume inactive-spec decoding is available.
Distinguish known absent selection from unknown metadata, preserve old saves,
and handle invalid/outdated exports without misleading errors from mere browsing.
No activation, import, temporary config or SavedVariables migration for preview.
If these conditions require broader changes, defer this optional item and explain
why in response.md. Keep normal export inspection usable.

## Files and exclusions

Expected: TemplateBrowser.lua, presentation fields in TemplateStore.lua,
English/French catalogs, relevant meaningful tests, implementation evidence in
TEMPLATE-BROWSER.md and developer-owned response.md here. A small read-only
helper for optional hero resolution is allowed only if justified.

No manager restore rewrite, storage migration, new preference, named whole
profiles, automatic spec switching/loading, Utilities destination or general
Talents master/detail redesign. Other categories must retain existing behavior.
No edits to EUI, RETAIL-API-REVIEW.md, request.md, review.md or design artwork.
Do not commit, push, launch other agents or automatically notify another session.

## Observable acceptance

1. Both supplied views visibly distinguish names, supporting status and quieter
   provenance; text remains readable. Main geometry/navigation is retained.
2. Counts, presence summaries and per-category source/date are truthful across
   mixed/missing/empty/inactive states; preview never writes game state.
3. Accent and semantic status colors follow the accepted roles through late/lazy
   EUI styling, theme changes and row reuse; standalone remains usable.
4. Talents selection/export, confirmations, combat/spec/stale guards and all
   existing manager behavior remain intact. Refresh preview copy remains exact.
5. English/French long text and unknown/long character names fit without overlap;
   minor row-height/wrapping adjustments are allowed. Content scrolls as needed.
6. Scrollbar styling matches the public API's intended treatment or the concrete
   unresolved boundary is documented; actual scroll operation is preserved.
7. Optional hero names, if included, describe the saved export correctly and
   show honest unavailable/absent states without side effects. Deferral is allowed.

## Validation, dependencies and response

Run stock Lua 5.1 `tests/run.lua` and `python tools/package_release.py --check`.
Reuse locale parity coverage. Add meaningful state/presentation-data tests for
new summaries and optional metadata, not pixel-coordinate assertions. A missing
Lua executable previously prevented the last task's suite; report actual tool
availability/results, not historical totals as a new pass.

Request in-game Overview/Talents captures with comparable data, locale, UI scale
and skin/theme context. Exercise mixed/all-present/missing talent states,
inactive/combat views, selection/export, wheel/thumb scrolling, lazy/theme
styling and standalone. Review keyboard/controller-cursor reachability and focus
without new input capture or bindings. Mark unperformed checks NOT RUN; fixtures
do not verify rendering, taint or client writes. No destructive setup is needed
just to produce screenshots.

No product question blocks the required pass. Scrollbar root cause, exact font
fit and optional hero metadata availability remain technical/evidence questions.
Write response.md with changed files, chosen text roles/copy, scrollbar diagnosis,
optional feature disposition, commands/results and remaining captures needed.
User relays the response to the design session for review.
