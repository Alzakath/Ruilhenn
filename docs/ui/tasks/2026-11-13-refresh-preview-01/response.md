# Implementation report — 2026-11-13-refresh-preview-01

## Status

Implemented locally. The user explicitly assigned this Ready task. No commit or
push was made.

## Implemented behavior and changed files

- `l10n/enUS.lua`: `UI_REFRESH` now reads exactly `Refresh preview`.
- `l10n/frFR.lua`: `UI_REFRESH` now reads exactly `Actualiser l’aperçu`, with
  the requested typographic apostrophe and accent.
- `TemplateBrowser.lua`: widened only the existing Refresh button from 116 to
  152 logical pixels. Its 34-pixel height, localized key, callback to
  `self:Refresh()`, visibility, enabled state and footer positions are
  unchanged. No manager, save/load, selection/export reset or event behavior
  was changed.
- `docs/TEMPLATE-BROWSER.md`: recorded local implementation evidence and kept
  actual-client label fit pending.

Static footer geometry: in a saved category, Save spans x=266–506, Refresh
preview spans x=518–670, and the right-anchored Load button begins at x=750,
leaving 12 pixels between Save and Refresh and 80 pixels between Refresh and
Load. In Overview or a missing category, Refresh remains at x=266 and ends at
x=418; it does not overlap the right-anchored Load control. Overview/missing
Save visibility is unchanged.

## Checks and actual results

- `python tools/package_release.py --check` — **PASS**; Retail artifact
  validated 28 files, interface 120105, load order and file-name case.
- `git diff --check` — **PASS**; Git emitted existing LF-to-CRLF working-copy
  notices for unrelated modified files.
- Localization consumer search — **PASS**; the browser button remains the
  runtime consumer of `UI_REFRESH`, and both catalogs contain the requested
  exact values. Existing suite locale-parity coverage was not executed here.
- Footer spacing — static calculation above; no automated geometry assertion
  was added, consistent with the request.
- `lua tests/run.lua` — **NOT RUN**. No stock Lua executable (`lua`, `lua51`,
  or `lua5.1`) was available on PATH or in the searched standard Windows
  installation locations. No substitute runtime was used.

## Deviations, constraints and unresolved questions

The button width increased by 36 logical pixels, the only geometry change.
Automated mocks cannot establish actual Retail text measurement or EUI font
styling. The accepted copy and functionality are implemented, but label fit in
game is not yet verified.

## In-game verification still required

**Label fit is unverified in game**, as requested. After `/reload`, inspect the
English and French labels in both footer arrangements, with standalone styling
and EUI styling. Confirm the complete single-line label remains readable at
normal scale and a smaller supported viewport/UI scale, with no clipping,
ellipsis or overlap. Click once in each locale and confirm the existing preview
refresh behavior runs without saving or loading. Controller focus/reachability
is unchanged by this text/width adjustment and was not tested in game.

Suggested captures: (1) saved category showing Save, Refresh preview and Load;
(2) Overview or missing category with Refresh preview on the left; capture both
in English and French, and repeat representative views with EUI enabled and
standalone styling. Include resolution, UI scale and EUI/theme context.

## Source and worktree

Request source HEAD: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`, matching the
live HEAD `3e5dfaa` at implementation start. The working tree already
contained extensive unrelated uncommitted runtime, UI, localization, test,
packaging and documentation changes; they were preserved. `request.md`,
`review.md` and `RETAIL-API-REVIEW.md` were not edited. All changes remain
uncommitted.
