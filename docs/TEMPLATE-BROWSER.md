# Shared template browser

UI specification entry point: [UI-SPEC.md](UI-SPEC.md). The local
[review workflow](ui/README.md) and [2026-11-13 baseline](ui/BASELINE-2026-11-13.md)
establish the separate design/developer handoff. The redesign below is already
implemented locally; screenshot review remains pending. No new implementation
task was created during workflow setup. Later restore evidence and test totals
remain owned by [RESTORE-FIXES.md](RESTORE-FIXES.md), rather than the older
slice-specific totals below.

For subsequent cross-character talent/bar runtime failures, manager fixes and
their latest check results, see [RESTORE-FIXES.md](RESTORE-FIXES.md).

## UI session checkpoint — 2026-11-13

### Development acceptance — 2026-11-15

User explicitly validated development. The release-cleanup task is
**Accepted**: [review](ui/tasks/2026-11-14-release-cleanup-01/review.md).
Cleanup report records 183 passing Lua tests, package/whitespace checks and a
verified 28-file local ZIP at that checkpoint, plus user-reported in-game smoke
PASS. The later workflow archive audit reduced the game ZIP to 26 runtime files.
UI session read the report without rerunning tests for this documentation-only
update.
Earlier investigation, correction and testing instructions below are historical
and do not reopen accepted work.

Current state: development/cleanup accepted and ready for Git/release handoff.
No new UI development is active. Release version 0.5.0 is selected and the
runtime-only archive has been audited; reconcile the broad shared worktree for
the intended commit/release and preserve exclusions/unrelated work, especially
RETAIL-API-REVIEW.md.
B01/B02 remain previously reported code-open observations rather than silently
fixed findings; carry their disposition into release notes/handoff. No commit,
push, tag or release publication was performed in this acceptance update.

### Current resumption checkpoint — 2026-11-14

Latest user decision: bindings investigation/fix **accepted**, user reports it
works and considers the addon ready for commit/push/release after cleanup. The
context-aware copy handles identical keys across contexts. Release cleanup is
now complete locally: temporary preflight stage tracing, command/event/table
dumps and other noisy success checkpoints were removed; useful error/status and
talent rejection/cleanup diagnostics remain. See the
[release-cleanup report](ui/tasks/2026-11-14-release-cleanup-01/response.md).
Lua validation passes (183 tests), and the package check/build verifies 26
runtime files. `dist/Ruilhenn-retail-12.1.5.zip` has no documentation, tests or
development tools. User selected **0.5.0** for the release because the UI is an
important new feature; TOC and changelog carry 0.5.0 and the ZIP TOC was verified
at that version. No commit, push, tag or publication was made. B01/B02 remain
reported as code-open rather than silently resolved. Older investigation and testing-pending notes below are
historical and do not reopen the accepted Copy fix. User reports the in-game
cleanup smoke check passed with debug off/on, browser navigation/refresh and
Copy account bindings unaffected.

Current follow-up: user explicitly requested Lua investigation of Copy failure
and prerequisite clarity. [Investigation instructions](ui/tasks/2026-11-14-bindings-scope-01/investigation.md)
are **Ready for investigation**, attached to the existing bindings task. The
user's concern is uncertainty about required setup; do not treat the generic
read error as evidence of an unmet prerequisite. Next: relay these instructions,
then review response.md for confirmed conditions/cause and a bounded correction
proposal before further mutation tests. No runtime change was made here.

Latest user runtime result: **Copy account bindings preparation fails** with
the binding-set read/verify notice before confirmation. See
[runtime finding](ui/tasks/2026-11-14-bindings-scope-01/review.md#runtime-failure-copy-baseline-read--2026-11-14).
Next: Lua developer identifies the exact capture/load stage and native return/
context assumptions with minimal diagnostics, preserves account/live state,
and supplies a bounded correction/retest. Repeated mutation tests are paused.
Quick Keybind coexistence is not testable in the user's normal workflow because
it captures chat and closes Ruilhenn; no forced co-visibility is requested.

Subsequent independent bindings review: **Changes requested before acceptance**.
[Review](ui/tasks/2026-11-14-bindings-scope-01/review.md#independent-review--2026-11-14)
identifies optional-editor iteration skipping QuickKeybindFrame when the first
global is nil (B01), and missing source identity in import confirmation (B02).
Reviewer independently reran **181 tests, all pass**, and package validation
**PASS**, 28 files. Existing coverage misses the optional-frame gap. Next:
relay bounded findings, then perform the guard-first
[in-game sequence](ui/tasks/2026-11-14-bindings-scope-01/in-game-checks.md).
No runtime changes were made in this review; native isolation is still unverified.
The previous checkpoint below predates this completed independent review.

Active task: [2026-11-14-bindings-scope-01](ui/tasks/2026-11-14-bindings-scope-01/request.md).
The developer response arrived before this checkpoint and was read for status:
**implemented locally; awaiting independent review and in-game verification**.
Do not restart implementation or treat the earlier Ready handoff as unfinished
development without reconciling that response and live code.

Completed design work: established UI-SPEC/role/workflow and screenshot records;
Refresh preview and hierarchy tasks were accepted by the user. Hierarchy fixes
include row-alignment reset, helper removal, working user-confirmed scrollbar
visuals and completed temporary diagnostic removal. Identity colors/icons were
implemented; user is happy with colors, but house/tree/mouse icon clarity remains
an open refinement proposal, not an authorized corrective task or full identity
acceptance. Preserve the accepted EUI accent policy, destination class color and
55% class / 45% neutral source-color implementation described in its response.

Accepted binding decisions: browser imports target only the current character;
copy-account replaces its own set with the account baseline, retains character
mode and never writes account bindings. No account-import option, persistent undo
history or legacy slash scope change is in the task. The new response reports
manager-owned import/copy, account-baseline fingerprints, native-editor/context
guards and temporary load/capture/restore inspection. These are developer claims
pending independent review, not actual-client account-isolation evidence.

Verification ledger: this UI session independently confirmed 172 Lua tests and
28-file package validation after hierarchy cleanup. Identity developer reported
176 tests/package pass; the new bindings response reports **181 tests, 0 failures**,
package validation and diff whitespace check PASS. These newer checks were not
rerun by the UI agent for this checkpoint. No new game check was performed.
Historical screenshots/user passes remain limited to their recorded views.

Outstanding: review bindings implementation/fixtures against the request,
especially two independent sets, active-mode restoration, unsaved live/editor
state, read/restore failure handling, stale account baseline and honest success
verification. Check that transient native LoadBindings inspection satisfies
the request's preview/state-preservation guarantees in practice; do not assume
mocked restoration proves native behavior. Inspect new button/confirmation fit
and distinguish template merge from exact account-copy replacement. Real-client
account preservation, reset/import results, reload persistence, French/small-scale
fit and input access remain unverified. No additional product choice blocks
that review. Icons remain a separate discussion; optional hero names are deferred.

Revision: HEAD still `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`; extensive modified
and untracked runtime, catalogs, tests, packaging and docs remain in the shared
worktree. Status was inspected; no exact checkpoint diff proves contents unchanged.
RETAIL-API-REVIEW.md is untouched. No runtime/test/catalog/response edits, commit,
push or automatic session communication occurred in this checkpoint.

Next action: resume through UI-AGENT.md, inspect current Git state, read the
bindings request/response/review and reconcile newer developer changes. Perform
the independent review, record findings in review.md, then request/inspect the
bounded in-game verification/captures needed for acceptance. Keep identity icon
proposals separate. Current task review is not yet completed.

### Selection and class identity review — 2026-11-14

Implementation feedback: user supplied Overview/Clicks captures (021223/021208)
and is happy with color choices; icon clarity is still under discussion.
See [review observations](ui/feedback/2026-11-14-identity-01/observations.md#implementation-captures-and-user-feedback).
No final acceptance of the identity task is inferred; proposed refinement focuses
on house/tree/mouse silhouettes, not a new color direction.

#### Key-binding scope question — 2026-11-14

User questioned whether imports are too risky and whether they affect account
or character bindings. Static inspection: Save captures GetCurrentBindingSet;
scoped browser snapshots preserve bindingSet. BindingsManager:Load applies each
saved key with SetBinding then calls SaveBindings(profile.bindingSet or current).
Therefore an account-source snapshot targets the account set (1), and a
character-source snapshot targets the character set (2); class/spec catalog
ownership does not isolate account-wide effects. Existing UI shows the target
set and confirmation warning, but does not force character-only import or offer
a target choice. Assigned keys can displace current assignments; no up-front
clear-all occurs. No automatic pre-import undo snapshot is present in this path.
These are code observations, not a new runtime mutation test.

Accepted user direction: browser binding imports target the destination
character's own set irrespective of source save scope. The source's recorded
scope is provenance, not authority to overwrite account bindings. There is no
account-wide import option. Legacy slash behavior retains its existing scope.

User accepted the recommendation for the reset action: **copy account bindings
into the current character's own binding set**, replacing that character set and
leaving it active/character-specific. This is a one-time copy, not a switch to
shared account mode; subsequent character edits stay isolated. Account bindings
must not be modified. The baseline is the actual account set, not factory
defaults or the selected template. The copy must replace rather than merge:
character-only assignments absent from the account baseline do not survive.

Implementation status: [2026-11-14-bindings-scope-01](ui/tasks/2026-11-14-bindings-scope-01/request.md)
now routes browser imports to the character set and adds the confirmed exact
account-copy utility. The implementation reads saved sets with `LoadBindings`,
captures through `GetBinding`, restores the prior live map without saving, and
only persists destination changes with `SaveBindings(2)`. Independent-set
fixtures and current check results are recorded in the
[implementation report](ui/tasks/2026-11-14-bindings-scope-01/response.md).
The request's acceptance constraints remain authoritative; live client account
isolation, key-binding editor detection, reload persistence and
English/French presentation remain to be verified in game. The user's safe
preflight retest identified a duplicate key across live binding rows before
account loading. The accepted bounded correction now reads and applies the
copy path by `(binding context, key)`, based on Retail's context lookup and
context-aware `SetBinding` use; same-context collisions and context API errors
still fail closed. Template imports, their saved data and legacy slash behavior
remain unchanged. The latest local checks and source evidence are in the
[bindings implementation report](ui/tasks/2026-11-14-bindings-scope-01/response.md).
Native context-aware copy, account isolation and reload persistence still need
controlled in-game verification. No automatic undo snapshot or account-wide
import option is included.

Active design review: `2026-11-14-identity-01`, following the user's acceptance
of hierarchy development. The new EUI/Ruilhenn comparison motivates proposals
for live-accent selection, restrained class-colored destination identity and
category icons. [Evidence and recommendations](ui/feedback/2026-11-14-identity-01/observations.md)
distinguish EUI branding green from the configured accent and explain icon scope.
User accepted the recommendations on 2026-11-14, including the subsequent
source-name treatment. The bounded
[2026-11-14-identity-01 request](ui/tasks/2026-11-14-identity-01/request.md) is
implemented locally; visual review is pending. It covers class-colored
destination/source identity and category icons with existing live-accent
behavior. The Lua implementation report and checks are recorded in
[the task response](ui/tasks/2026-11-14-identity-01/response.md). Exact assets
and blend remain subject to in-game readability and lifecycle review.

Accepted accent decision, 2026-11-14: use EUI's configured live UI accent for
Ruilhenn selection. Users wanting green or another color choose it in EUI's
configuration. Do not hardcode EUI branding green, introduce a separate Ruilhenn
accent preference or override a configured white accent. Preserve the usable
standalone fallback when EUI is absent/disabled.

Accepted class identity: use normal class color for the current character's name
and class word. Realm, specialization and active-state text stay neutral. Source
character names use class color blended toward neutral gray at full opacity,
consistently in Overview and category headers. Source realm, labels and saved
date stay muted neutral. This supersedes the earlier source-neutral-only advice.
Avoid transparency or simple darkening, which can reduce readability on varied
backgrounds. Exact blend strength is an implementation choice subject to capture
review across classes, especially darker colors. Unknown/unresolvable class data
uses neutral fallback, never a guessed identity.

Accepted category icons: small consistent monochrome symbols for Overview
(house), Talents (tree), Action bars (slot grid), Key bindings (keyboard) and
Click casting (mouse). Align icon+label groups to a common left text start.
Selected icon/label and selection marker use the live EUI accent; unselected
controls remain neutral. Icons supplement labels and share the button's hit/focus
target. Use verified native or packaged assets, not generated reference art or
private EUI artwork. No Utilities destination or specialization icons in this
pass. Keep non-color selection markers. A filled selected-row treatment remains
an exploration rather than a newly accepted requirement.

Implementation evidence, 2026-11-14: category symbols are assembled from
runtime rotated solid textures using Blizzard's `Interface\Buttons\WHITE8X8`
texture; no new packaged assets were added. Destination name/class use
`C_ClassColor.GetClassColor`; source names use a 55% class-color / 45% neutral
gray blend with full-opacity color markup. Source name/realm separation accepts
only the stored ` — ` delimiter, and unparsed legacy values remain neutral.
Regression and TOC-driven package checks pass. English/French label fit,
rendered class contrast, EUI appearance and actual-client input remain
unverified; see the task response for capture scenarios.

### Overview and Talents hierarchy review — 2026-11-13

Final task disposition: **Accepted by the user** on 2026-11-14 (“I consider dev
ok”). Later pending-review statements below are historical. The prior 172-test
and package passes, user-reported scrollbar visual pass and separately unverified
scenarios retain their exact scope. New accent/class-color/icon proposals are
tracked separately above; they do not reopen this task.

Cleanup follow-up: user clarified temporary tracing was already removed.
Reviewer verified current code/report and independently reran **172 Lua tests
(all pass)** plus package validation **PASS**, 28 files. Diagnostic cleanup is
complete; no further cleanup request or new trace level is needed. Earlier
removal recommendations below are historical. Remaining scroll interaction,
theme and standalone verification gaps are unchanged.

Latest update, 2026-11-14: user confirmed scrollbar skinning now works and
supplied an Action bars capture with decorative arrows absent and thumb visible.
R02 visual result is **USER-REPORTED PASS**; interaction/theme/standalone checks
remain separately unverified. See [review closeout](ui/tasks/2026-11-13-hierarchy-01/review.md#visual-fix-and-diagnostic-cleanup--2026-11-14).
At the user's request, temporary R02 tracing, hooks, trace-only state and
trace-specific assertions have now been removed while preserving the working
fallback and ordinary debugging. Lua and package checks pass; no new logging
level was introduced. Prior R02 diagnosis below is retained as historical
evidence; full task acceptance was not requested.

Active UI design review: `2026-11-13-hierarchy-01`.
The user supplied Overview and Talents captures and reported that spacing and
positioning seem satisfactory, while information lacks purpose, hierarchy and
contrast. The [evidence and findings](ui/feedback/2026-11-13-hierarchy-01/observations.md)
record observed issues separately from proposals and unverified behavior.
Preserve the existing layout as the working baseline. Proposed changes focus
on text roles, prominence, shorter routine statuses, useful talent summaries
and quieter provenance. The user's subsequent request for development
instructions authorizes the bounded presentation pass in
[2026-11-13-hierarchy-01/request.md](ui/tasks/2026-11-13-hierarchy-01/request.md),
implemented locally; current review disposition is **Code corrections reviewed;
in-game confirmation pending**.
The request specifies the scope and exclusions; hero identification was
deferred as optional. The implementation report is in
[response.md](ui/tasks/2026-11-13-hierarchy-01/response.md). Six new implementation
captures were reviewed: [findings and evidence](ui/feedback/2026-11-13-hierarchy-01/implementation-captures.md).
R01 and R03 are corrected locally: reused rows reset text justification before
category rendering, and Overview no longer shows the generic helper. New
captures confirm global third-party skinning and Ruilhenn's toggle are enabled.
The user's subsequent runtime trace confirms the enabled callback ran before
the content scrollbar was created; the public `S.ScrollBar` primitive then
returned after receiving the exact displayed `Slider` object. The slider trace
lists two arrow-button children but no conventional track/thumb fields. The
public API documents intended treatment but neither its accepted native region
shape nor per-region results. Thus callback delivery, registration timing and
widget identity are ruled out. The follow-up region trace showed visible arrow
texture IDs 130854 and 130856 kept alpha 1 and white vertex color before and
after `S.ScrollBar`; the primitive leaves this template's child-button arrow
artwork untouched. Ruilhenn now fades only textures belonging to the named
up/down arrow buttons, and only when EUI skinning reports enabled. The button
frames/scripts and slider thumb remain intact; standalone mode is unchanged.
The user confirms the latest modification worked for skinning. Temporary
region tracing was removed after diagnosis. Scroll operation, theme-change
behavior and standalone appearance remain unverified.
Hero names remain deferred as allowed. Lua 5.1.5 now passes all 172 tests and
the 28-file package check passes; both were independently rerun by the reviewer.
Static review confirms R01/R03 corrected, and click alignment has visual
confirmation. On 2026-11-14 the UI reviewer read the investigation report and
independently reran the 171-test suite and package validation (both pass).
R02's visual styling is confirmed by the user on the latest modification.
Next: verify wheel, thumb and arrow-button scrolling, EUI theme changes and
standalone appearance. Missing convenience fields do not prove absence of
Slider texture regions. See
[investigation review](ui/tasks/2026-11-13-hierarchy-01/review.md#investigation-review--2026-11-14).
French fit, actual scroll input and
restoration acceptance also remain unverified.

Latest hierarchy evidence update: [enabled-configuration captures](ui/feedback/2026-11-13-hierarchy-01/implementation-captures.md#subsequent-enabled-configuration-batch)
visually confirm Ruilhenn and global EUI skin toggles enabled while scrollbar
art persisted. User-supplied runtime traces confirmed the enabled callback,
correct displayed Slider, and unchanged arrow texture state across the public
primitive call. Ruilhenn's enabled-only arrow-art fallback was confirmed by the
user to work. Temporary diagnostics were subsequently removed at the user's
request; focused enabled/disabled behavior tests and the public skin integration
remain. Full task acceptance and scroll-input/standalone checks remain pending.
No EUI internals were changed. This note belongs to the hierarchy task; optional
hero status below is unchanged.

#### Optional hero talent identification

Priority: **Nice to have**, explicitly requested by the user. It must not block
the core hierarchy/color pass. Identify the hero talent tree associated with
each saved talent build from that build, never its free-form name or the
destination's active hero talents.

Recommended placement (proposal): two-line identity block at the left of each
Talents row, with the prominent build name above a smaller, regular-weight,
light-gray “Hero talents: Lightsmith” line. Keep the neutral import status
(“Already present” / “Available to import”) right-aligned as a separate field.
This keeps hero identity beside the build it describes without mixing it with
availability, source metadata or navigation. Preserve the whole-row selection
target. Allow row height/wrapping for French; do not squeeze metadata into the
name or reduce text below readable size. No hero-specific badge/color or extra
Overview information is needed. Exact copy/placement remains a proposal.

If metadata cannot be resolved, use a neutral unavailable label; distinguish a
verified absence of hero selection from an unknown result. Never guess from
the saved build's name, including the illustrative names used in the mockup.
Technical feasibility is supported by the existing export decoder's
SubTreeSelection handling and packaged Retail 12.1.5.70783 source declarations
(`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`): TraitEntryInfo.subTreeID and
C_Traits.GetSubTreeInfo(configID, subTreeID) returning a nullable name. Upstream
fetch was unavailable in this review; this is pinned local source evidence,
not runtime verification. Current browser does not expose this information.
Before implementation, verify read-only resolution, legacy/invalid exports,
no selected hero tree, unavailable metadata and inactive-spec browsing. Missing
metadata must never produce a guessed tree. The Ready hierarchy request permits
this as an optional read-only addition, with explicit deferral if unreliable.

#### Accepted color policy

User accepted these color roles on 2026-11-13. Off-white leads category titles,
character identity and category/build names; light neutral gray supports counts,
descriptions and selected class/spec; muted readable gray supports source labels,
saved dates and guidance. The user's EUI accent marks selected navigation/spec
and the primary action. Green indicates verified availability where meaningful
(e.g. learned click-casting spells); amber indicates skipped entries or a
condition requiring attention; red indicates actual failures. Disabled controls
remain neutral. Every semantic color has a text equivalent.

“Already present” and source identity remain neutral, not success/accent states.
Color reinforces typography and grouping. The developer may choose compatible
exact shades through the public EUI interface, preserving readable contrast and
the standalone fallback; shade/rendering acceptance requires captures. This
approval originally covered color roles; the subsequent Ready request bounds
the additional presentation/copy work now authorized for implementation.

Scrollbar follow-up: the Talents capture visibly retains ornamental arrow/button
art unlike the expected flat treatment. Installed EUI public `SKINNING_API.md`
documents `S.ScrollBar` as fading arrows/track art and painting a thin white
thumb strip; the supplied runtime trace confirms Ruilhenn passes the displayed
`Slider` to that primitive and it returns with `S.IsEnabled=true`.
The implementation previously hid the bar directly after registering it for
public styling. That explicit hide was removed; Ruilhenn now shows the bar only
when the content exceeds the viewport and hides it when rows fit. The browser
continues to register the native scroll-frame bar with the public `ScrollBar`
primitive. This fixes the local visibility conflict while retaining the native
wheel/track/thumb controls. The supplied runtime trace lists the two
arrow-button children, but the public API does not document accepted native
region shapes or expose per-region style results. The trace rules out a missed
callback or wrong displayed object. Region snapshots then showed visible arrow
texture IDs 130854 and 130856 kept their IDs, alpha 1 and white vertex color
after the public primitive returned. This localizes the issue to the primitive
not changing these child-button textures on the native Slider template.
Ruilhenn now sets alpha to zero on textures belonging to the named up/down
Button children after EUI styling, only when EUI reports enabled. It does not
hide or disable the buttons, replace their scripts, or alter the named thumb
texture. No EUI internals were changed. The user confirms visual skinning works
with the latest modification; thumb/arrow input, wheel scrolling, theme refresh
and standalone mode were not part of that confirmation. Temporary verbose
tracing and its hook/state/tests have since been removed; behavioral fallback
coverage remains.

The hierarchy pass now assigns primary, secondary, supporting, status and EUI
accent roles; separates character and source/date fields; puts counts/state
secondarily in Overview with a trailing chevron; and gives Talents concise
present/available row states plus derived all-present/mixed/all-available
summaries. Existing-name policy, prerequisites and selection/export guidance
are separate lines. Inactive specialization rows remain unchecked and do not
claim destination availability. Existing shell dimensions, manager dispatch
and accepted Refresh preview copy remain unchanged. Optional hero-tree
identification was deferred because safe read-only resolution across inactive,
legacy and invalid exports was not required for this presentation pass.

Automated presentation-data and scrollbar-visibility coverage was added. The
developer later installed stock Lua 5.1.5; `lua tests/run.lua` passes all 172
tests, including hierarchy and EUI-only arrow-fallback cases.
The Retail package check and
`git diff --check` pass. Actual-client fit, scrollbar styling/operation and
input review remain pending; see the implementation report for the verification
matrix.

Most recent bounded UI task (accepted):
[2026-11-13-refresh-preview-01](ui/tasks/2026-11-13-refresh-preview-01/request.md).
The baseline checkpoint below predates that task; see its current feature record.

### Refresh preview label — 2026-11-13

Accepted by explicit user request: rename the browser button to **Refresh
preview** (English) / **Actualiser l’aperçu** (French), preserving behavior.
This supersedes older Refresh wording in the handoff for this control only.
Task status: **Accepted** by explicit user instruction on 2026-11-13 after
in-game testing. User report: “Tested in game: record
2026-11-13-refresh-preview-01 as accepted”. No further implementation or review
action is required for this task. Test locale, skin, scale and individual
scenarios were not specified; no separate matrix passes are inferred.
The design session inspected `self.reload`, its 116 × 34 dimensions, both footer
positions and the existing `UI_REFRESH` catalog values. The longer labels have
an unverified fit risk; minimal button fit adjustment is within scope.

Scope, observable localization/fit acceptance and required checks are in the
[request](ui/tasks/2026-11-13-refresh-preview-01/request.md).
[Review](ui/tasks/2026-11-13-refresh-preview-01/review.md) completed static
inspection with no blocking code finding and records the subsequent user
acceptance. The implementation report is in
[response.md](ui/tasks/2026-11-13-refresh-preview-01/response.md). The existing
button uses the exact English/French labels and is 152 × 34 logical pixels;
its callback, visibility, enabled state and two existing footer positions are
unchanged. Automated checks and static spacing review are recorded in the
response. User-reported in-game testing supports acceptance of this task;
small-scale, locale and optional-EUI coverage were not separately described.

Reviewer independently reran the package check: PASS, 28 files, interface
120105. Stock Lua executable names are absent from PATH; the developer's
required Lua suite remains NOT RUN for this task. This limitation is retained
without overriding the user's acceptance. Next UI work returns to the broader
browser screenshot review when evidence is supplied; the overall redesign's
acceptance is not implied by acceptance of this label change.

### Earlier baseline checkpoint

Active work: establish the separate UI design/review session and prepare the
first review of the locally implemented redesign. This is a design review,
not a new Lua implementation task. Role/resumption instructions live in
[UI-AGENT.md](ui/UI-AGENT.md).

Completed: inspected repository instructions, accepted PNG, relevant feature
documents and current browser/store code; reconciled the archive handoff with
the implemented shared shell, Overview, structured Click casting and empty
states, plus later restore safeguards. Created [UI-SPEC.md](UI-SPEC.md),
the [workflow](ui/README.md), reference/feedback/task directory guides and
[baseline review](ui/BASELINE-2026-11-13.md). Marked the handoff's first task
historical and preserved the original PNG and all pre-existing work. Added the
durable UI agent guide on checkpoint request. No speculative implementation
request, developer response or automatic session communication was created.

Checkpoint refresh after the subsequent “presets” message: no additional design
or implementation work was performed. The assistant asked whether this meant
shared configuration templates or a preset resumption prompt; the user has not
clarified. This word alone establishes no accepted feature requirement or task.

Revision context: HEAD `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880` at baseline;
the checkpoint status inspection still shows substantial local/untracked UI,
manager, localization, test and documentation work described in the baseline.
Status inspection does not establish an unchanged content snapshot. Reconcile
any intervening Lua-session changes on resumption before proposing corrections.

Verification: this UI session ran `python tools/package_release.py --check`:
PASS, 28 files, interface 120105, load order/case valid. The docs directory is
excluded by existing `.pkgmeta` and the local TOC-driven packaging allowlist.
No fresh Lua suite was run for these documentation-only changes. Earlier
slice/restore test totals remain historical evidence in their respective
records. In-game rendering, localized fit, input access and redesigned
interactions have NOT RUN in this UI session; no current captures were supplied.
At this refresh, Git HEAD and status were inspected again: HEAD remains the
revision above and the working tree remains populated with uncommitted work.
No new runtime, Lua-suite or packaging verification was run for this refresh.

Outstanding questions are evidence questions: how the implementation actually
renders with the user's EUI/theme and scale; whether long French copy,
metadata, click columns and confirmations fit; whether overflow and disabled
reasons remain clear; and whether keyboard/controller-cursor interactions work.
These are unverified risks, not observed defects or accepted correction tasks.
Restore-operation questions remain in RESTORE-FIXES.md rather than this review.
Also unresolved: the intended meaning and scope of “presets”. Clarify it if the
user resumes that topic before creating a design or implementation request.

Next action: read UI-AGENT.md and reconcile the latest developer changes. If
the user continues the “presets” topic, clarify its intended meaning first;
otherwise continue the pending screenshot review. Inspect the user's
first screenshot folder. Prioritize Overview with mixed saved/missing sources
and Click casting with available/skipped rows; extend to inactive spec, missing
Action bars, confirmations and French/standalone views as listed in the baseline.
Record actual feedback under `ui/feedback/<review-id>/`, propose bounded
corrections, and wait for scope agreement before marking any request Ready.
No commit or push was performed.

## Subsequent UI redesign handoff

`docs/Ruilhenn-UI-Handoff.md` (v2, 2026-11-13) defines the subsequent accepted
direction and AC01–AC13. The first redesign slice is the shared shell,
Overview, structured Click casting and missing/empty category presentation;
existing talent, bar and binding workflows remain functional. Deferred
proposals in that handoff are outside the slice. The accepted image is now
present at `docs/Ruilhenn click-casting UI mockups.png` (1536 × 1024) and was
visually inspected before implementing this slice. The written handoff takes
precedence over illustrative artwork, sample values and the Utilities entry.

### Visual implementation map (2026-11-13)

- Retain a 1040 × 680 logical window that scales down to fit the screen.
  A title-only drag region occupies the top 42 pixels; the current character,
  class/active spec and category controls occupy the 228-pixel left panel.
- Horizontal same-class spec choices sit above the content. The selected
  choice has an accent marker; the current active spec also has an explicit
  localized Active label. Selection and active state are separate.
- The main header leads with the category title and subordinate class/spec.
  A compact source/time panel is shown only for actual category snapshots.
- Overview uses four navigable rows with independent provenance and actual
  saved-state/content counts. Its summary counts saved categories, including
  saved empty snapshots; it has no Save/Load actions.
- Click casting uses 40-pixel rows with aligned input, action/icon and status
  fields. Actual spell textures or a question-mark fallback are used; no art
  is extracted from the reference image. Body text stays neutral; green/amber
  statuses retain text equivalents. Unresolved actions use readable labels.
- Existing-snapshot actions use secondary Save and Refresh on the left and
  an accent-labeled Load on the right. Missing compatible categories promote
  their Save action in the content. Saved-empty views retain true provenance
  and explicitly explain empty native click-profile replacement.
- Near-black/charcoal primitives provide the standalone fallback. EUI owns
  runtime shell/panel/button/font/scroll styling through its public API.
  Custom icon/selection regions exist before skin setup and are passed as
  public Button keepKeys so lazy creation and later theme updates retain them.
- Metadata, statuses, empty-state copy, buttons and table labels are localized
  in English/French with wrapped text. Exact sizes, contrast, clipping,
  controller cursor operation and actual EUI appearance remain game checks.

### Handoff acceptance and verification

| Criteria | Local implementation / evidence | Actual-client status |
| --- | --- | --- |
| AC01–AC02 | Horizontal filtered catalog preserved; Active label and non-color selection marker added; current destination stays visible | NOT RUN for redesigned layout |
| AC03–AC04 | Category-first header, actual snapshot-only metadata, independent Overview source/counts and navigation; saved-empty counts tested | NOT RUN |
| AC05–AC06 | Structured click input/action/icon/status fields, same-row summaries, missing-spell preview; tests prove no preview writes | NOT RUN |
| AC07 | Missing and saved-empty states, first-save wording and empty click replacement confirmation tested | NOT RUN |
| AC08–AC10 | Existing manager ownership/guards retained; inactive states neutral; confirmations bind to reviewed data; no fabricated result layer | Regression tests pass; redesigned interaction NOT RUN in game |
| AC11–AC12 | Locale parity, row/icon/status/export reset and lazy/late public skin registration tested; native scrollbar auto-hide enabled | French layout, overflow and theme rendering NOT RUN |
| AC13 | Full suite includes real selected-talent async flow and existing bars/bindings/click manager regressions | Existing runtime records remain scoped to earlier changes |

Validation for this slice: 138 stock Lua 5.1 tests pass. The TOC-driven
28-file artifact check passes. There is no connected game/computer-capture
tool in this session, so an actual implementation screenshot comparison
against the accepted PNG has NOT RUN. Do not treat the frame harness as
rendering, taint, controller or actual-client evidence.

Requested captures after `/reload` → `/ruil`: Overview with mixed saved/missing
categories; clicks with an unlearned spell; missing action bars; an inactive
saved spec; first-save and empty-click load confirmations; long French labels.
Repeat representative views with EUI skinning off, changed accent/theme,
overflow, lower resolution/UI scale, Escape, title dragging and controller
cursor. The handoff's inline result layer and other deferred redesigns were
not added. Implementation is local and uncommitted, awaiting this review.

Earlier implementation and validation records follow for historical context.

Target: Retail 12.1.5.70783 / interface 120105. Live source resolved again
2026-11-12 to `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`.
Base revision: `3e5dfaa`. No commit/push of this feature requested yet.

User decisions: mock-up first; shared templates by class/spec with independent
source characters (e.g. Guardian from A, Feral from B); EllesmereUI public
skinning API accepted. Design: `docs/UI-MOCKUP.html`, dark sidebar/content
window, template selection, category tabs, scrollable inspection, explicit
save/load and replacement confirmations. EUI uses its own runtime art/fonts;
no EUI assets or implementation are copied. Standalone fallback retained.

| ID | Acceptance | State |
| --- | --- | --- |
| REQ-TB-1 | Browse saved specializations of the current character’s class, including scoped legacy saves | Implemented; foreign classes excluded and same-class specs retained in tests |
| REQ-TB-2 | Record source character/realm/time per saved category; Guardian and Feral independent | Implemented; source isolation tests pass |
| REQ-TB-3 | Inspect talents, action slots, bindings and native click-casting entries | Implemented; talent availability/export and missing-spell inspection covered |
| REQ-TB-4 | Save/load selected category for current compatible class/spec with explicit confirmation and combat checks | Implemented; confirmation, stale data, combat/spec guards tested |
| REQ-TB-5 | Capture key bindings per class/spec without losing existing global backup | Implemented; copied profiles restore without replacing the global snapshot |
| REQ-TB-6 | Optional EUI RegisterSkin integration; late/lazy controls; standalone fallback | Implemented; registration/lifecycle tests pass; scrollbar arrow-art skinning USER-REPORTED PASS; scroll input/standalone/theme checks pending |
| REQ-TB-7 | English/French catalogs, `/ruil` launcher and built-in Settings discovery | Implemented; locale parity and Settings registration tests pass; layout review NOT RUN |
| REQ-TB-8 | Preserve old slash commands and manager async/error behavior; no false completion claims | Implemented; full regression and real selected-talent async flow pass |
| REQ-TB-9 | Regression/packaging checks; actual EUI appearance and runtime review | 172 Lua 5.1 tests pass; 28-file artifact check passes; scrollbar skinning USER-REPORTED PASS; remaining visual/input/controller checks pending |

Data design: keep existing bars/talents (class + spec index) and clicks (class
+ stable spec ID) in place. New `templateInfo[class][specID]` stores source
metadata by category, and `bindingTemplates[class][specID]` stores scoped key
binding snapshots. Existing global bindings remain available through the
original slash command, outside the browser because class/spec ownership is
unknown. No guessed ownership of old saves. All browser load paths require
both class and stable active spec ID to match, including at execution time.

UI actions use the existing managers. Browsing never changes specialization
or applies anything. Talent inspection lists names/exports; restoring uses
the existing missing-name import flow. No automatic template loading or new
user-configurable preferences. Settings hosts a launcher, not duplicate data.

Controller assessment: template/category/list rows and action/confirmation
buttons must be reachable with native controller cursor; scrolling has visible
controls and wheel support; Escape dismisses the window/confirmation using
UISpecialFrames, with no custom input capture.
Ordinary buttons remain mouse-operable. No custom controller bindings, input
capture or CVars. Native directional focus is not claimed. Controller cursor,
keyboard navigation, localized layouts and actual rendering remain game tests.

Evidence: local EUI 9.8.4 `SKINNING_API.md` documents RegisterSkin, S.Shell,
Panel, Button, Tab, SetTabSelection, Font, CloseButton, ScrollBar and live
updates. `EllesmereUIBlizzardSkin_SkinAPI.lua` owns the skin primitives;
registration is optional and disabled per user choice. Retail Settings canvas
registration follows the pinned Blizzard_Settings_Shared API; specialization
catalog uses GetSpecializationInfoForClassID and
C_SpecializationInfo.GetNumSpecializationsForClassID.

Verified source controls: BackdropTemplate in Blizzard_SharedXML/Backdrop.xml;
UIPanelButtonTemplate/UIPanelCloseButton in the SharedXML panel templates;
UIPanelScrollFrameTemplate/ScrollBar child in SecureScrollTemplates.xml;
InputBoxTemplate in Shared/InputBox/InputBoxTemplates.xml. The original
SharedXML/SharedUIPanelTemplates.xml path returned 404; the Mainline/common/
secure files were resolved through the pinned tree before implementation.
Click modifiers use GetStringFromModifiers, as in the pinned native editor.
The user subsequently chose horizontal specialization selection: same-class
templates now occupy an evenly spaced row above the content, with no template
scrollbar. The left column contains the current character and category
navigation. Category inspection retains its scrollable area below the row.
Compatible click-casting rows use green status text for available bindings and
amber status text for unlearned spells, alongside explicit labels and a count
summary. Other specs remain neutral; recycled rows reset icon/status/text
when changing category. Colors describe learned-spell availability,
not a guarantee that the client will permit a write or resolve every macro.
After a user-reported loss of left-column skinning, navigation uses S.Button
like the working action buttons, rather than S.Tab on UIPanelButtonTemplate
controls. Selection uses the public GetAccentColor getter and OnLooksChanged
callback; inactive entries keep neutral text. No EUI internals are modified.

## In-game acceptance still required

1. `/reload`, then `/ruil`. Check sidebar, category rows, scrolling, button
   labels and confirmation layout against the mock-up. Repeat with EUI
   third-party skinning disabled (reload) and a changed EUI accent/theme.
2. Open Settings → AddOns → Ruilhenn and launch the same browser. Reopen
   repeatedly, then test Escape, dragging and lower resolutions/UI scales.
3. On each intended source, select the matching template and save categories.
   Verify Guardian/Feral source metadata stays independent. Reload and inspect
   both, then log into a destination and check source/time persistence.
4. Inspect talents, select/copy one export and import a missing named loadout;
   test all-missing import and existing-name display. Spend available points
   first. Verify real server delivery and errors, not merely button clicks.
5. Confirm bars, scoped bindings and clicks load through their existing flows.
   On a character missing a spell, compare the warning with the preview.
   Check the displayed target binding set before accepting account changes.
6. Verify other classes are absent; browse another spec of your class and
   verify mutation buttons are disabled. Open a
   confirmation, enter combat/change spec, and verify it is dismissed. Check
   mouse, keyboard and native controller cursor access to all controls and
   scrolling. French long labels and controller behavior need real review.

Checkpoint: local implementation and automated checks complete on top of
`3e5dfaa`; changes are uncommitted. No connected game/browser capture tool was
available, so actual EUI rendering, template behavior, persistence and input
acceptance remain NOT RUN. Next action: user `/reload` + `/ruil` review.
