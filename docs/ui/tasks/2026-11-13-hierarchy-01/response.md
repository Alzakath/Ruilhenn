# Implementation response — 2026-11-13-hierarchy-01

Status: **R01 and R03 implemented. R02's enabled-EUI arrow-art fallback was
confirmed by the user to work. Temporary diagnostics have been removed; focused
fallback tests and the public EUI integration remain. Scroll interaction and
standalone appearance still need separate verification.**

## Design evidence reviewed

Reviewed the task's [observations and screenshots](../../feedback/2026-11-13-hierarchy-01/observations.md)
(`Screenshot 2026-11-13 223203.png` and `Screenshot 2026-11-13 223333.png`),
the [hierarchy HTML proposal](../../drafts/hierarchy-preview.html), and the
[implementation capture review](../../feedback/2026-11-13-hierarchy-01/implementation-captures.md)
with six screenshots. The click captures show inherited right justification in
reused rows; scrollbar arrows remain visible. The linked EUI 9.8.4 follow-up batch adds
[Talents](../../feedback/Screenshot%202026-11-13%20235518.png),
[EUI settings](../../feedback/Screenshot%202026-11-13%20235535.png), and
[Click casting](../../feedback/Screenshot%202026-11-13%20235606.png). The settings
capture visibly has global third-party skinning and Ruilhenn enabled. It still
does not prove callback receipt or primitive execution. I retained the live
shell geometry and treated the HTML as a hierarchy guide, not pixel-perfect
artwork.

## Implemented behavior

- Added primary, secondary, supporting, and semantic status text roles. Overview
  categories and talent build names use the normal body font and primary color;
  counts, statuses and provenance use secondary/supporting roles. EUI
  `Font` styling is followed by role reapplication; selected navigation and
  selected talent rows use the current EUI accent. Standalone colors remain.
- Split the sidebar destination into a quiet current-character label, prominent
  character name, realm, class/spec, and active-specialization line.
- Split category source identity and explicitly labeled saved time in the source
  panel. Overview keeps each category's source/date and full timestamp, leads
  with the category name, puts state/count at the right, and uses a separate
  trailing chevron. Removed the misplaced “below” instruction.
- Talents rows use a prominent build name and compact neutral status. The
  summary reports all-present, mixed, or all-available counts for the active
  specialization; inactive-spec entries remain unchecked. Empty saved data
  retains its empty state. The existing-name policy, prerequisites, and
  select-to-inspect/copy-export instruction now have separate lines. A
  theme/skin refresh preserves a selected build and its export while refreshing
  its accent color.
- Removed the direct `Hide()` on the native content scrollbar. It remains
  registered with the public EUI `ScrollBar` styling primitive and is shown
  only when the content exceeds its viewport. The shell geometry, category
  managers, load/save flow, and accepted Refresh preview wording were retained.
- Reset each recycled row's input, action, status and secondary text to left
  justification before rendering. Click action text stays left-aligned beside
  its existing icon; click availability aligns left beneath its column header.
  Overview state and talent status keep their deliberate right alignment.
- Hid and cleared the generic Overview helper. Its now-unused English/French
  catalog entries were removed.
- The user-provided callback and region snapshots showed that the enabled
  public call left visible arrow textures 130854 and 130856 unchanged at alpha 1
  and white vertex color. Ruilhenn fades textures on the native up/down arrow
  Button frames after public scrollbar styling, only when `S.IsEnabled()` is
  true. It leaves those buttons, their scripts, the Slider thumb and its texture
  untouched. Standalone mode is unchanged. Per the user's cleanup request,
  temporary verbose scrollbar traces, snapshot helpers, callback/scroll hooks,
  trace-only state and trace-specific assertions have been removed. The
  fallback reads `S.IsEnabled()` at application time; no diagnostic state is
  retained. Focused enabled/disabled behavior tests remain.
- Deferred optional hero-tree identification. The presentation pass does not
  decode exports or guess from build names; safe read-only resolution for
  inactive, legacy, and invalid exports was not established as necessary here.

## Changed files

- `TemplateBrowser.lua`
- `TemplateStore.lua`
- `l10n/enUS.lua`, `l10n/frFR.lua` (including removal of unused Overview helper)
- `tests/TemplateBrowserTest.lua`, `tests/UIFixture.lua`, `tests/README.md`
- `docs/TEMPLATE-BROWSER.md`
- This report

The request, review and visual references were not modified. Existing unrelated
work in the shared worktree was preserved. No commit or push was made.

## Checks

- `python tools/package_release.py --check` — **PASS**; 28 runtime files,
  interface 120105, TOC load order and filename case valid.
- `git diff --check` — **PASS**; Git emitted only existing LF-to-CRLF working
  copy notices.
- `lua -v` — **Lua 5.1.5**.
- `lua tests/run.lua` — **PASS**; 172 tests passed, 0 failed. This includes
  navigation/justification and callback/primitive/lazy-lifecycle coverage,
  EUI-enabled arrow-only fading and disabled-skin preservation,
  summary/overflow/theme-role coverage, and existing manager regressions.
- EUI scrollbar arrow-art appearance — **USER-REPORTED PASS** for the enabled
  setup. Wheel/thumb/arrow input, theme changes, standalone appearance, taint,
  controller/keyboard navigation, and game writes — **NOT RUN**. The frame
  harness only exercises control state and presentation data.

## Scrollbar findings and implementation (R02)

The browser already called the public EUI `ScrollBar` primitive for the
`UIPanelScrollFrameTemplate` child and set `scrollBarHideable`; it then manually
hid that same child. That was a concrete Ruilhenn-side visibility conflict and
is now removed. `UpdateScrollBarVisibility` shows the child only when the
rendered content is taller than the visible scroll frame. The test harness
checks the 4-row Overview fits (bar hidden) and a 5-row Talents list overflows
(bar shown), then switches back and checks that the bar hides again.

The settings capture visibly confirms global **Skin Third-Party Addons**
and per-addon **Ruilhenn** toggles enabled. The Talents and Click casting
captures still show arrow/button art. The user then supplied the in-game trace
below, which confirms the callback ran enabled after reload and before the
content scrollbar was created.

Ruilhenn's code registers through `RegisterSkin`. The scroll helper stores the
actual scroll frame and its `frame.ScrollBar`, then registers that same child
through `UI:Style`. If the callback arrived first, `Style` applies the primitive
at creation; if it arrives later, `ApplySkin` replays registered widgets. The
prior visibility fix only removed a forced hide and toggles the bar for
overflow; it does not explain persistent arrow art.

The user-provided runtime trace reports `S.IsEnabled=true` and zero scrollbars
registered at callback time. The browser then creates its content scrollbar
after the callback. Ruilhenn logs that the widget is the displayed child of
`RuilhennTemplateContents/ScrollFrame`, named
`RuilhennTemplateContentsScrollBar`, with WoW object type `Slider`. Its two
enumerated children are the scroll-up and scroll-down arrow buttons; the
reported `Back`, `Forward`, `Track`, and `ThumbField` fields are absent, and
`GetThumb` is unavailable. The public primitive is called during creation with
that exact displayed object and returns. Therefore callback delivery, enabled
configuration, registration timing, and target-object mismatch are ruled out
for this run. A subsequent region trace showed the visible arrow textures
(file IDs 130854 and 130856) still at alpha 1 and white vertex color after the
primitive returned; the IDs also match their pre-call values. The Slider's
thumb texture is a distinct named region and is not faded by the fallback.
This identifies the concrete integration gap: the public primitive returns
for this `UIPanelScrollFrameTemplate` Slider but leaves its child arrow-button
textures untouched. The API does not document this child-region shape.

The user also supplied before/after region snapshots and confirmed the visual
fallback worked. The temporary diagnostic code has now been removed; enabled
and disabled fallback behavior remains covered by focused tests.

The sibling public `SKINNING_API.md` promises faded arrow/track art and a thin
thumb; it exposes `S.IsEnabled()` but does not specify accepted child-region
shapes, report which subregions it changed, or return a style result from
`S.ScrollBar`. The API implementation is not exposed by the sibling install in
this workspace. The widget API skill's bundled Retail 12.1.5.70783 declaration
ledger (source pin `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`) verified the
read-only methods used in the completed region inspection. Based on the
unchanged visible-arrow texture state, Ruilhenn fades only textures on the
two named arrow Buttons when EUI skinning is enabled. It does not hide or
disable the buttons, replace native scripts, or alter the thumb; when EUI is
disabled the native arrow art remains. No EUI internals were changed. The
The user subsequently confirmed that the latest modification worked for
skinning. This verifies the visual result in the reported EUI setup. Arrow-button
operation, wheel/drag scrolling, theme changes and standalone appearance still
need in-game verification.

Diagnostic cleanup removed temporary R02 callback, primitive and region
logging, inspection helpers, the `OnVerticalScroll` observer, trace-only state
and trace-specific assertions. Ordinary debug logging elsewhere is unchanged;
no logging level was added. The enabled-only arrow fallback, public EUI skin
registration and normal scrollbar overflow behavior remain. The fallback
queries public `S.IsEnabled()` as needed and stores no tracing state.

## Deviations and unresolved questions

- Hero talent names were deferred as expressly optional.
- Exact English/French line fit is unverified. Overview source/date combines
into one supporting line; very long character/realm names may wrap in the
existing widths. No in-game label-fit claim is made.
- The user confirmed the EUI skinning result. For further acceptance, install
  the updated code, `/reload`, and check that the thumb remains while wheel,
  thumb dragging and arrow-button scrolling still work.
- Repeat with EUI skinning disabled after reload; confirm native standalone
  appearance is unchanged. Check EUI theme changes do not restore arrow art.

## Remaining in-game verification

1. Capture Overview and Talents with comparable source data before/after
`/reload`, including category-specific source/date and an all-present talent
summary. Confirm names lead, statuses/counts are secondary, and provenance is
quieter without clipping.
2. Check mixed and all-available talent summaries, saved-empty, selected export,
inactive specialization, and a blocking talent prerequisite. Verify no
inactive state claims availability.
3. The user confirmed the EUI scrollbar skinning result. Verify wheel, thumb and
   arrow-button scrolling with content that fits and overflows. Repeat with EUI
   disabled and after a theme change to verify standalone appearance and
   persistent EUI styling.
4. Check English and French at the user's usual and smaller UI scales, with long
character/realm names. Confirm the Refresh preview button and footer remain
unclipped; this task's own in-game fit was not established by prior label
acceptance evidence.
5. Check mouse, keyboard, and native controller cursor reachability; no new
input capture or bindings were introduced.

Suggested review screenshots: Overview with mixed saved/missing categories and
independent sources; Talents with all five builds present; Talents with mixed
present/available status and visible overflow. Include locale, UI scale, EUI
enabled/theme state in the capture notes.

## Source state

Implemented against the request's recorded base HEAD
`3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`. The worktree already contained
substantial unrelated uncommitted and untracked project work before this task;
all of it remains uncommitted. Reconcile the complete worktree before any
future commit.
