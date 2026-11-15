# Review — 2026-11-13-hierarchy-01

Current disposition: **Accepted by the user**, 2026-11-14: “I consider dev ok.”
This closes the bounded hierarchy development task and supersedes earlier
pending dispositions below. Preserve their verification limits: acceptance does
not imply separately tested French, theme, standalone or input scenarios.
The user's subsequent accent/class-color/icon ideas are a separate design review,
not additional blockers for this task.

Latest follow-up, 2026-11-14: user clarified that temporary tracing was already
removed. Verified current code and updated response: verbose region/callback
logging and tracing-only machinery are absent; the enabled-only arrow-art
fallback and public skin application remain. The removal plan below is
superseded and requires no further developer action. Reviewer independently
reran **172 Lua tests: all pass**, and package validation **PASS**, 28 files.
No runtime or response file was edited by this review. Remaining input/theme/
standalone evidence gaps are unchanged; no new logging level is needed.

## Visual fix and diagnostic cleanup — 2026-11-14

User reports “Scroll skinning is now working” and supplied
[Action bars capture](../../feedback/2026-11-13-hierarchy-01/2026-11-14-scrollbar-working.png).
The screenshot was copied unchanged from the supplied temporary attachment to
durable feedback storage. It shows the Guardian Action bars list at a lower
scroll position, with the former decorative arrows absent and the thumb still
visible. Record **R02 visual result: USER-REPORTED PASS** for this setup. It does
not separately verify wheel/thumb/arrow interaction, theme changes, standalone
or French layouts. R01/R03 remain resolved; full task acceptance was not requested.

Read the updated response and inspected the targeted Ruilhenn-only fallback:
it fades arrow-button texture regions when enabled skinning is confirmed, without
replacing scripts or modifying EUI. The developer reports before/after texture
evidence identifying the previously unchanged art. Earlier investigation-next-step
paragraphs below are superseded by that investigation and the successful fix.

User reports R02 diagnostics are excessive even at debug level and requests
either development-only trace separation or their planned removal. Recommended
bounded closeout: **remove temporary R02 tracing**, rather than introduce a new
logging level for a resolved investigation. Remove region snapshots, verbose
callback/widget/primitive logs, tracing-only hooks/state and their dedicated
tests. Retain any helpers/state actually required by enabled-only arrow fading,
public skin integration, overflow control and meaningful behavior tests; distinguish
functional dependencies before deleting. Preserve ordinary actionable debug
logging elsewhere. Do not change the successful scrollbar visuals/behavior or
logging architecture. Developer should report cleanup and rerun Lua/package checks.
This is a cleanup plan for the existing task, not implementation performed here.

## Investigation review — 2026-11-14

Read the updated developer report and inspected the debug-gated trace and
regression coverage. The developer records a user-supplied runtime trace showing
enabled callback receipt before lazy creation, and the public primitive returning
after receiving the displayed native Slider. Accept these as reported runtime
evidence for that run, not proof of a visual styling pass. Raw trace lines were
not separately supplied to this UI session; their interpretation is recorded in
response.md. No response file was edited.

Callback absence, disabled skinning and wrong-widget registration are no longer
useful primary hypotheses for that run. A primitive returning without error does
not establish what textures it changed. The missing convenience fields and
`GetThumb` do not prove the Slider lacks a thumb: child fields and texture regions
are different evidence. The native region/texture ownership and before/after
state remain unidentified. Do not call the investigation a proven EUI bug or an
impossible public-API requirement yet.

Recommendation: retain R02 open as a bounded visual integration issue. Next
technical step is a targeted read-only inspection of the actual arrow-button and
Slider texture regions using verified native widget APIs, comparing visible
regions before/after public styling and after showing/scrolling. Use native
template evidence to distinguish unhandled artwork from later restoration.
Keep private EUI implementation untouched; choose a Ruilhenn-only visual fallback
only once this evidence supports it, and preserve native wheel/thumb operation.
This is continuation of the existing diagnosis, not authorization for a wider
scrolling rewrite. No new design decision is necessary to collect that evidence.

Reviewer independently reran checks on 2026-11-14: **171 Lua tests passed,
0 failed**; package validation **PASS**, 28 files/interface 120105. No fresh
visual correction or input-operation pass exists. R01 is visually resolved,
R03 statically resolved, hero identification legitimately deferred. Full task
acceptance remains pending R02 resolution or explicit acceptance of its limitation.

## Prior review chronology

Latest evidence: [enabled-configuration batch](../../feedback/2026-11-13-hierarchy-01/implementation-captures.md#subsequent-enabled-configuration-batch)
visually confirms R01 fixed in Click casting. EUI settings show global
third-party skinning and Ruilhenn enabled; ornamental scrollbar art remains in
Talents/Clicks. R02 now needs developer runtime diagnosis of callback/primitive
execution, rather than another request to check the configured toggle. Reload
timing and actual callback execution remain unverified. No further code change
is prescribed until that boundary is established. R03 remains statically resolved.

The next-step paragraph below predates this enabled-configuration evidence;
continue with targeted runtime diagnosis and wheel/thumb verification. No tests
were rerun for this screenshot-only review, and response.md was not edited.

R01 and R03 are resolved by static inspection and regression coverage. R02 is
an unresolved rendering/environment question, not a confirmed code defect.

The reset loop restores LEFT justification; click action/status explicitly use
LEFT while Overview/Talents retain their intended RIGHT fields. The new test
exercises reused/new rows through Overview → Talents → Clicks and Overview →
Clicks. Overview's helper is hidden/cleared and unused translations are removed.
Reviewer independently reran `lua tests/run.lua`: **170 passed, 0 failed**;
package validation: **PASS**, 28 files, interface 120105. Developer reports
`git diff --check` PASS. No runtime or developer response was edited in review.

Next: explicitly enable Ruilhenn's EUI third-party skinning, `/reload`, then
capture overflow scrollbar and click rows after Overview/Talents navigation.
Confirm wheel and thumb operation and supply skin/theme context. If decorative
art remains with the public skin active, diagnose that boundary. No speculative
skin fix is requested before this check. Other previously unverified states
remain unverified; optional hero identification remains deferred. No final
acceptance claimed.

## Earlier review (superseded for R01/R03)

Disposition was **Changes requested** after reviewing developer response, current
code and six user-supplied implementation captures. Detailed evidence and
corrections: [implementation capture review](../../feedback/2026-11-13-hierarchy-01/implementation-captures.md).

The hierarchy pass visibly improves Overview and all-present Talents. Optional
hero identification was legitimately deferred. However, reused click rows retain
right justification from Overview/Talents, producing visibly inconsistent action
and status columns (R01, high). Reset justification per role and cover the
navigation/reuse sequence. Ornamental scrollbar art persists (R02, medium);
confirm EUI enablement/theme before diagnosing further. The generic Overview
helper was retained contrary to the request (R03, low).

Reviewer reran stock Lua 5.1.5 suite: **169 passed, 0 failed**. Package check:
**PASS**, 28 files, interface 120105. Rendering evidence is English/current-spec
only; other states and input acceptance remain unverified as detailed in the
capture review. No runtime, catalog, test or developer response edits were made.

Next: relay R01–R03 to the developer for the bounded corrections/diagnosis, then
review fresh clicks and scrollbar evidence before recommending acceptance.
Feature status remains in TEMPLATE-BROWSER.md. No new implementation task was
created; findings attach to this existing request.
