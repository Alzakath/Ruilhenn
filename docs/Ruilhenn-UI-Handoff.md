# Ruilhenn UI specification and Codex handoff

Version: 2 · 13 November 2026 · Historical handoff; visual direction accepted.

Live-checkout reconciliation: the first slice below is already implemented
locally. Its task and starter are historical, not a fresh implementation request.
Start with [UI-SPEC.md](UI-SPEC.md), the [baseline review](ui/BASELINE-2026-11-13.md)
and current feature-document acceptance before using this archive handoff.

## Purpose and working agreement

This chat specifies and visualizes the addon UI. The coding agent implements Lua in the real repository. Return in-game captures and implementation notes here for review. This document contains the agreed specification, source mapping, decisions and the first bounded implementation task. Keep evolving requirements, acceptance and implementation status in the relevant feature documents, as required by AGENTS.md. A dedicated docs/UI-SPEC.md may hold the enduring UI specification if useful; link to it from docs/TEMPLATE-BROWSER.md rather than duplicating authoritative text. Do not move task status into AGENTS.md.

The accepted reference is the three-screen image “Ruilhenn click-casting UI mockups.png” from this conversation. Attach it alongside this document when starting a coding session. It shows Click casting, Overview and an empty Action bars category. The written behavioral rules take precedence over illustrative details in that image. Teal is a sample accent; source names, dates and counts are sample data. Exact spell artwork and navigation icons in the generated image are not production assets.

## Reviewed source snapshot

Reviewed the supplied Ruilhenn.zip, especially TemplateBrowser.lua, TemplateStore.lua, ClickCastingManager.lua, the TOC, localization catalogs, browser documentation, UI fixture, browser tests and packaging script. This is a point-in-time archive, not the live repository. Check the current checkout and its instructions before editing.

The separately supplied AGENTS.md has now been reviewed and incorporated below. It supplements the archive; it was not present inside that earlier ZIP. CLAUDE.md remains unavailable in the supplied material. Read the current repository instructions before editing; do not infer unseen instructions. The bundled .gemini reference material is not a substitute for project guidance.

### Project guidance from AGENTS.md

- Use the installed `wow-addon-dev` plugin and applicable skills for general WoW development, client/API research, UI construction, localization, controller support and validation. Discover them in the coding environment; do not hardcode version-specific installation paths or copy their instructions/API references into project guidance. This handoff does not claim those skills have been loaded or applied during this source review.
- Before changing behavior, read Readme.md, docs/TEMPLATE-BROWSER.md, docs/CLICK-CASTING.md and docs/UI-DESIGN-PROMPT.md as relevant. Consult docs/RETAIL-VALIDATION.md and docs/RETAIL-COMPATIBILITY.md for historical evidence; reconcile older checkpoints with newer feature notes and code.
- The HTML mockup is an earlier artifact. Later recorded user decisions take precedence where layouts differ. The accepted mockup and this specification supply the subsequent UI direction without changing the existing product contract.
- Update the relevant feature document when requirements or acceptance change; keep evolving task status there. Keep AGENTS.md focused on Ruilhenn decisions and navigation.
- Core.lua owns the namespace, Main.lua initialization/commands, and Ruilhenn.toc runtime load order. Existing managers own save/load; TalentImport.lua decodes talent exports and ItemData.lua handles deferred item information. Do not implement a second restore path in the UI.
- Preserve RuilhennDB legacy backups and mixed spec-index/spec-ID storage relationships, including scoped bindings.
- EllesmereUI is an optional sibling addon. Consult its installed public SKINNING_API.md and work only on Ruilhenn integration, not EUI implementation.
- Use stock Lua 5.1 (the executable name may differ); read tests/README.md for fixture and verification limits. Keep .pkgmeta exclusions consistent with developer-only files; the local packager follows the TOC for runtime files.
- RETAIL-API-REVIEW.md is a pre-existing user-owned review file. Leave it out of unrelated edits and commits.

These repository rules constrain implementation. The UI specification defines the agreed player experience; it does not replace repository instructions.

The archive already has horizontal specialization selection in TemplateBrowser.lua and describes it in docs/TEMPLATE-BROWSER.md. The earlier screenshots show a preceding layout. Preserve the newer horizontal arrangement rather than treating screenshots as the current source structure.

### Source map

| File / symbol | Existing responsibility | UI work |
| --- | --- | --- |
| AGENTS.md | Project decisions, navigation and development workflow | Read first; keep task status in feature docs |
| TemplateBrowser.lua: Create | Lazy window creation, sidebar, spec row, content scroll, footer, export box | Rework geometry and shared regions |
| TemplateBrowser.lua: Refresh | Selection, catalog rendering, rows, descriptions, enabled states | Category title, honest saved counts, category-specific rendering |
| TemplateBrowser.lua: Confirm / Accept | Explicit confirmation, captured snapshot, stale-selection checks | Preserve checks; improve category-specific wording/layout |
| TemplateBrowser.lua: Style / ApplySkin / Initialize | Optional EUI registration, lazy styling, theme callback, events | Retain public API boundary and fallback |
| TemplateStore.lua: Current / Catalog / Compatible | Current class/spec, saved same-class catalog, compatibility | Reuse; browsing must stay read-only |
| TemplateStore.lua: Data / Source / Inspect | Saved content and display rows, per-category provenance | Add structured presentation fields only where needed |
| TemplateStore.lua: Execute | Dispatch to existing managers | Preserve mutation guards and manager ownership |
| ClickCastingManager.lua | Capture, validate, resolve macros, skip spells, write and verify profile | Preserve behavior; avoid duplicating restoration logic |
| TalentManager.lua / TalentImport.lua | Talent inspection/import workflows | Retain existing workflows in this iteration |
| ActionBarsManager.lua / BindingsManager.lua | Existing save/load behavior | Retain existing workflows |
| l10n/enUS.lua / frFR.lua | Localization | Add matching keys and review long labels |
| tests/TemplateBrowserTest.lua / UIFixture.lua | Control/event harness | Extend meaningful state/interaction coverage |
| docs/TEMPLATE-BROWSER.md | Existing requirements and verification history | Update with actual new results; do not claim in-game verification |
| docs/UI-MOCKUP.html / UI-DESIGN-PROMPT.md | Earlier design artifacts | Mark superseded details where applicable |

## Agreed product contract

- One current shared snapshot per class, specialization and category. No collection of named whole-character profiles.
- Categories: Talents, Action bars, Key bindings, Click casting. Overview navigates to categories; it does not save or load all categories.
- Each category has independent source character/realm and saved time. A source change in one category changes no other category.
- Catalog includes saved same-class specializations and the current specialization, even without a backup. Do not add every unsaved inactive specialization.
- Browsing never switches specialization or applies settings. Save/load require matching class AND active stable specialization ID.
- Browsing is allowed in combat; mutations are disabled. Combat/spec changes dismiss pending confirmations. Recheck at execution time.
- Preserve legacy data. Unknown source/date remains honestly unknown until resaved. Missing backup and saved-but-empty are different states.
- Preserve existing slash commands and Settings → AddOns → Ruilhenn launcher.
- EUI is optional. Use its public skinning interface and provide a usable standalone fallback. Do not copy private EUI implementation or artwork.
- All player-facing copy uses English/French localization keys. Color always has a text equivalent.

## Shared layout specification

The existing logical 1040 × 680 window is a starting implementation size, not a pixel-perfect requirement. Use shared spacing constants and anchored regions. Fit the available screen without clipping at different UI scales. Do not stretch the addon to fill the screen unnecessarily.

1. Compact title bar: Ruilhenn, close button, draggable title region, Escape closes.
2. Left column: current destination character and realm, class and ACTIVE specialization. Below: Overview, Talents, Action bars, Key bindings, Click casting.
3. Horizontal specialization row above main content, room for up to four choices without a specialization scrollbar. Selected template and active player specialization are separate states. Identify the active one explicitly, even when browsing another tab.
4. Main header: category title (e.g. Click casting); subordinate text identifies selected class/spec. Saved category source/time appears in a compact metadata region. No source region for a nonexistent backup.
5. Content region: compact left-aligned rows or a deliberate empty state. Scroll the content only as needed; show functioning wheel/visible scrollbar controls for overflow. No detached icons or unexplained spinner.
6. Footer: secondary Save current [category]… and Refresh together on the left; primary Load [category]… on the right. Overview has no mutation buttons. Empty compatible categories promote their Save action in the content, avoiding duplicate prominent actions.

Use near-black shell, charcoal panels, subtle borders and off-white text. Selected navigation uses EUI accent text plus a visible marker; avoid implementing a filled accent background if the public skin cannot support it cleanly. Body/input/action text is neutral; green/amber belongs mainly to status labels. Use actual game spell textures where available and a neutral placeholder when unavailable. Navigation icons are optional for this iteration; do not let icon work block layout.

Proposed starting geometry: 16–24 logical-pixel outer/content padding; 8–12 between controls; 32–36 high ordinary rows/buttons, expandable for translated text; 210–240 sidebar. These are implementation defaults to validate in-game, not newly approved fixed dimensions. Dynamic labels must not collide with metadata or adjacent columns.

## Representative screens

### Overview

Four navigable category rows with category name, snapshot state and its OWN provenance when saved. Show real content counts where available, but never interpret four navigation rows as four saved entries. Summary is N of 4 categories saved. A saved empty snapshot counts as saved. Missing backup: “No backup saved”. Existing snapshot without provenance: “Unknown source”. Include saved time for each saved category, directly or in an accessible detail/tooltip. Selecting a row opens that category.

### Click casting

Three aligned columns: Input | Action | Availability. Action column has spell icon and readable name, or readable macro/interaction name. Example inputs: Right mouse button; Shift + Right mouse button; Mouse button 5. Localize modifiers/button descriptions. Do not expose internal action IDs as ordinary labels; use a readable unresolved/loading placeholder and preserve useful diagnostic details separately.

Available rows use a green status with text. Unlearned spells use amber “Not learned — skipped”. Above content: X bindings available · Y will be skipped. “Available” means the learned-spell check passed; it is not a guarantee that macros resolve or the client permits the write. For incompatible browsed specs, use neutral “Availability checked on the active specialization” wording instead of destination green/amber judgments.

Persistent concise effect warning: loading replaces the character's native click-casting profile; unlearned spells are skipped; complete template is retained. Native editor must be closed for saving/loading. Preserve macro-resolution failures and actual profile verification.

Current Inspect returns combined text/detail/missing fields. Extend with structured input/action/kind/status/icon fields as needed; keep existing consumers working or update their tests deliberately. Never parse localized combined strings back into columns. Summaries derive from the same rows shown to the player. Reset every recycled row's icon, status, text color and visibility when reused.

### No backup

Category heading, simple empty-state graphic optional, “No [category] backup saved”, concise category-specific explanation, Save current [category]… if compatible. Load disabled with a visible reason. No invented source/date. Keep saved-but-empty distinct: “Saved template contains no entries”, with genuine provenance. Loading an empty click profile can clear the native profile; confirmation must describe that effect.

### Browsed inactive specialization

Keep normal inspection and source details. Show a stable notice: “Viewing Protection. Your active specialization is Holy. Switch specialization in game to save or load.” Both actions disabled. No automatic switch button or automatic application. This state must not hide a separate no-backup or empty-snapshot state.

### Confirmation and result

Save confirmation names category, selected class/spec, current character and previous source if one exists; explains replacement of that shared category. First save says it creates a backup rather than implying one exists.

Load confirmation names category, source and destination plus the category's exact effect. Click casting repeats replacement and predicted skipped count; account key bindings warn about effects on other characters. Cancel returns without mutation. Pending confirmations remain bound to the reviewed snapshot and selection.

Do not equate a successful pcall or an accepted queued task with completed restoration. Existing managers own completion/error truth. A new inline pending/result layer is deferred to a dedicated follow-up unless supported by an existing reliable completion signal. Preserve chat/log feedback in the first iteration. Do not fabricate progress bars, completion callbacks or success messages.

## First Codex implementation task

Implement the shared visual shell, Overview, Click casting and no-backup presentation described above. Preserve functional Talents, Action bars and Key bindings browsing/actions using the shared shell; their richer category-specific redesigns come later. Keep the work focused on UI and presentation adapters. No SavedVariables migration, manager rewrite, new talent activation behavior, automatic loading or whole-profile feature.

Suggested sequence:
1. Inspect working-tree status and read the current AGENTS.md (plus CLAUDE.md if present). Use the installed wow-addon-dev plugin and applicable skills. Read the relevant feature docs and tests/README.md before editing. Preserve unrelated local changes, including RETAIL-API-REVIEW.md. Identify differences from this archive before applying assumptions.
2. Rework shared shell and selected/active states with optional EUI and standalone fallback. Reuse existing module boundaries; extract small UI helpers only if justified.
3. Add structured category presentation data needed by Overview/Click casting. Keep per-category provenance separate from current destination.
4. Implement compact rows, summaries, no-backup versus empty states and explicit localized actions. Preserve confirmations and execution guards.
5. Update meaningful interaction/state tests, English/French catalogs and relevant feature docs with requirements, acceptance and actual task status. Keep developer-only additions excluded appropriately in .pkgmeta, preserve TOC loading order, and leave RETAIL-API-REVIEW.md out of unrelated edits/commits. Run repository checks and report actual results.
6. Supply an in-game screenshot checklist and list any unverified rendering/API behavior. Do not claim screenshot fidelity from the frame harness.

### Acceptance criteria

- AC01: horizontal same-class specialization row; current unsaved spec included; no spec scrollbar; active spec distinct from selected spec.
- AC02: current character stays visible in sidebar; selected category and selected spec have clear non-color-only markers.
- AC03: category title leads; independent real source/date displayed only for existing snapshots; unknown provenance never guessed.
- AC04: Overview counts actual saved snapshots including saved empty snapshots; category rows navigate correctly; no Overview Save/Load.
- AC05: click table aligns input, action/icon and status; readable mouse/modifier names; skipped summary matches shown rows.
- AC06: unavailable spell warning is visible before loading and template data is not mutated by preview.
- AC07: missing backup and saved empty remain distinct; empty click profile warning explicitly describes replacement with an empty profile.
- AC08: inactive-spec/combat mutations disabled with reasons; browsing remains possible; confirmations invalidated on context or snapshot change.
- AC09: explicit save/load confirmations retained, including scope/effect; no manager call from mere selection or Refresh.
- AC10: native editor, unresolved macro and write verification failures retain existing manager behavior; no false UI success.
- AC11: French/English labels fit or wrap; scrolling works; row reuse leaves no stale colors/icons/status/export UI.
- AC12: EUI accent/theme update works for existing and lazily created widgets; no EUI dependency for basic use.
- AC13: talents individual selection/export/import, action-bar restore and both key assignments continue working; legacy commands preserved.

### Validation and review

From repository root:

```sh
lua5.1 tests/run.lua
python tools/package_release.py --check
```

Use the available stock Lua 5.1 executable if its name differs; use the available Python 3 executable (`python` or `python3`). Read tests/README.md for fixture limits. `python tools/package_release.py` builds and verifies the local ZIP in dist/ when a release artifact is requested. Keep .pkgmeta developer-only exclusions consistent with any new files; the local packager includes runtime files through the TOC.

Test meaningful changes: real saved-count calculation, missing versus empty, click structured rows and skip counts, inactive-spec/combat guards, stale confirmation cancellation, navigation, row reuse and locale parity. Adapt UIFixture only to represent used control behavior; do not test arbitrary pixel coordinates as proof of appearance.

Manual captures requested: (1) Overview with mixed saved/missing categories, (2) clicks with available/skipped rows, (3) missing action bars, (4) inactive saved spec, (5) save/load confirmation, (6) long French labels. Repeat key views with EUI skinning off. Exercise overflow, smaller screen/UI scale, theme accent changes, Escape, dragging and native controller cursor. Record NOT RUN where unavailable. Rendering, clipping, taint and real client writes require in-game verification.

## Decisions and deferred work

Accepted: dark optional-EUI direction; horizontal specs, left category navigation; compact structured click rows; explicit source/destination; category-specific actions; clear empty states; preserve independent snapshots and guards.

Implementation defaults to validate: exact dimensions, spacing, typography sizes, icon sizes, selection-marker geometry. The generated image does not establish a proprietary skin API contract.

Deferred proposals: Utilities navigation destination (mockup placement only; preserve existing utilities access), richer talent master/detail view, graphical action-bar layout, dedicated bindings view, inline async operation lifecycle/results. Do not add dead Utilities navigation or promise a pending/success UI without implementing reliable completion signals.

## Copy/paste starter for Codex

> Implement the first task in the attached Ruilhenn-UI-Handoff.md, using the accepted three-screen mockup as the visual reference. Read and follow the repository's current AGENTS.md (and CLAUDE.md if present), and use the installed wow-addon-dev plugin with applicable skills. Read relevant feature documents and tests/README.md, then inspect the current code and preserve unrelated work. Leave RETAIL-API-REVIEW.md out of unrelated edits and commits. Start with TemplateBrowser.lua and TemplateStore.lua; preserve existing save/load managers, legacy data, localization, optional public EUI integration and all compatibility/combat/stale-confirmation guards. Deliver the shared shell plus Overview, Click casting and empty states; preserve other category workflows. Update requirements, acceptance and task status in the relevant feature documents, maintain .pkgmeta exclusions and TOC load order, and run the stated checks using stock Lua 5.1. Report changed files, verified behavior, remaining in-game checks and any scope issue. Do not implement deferred proposals or claim game rendering was tested without in-game evidence.

## Revision history

- v2 — Incorporated the separately supplied AGENTS.md: plugin/skill workflow, required project reading, feature-document ownership of task status, optional sibling EUI public API, legacy storage constraints, stock Lua checks, packaging exclusions and protection of RETAIL-API-REVIEW.md. Replaced the earlier missing-AGENTS notice. UI scope and accepted visual direction unchanged.
- v1 — Initial archive review, UI specification and first implementation task.
