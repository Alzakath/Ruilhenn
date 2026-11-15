# Implementation capture review

User identifies this batch as the implementation of `2026-11-13-hierarchy-01`.
Originals retained unchanged in the parent feedback directory:

| File | View |
| --- | --- |
| [233754](../Screenshot%202026-11-13%20233754.png) | Overview |
| [233806](../Screenshot%202026-11-13%20233806.png) | Talents, all present |
| [233814](../Screenshot%202026-11-13%20233814.png) | Action bars |
| [233822](../Screenshot%202026-11-13%20233822.png) | Key bindings |
| [233833](../Screenshot%202026-11-13%20233833.png) | Click casting, upper rows |
| [233843](../Screenshot%202026-11-13%20233843.png) | Click casting, lower scroll position |

All show English, Protection selected/active and Gravarn as destination.
Exact client build, EUI skin enablement/theme/accent, UI scale and capture
revision are unknown. Current code was reviewed in the uncommitted worktree;
no exact per-task before/after Git diff exists for the untracked browser file.

## Resolved or improved in these states

- Destination name, category/build names and source identity now have stronger
  prominence than supporting dates and instructions.
- Overview counts are aligned to the right with separate trailing chevrons;
  source and full saved timestamp remain independent per category.
- Talents accurately displays the all-present summary and short neutral row
  statuses. Effect, prerequisites and selection hint are separately readable.
- Source panel explicitly identifies source and saved date. Layout/Refresh
  preview copy remains intact in these captures.
- Click casting retains green/amber text equivalents and a 9 available / 1
  skipped summary. These are preview observations, not verified restore outcomes.
- Deferral of hero talent names is allowed by the request and is not a defect.

## Remaining findings

### R01 — High: Click casting action-column alignment is inconsistent

**Observed:** 233833 shows Target unit, Word of Glory, Lay on Hands and Open
unit menu near the right side of the action column, detached from their icons.
Holy Bulwark and subsequent actions start directly after their icons. The lower
capture confirms a second group of normally left-aligned names. Status alignment
also varies between earlier and later rows.

**Code evidence:** Overview sets reused `control.action:SetJustifyH("RIGHT")`.
Talents sets `control.status:SetJustifyH("RIGHT")`. The clicks branch resets
anchors and sizes but not horizontal justification. The first four reused
Overview rows and first five Talents rows can therefore carry different text
alignment than newly created rows. This supports an inherited-presentation
diagnosis, though the exact navigation sequence was not supplied.

**Required correction:** reset alignment explicitly for every rendered role.
Click action names must all start next to their icons; availability must use a
consistent alignment matching its header. Verify Overview → Clicks and Overview
→ Talents → Clicks, scroll down/up, and return to Overview/Talents. Add a meaningful
row-reuse regression assertion for justification, not just text/color/icon reset.
This is preservation of the existing aligned click table, not a new redesign.

### R02 — Medium: Scrollbar appearance remains unresolved

**Observed:** Talents, bars, bindings and clicks still show ornamental native
arrow/button art; the lower click capture shows the thumb at a different position.
It does not show the intended flat strip treatment described by the public API.

Removing a forced Hide and checking overflow did not establish skin fidelity.
Do not equate the visibility fix with resolution of the artwork finding. Confirm
whether Ruilhenn third-party skinning is enabled in the user's EUI configuration;
then investigate public primitive execution/widget shape/lifecycle. Keep EUI
internals untouched. Wheel/thumb operation is not verified by static captures.

### R03 — Low: Overview helper retained despite requested removal

233754 still shows “Choose a category to inspect its saved configuration.”
The inaccurate “below” is corrected, but the request specified removing the
generic helper. Remove it for request fidelity, or explicitly propose retaining
it for user agreement; this is a minor discrepancy, not a functional blocker.

## Follow-up considerations outside this pass

Bindings display raw-looking uppercase identifiers such as MOVEFORWARD rather
than readable action labels. This is observed but a dedicated bindings
presentation remains deferred; do not silently expand this pass. Question-mark
icons for Target unit/Open unit menu suggest missing spell data even though
these are interactions; a later refinement could omit those placeholders or
use meaningful interaction icons.

Selected navigation/spec and primary actions appear white in this batch.
That is not proof of an accent-role failure: the configured accent may be white.
Confirm theme context before alleging a regression; a non-white-accent capture
would demonstrate whether roles follow the selected EUI accent.

## Verification boundary

### Subsequent enabled-configuration batch

Additional originals:
[Talents 235518](../Screenshot%202026-11-13%20235518.png),
[EUI settings 235535](../Screenshot%202026-11-13%20235535.png),
[Click casting 235606](../Screenshot%202026-11-13%20235606.png).

R01 now has visual confirmation: the upper click rows consistently place action
names immediately after icons and availability text under its header. This
resolves the previously visible alignment issue for the captured state.

The EUI configuration capture shows **Skin Third-Party Addons** and **Ruilhenn**
toggles in their enabled/right-hand position. Version v9.8.4 is visible. R02
can no longer be deferred solely because the configured enablement is unknown.
Talents and Click casting still visibly retain ornamental arrows and a native
thumb. The configuration snapshot does not itself prove a reload after changing
settings, skin callback receipt or invocation of the scrollbar primitive on the
displayed object. These are the remaining runtime diagnostic questions.

Next developer investigation: reconcile the enabled configuration with actual
callback/primitive execution for the displayed scrollbar and its lifecycle.
If runtime skin execution is confirmed, identify the public primitive/widget
boundary and report it without modifying EUI internals or assuming the requested
flat appearance is impossible. Any diagnostics should be targeted and removable;
no broader skin rewrite is authorized by these screenshots. Wheel/thumb input,
standalone styling and theme update behavior remain unverified.

R03 is statically resolved; this batch contains no fresh Overview capture, so
it adds no visual confirmation of helper removal. Overall task remains pending
R02 resolution or an explicitly accepted limitation; no final acceptance claimed.

Reviewer independently ran stock Lua 5.1.5 `lua tests/run.lua`: **169 passed,
0 failed**, and `python tools/package_release.py --check`: **PASS**, 28 files,
interface 120105, load order/case valid. These tests do not contradict the visible
row-alignment defect; their existing reset assertions do not cover that property.

Missing evidence: French/smaller scales, mixed/available/empty/inactive/combat
states, selected export, confirmations, theme changes, standalone comparison,
input/focus, taint and actual mutations. The two click scroll positions prove
different visible content, not the input method used or all scrolling operations.

Recommendation: **Changes requested**, principally R01; R02 needs confirmed skin
context and diagnosis, and R03 a small scope correction. No runtime implementation
or developer response edit was performed during review.
