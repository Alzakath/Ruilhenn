# Refresh preview label

Task ID: `2026-11-13-refresh-preview-01`

Status: **Ready for implementation**.

Authorization: the user explicitly requested this exact English/French rename
as a two-agent workflow test and requested a Ready handoff. Implementation is
assigned to the separate Lua Codex session; creating this request does not start it.

## User problem and intended outcome

Clarify that the browser's Refresh action refreshes its preview. Display exactly
**Refresh preview** in English and **Actualiser l’aperçu** in French. Preserve the
current action, including any existing selection/export reset behavior.
Accepted requirement and evolving status: [browser feature record](../../../TEMPLATE-BROWSER.md#refresh-preview-label--2026-11-13).

## Inspected source and working tree

HEAD: `3e5dfaa2d79e0ed9efe997678bf0c6ecfbe34880`.
TemplateBrowser.lua is untracked; both catalogs already have unrelated local
modifications. Managers, tests, TOC, packaging and other documents also contain
pre-existing uncommitted work. Inspect the live files and preserve all of it;
HEAD alone does not contain the implementation being changed.

Current code: TemplateBrowser.lua creates `self.reload` from `L.UI_REFRESH`,
116 logical pixels wide and 34 high, with `function() self:Refresh() end`.
Refresh positions it at x=518 for a saved category or x=266 for Overview/missing
categories. The button helper enables wrapped text. Current catalog values are
`Refresh` / `Actualiser`. Repository search found this browser button as the
runtime consumer of `UI_REFRESH`; confirm before editing.

## Scope and exclusions

- Change the existing `UI_REFRESH` value in l10n/enUS.lua and l10n/frFR.lua.
- If needed for label fit, make the smallest change to this button's width or
  text fit in TemplateBrowser.lua. Preserve footer alignment and gaps.
- Report implementation and validation in developer-owned `response.md` here;
  update the feature's implementation evidence without rewriting its requirement.
- No changes to callback, refresh semantics, managers, storage, other labels,
  navigation, confirmations or restoration behavior. No general footer redesign,
  translation cleanup, new preference, commit or push. Preserve RETAIL-API-REVIEW.md.

## Layout, copy and states

Use the exact copy above, including French accents and typographic apostrophe.
Continue using the localization catalog and English fallback. The longer labels
must remain fully readable within the button, with no clipping, ellipsis,
overlapping controls or escape outside its hit region. Prefer a single line
and a minimal width adjustment if necessary; do not shrink text to an unreadable size.
Check both existing footer positions: saved category with Save on the left and
Load on the right; Overview/missing category with Refresh at the left. Keep
current visibility, enabled states, hit handling and input behavior unchanged,
including browsing during combat/inactive-spec states.

No new mockup is needed for this explicit text-only request. Reference:
[accepted PNG register](../../reference/README.md) and
[UI-SPEC.md](../../../UI-SPEC.md); this accepted rename supersedes older
“Refresh” wording only.

## Observable acceptance criteria

1. English browser button reads exactly `Refresh preview`; French reads exactly
   `Actualiser l’aperçu`, using the existing localized key with English fallback.
2. Full labels fit at the normal UI scale in saved-category and Overview/missing
   footer arrangements, both standalone and with optional EUI styling. No overlap
   with Save/Load, no truncation and no illegible font reduction. Check a smaller
   supported viewport/scale as part of the existing scale-to-fit behavior.
3. Activation still invokes the existing `UI:Refresh()` path once and performs
   no save/load operation. No changes to selection/export reset or event handling.
4. Other player-facing copy, footer actions and restoration safeguards remain
   unchanged. Existing English/French key parity remains valid.

## Required checks and client verification

Run stock Lua 5.1 `tests/run.lua` and `python tools/package_release.py --check`
from the addon root, using available equivalent executable names. Report actual
commands/results. Reuse existing locale parity/browser coverage; no new test
suite is required for a literal rename. If geometry changes, inspect footer
spacing statically and report the exact adjustment.

In WoW: after reload, capture English and French button fit in the two footer
arrangements; include representative EUI and standalone views with locale,
resolution/UI scale and skin context. Click once and confirm preview refreshes
with the same behavior and no restore/save. Report unavailable checks as NOT RUN;
fixtures do not establish label fit. User captures may complete this review later.

## Open questions and dependencies

No product question blocks implementation. The current 116-pixel width may be
insufficient, especially in French; this is an inferred fit risk, not an observed
in-game defect. Rendering acceptance depends on actual-client evidence. Avoid
concurrent edits with the UI session. The user relays the request and response.
