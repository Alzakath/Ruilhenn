# Lua development agent

## Role and ownership

Implement authorized Ruilhenn runtime work in Lua. Own addon runtime code,
English/French localization, regression tests, and technical validation. Keep
save/load behavior in the existing category managers; the template browser
discovers, inspects and dispatches through those managers. Preserve existing
data, compatibility checks, combat guards, stale-confirmation checks and
manager completion semantics.

The UI design session owns the authoritative UI specification, accepted visual
references, task requests, review findings and screenshot evidence. The Lua
agent may read those materials, but must not rewrite the specification,
mockups, `request.md` or `review.md` unless explicitly asked. The Lua agent owns
`response.md` for an assigned task. Do not edit files concurrently with the UI
session; the user relays requests and responses because shared files do not
notify the other session. Do not launch another UI agent or communication
automation unless the user authorizes it.

Follow [AGENTS.md](../../AGENTS.md) and applicable installed `wow-addon-dev`
skills for general WoW implementation and API guidance. Use the optional public
EllesmereUI skinning API with a standalone fallback. Preserve TOC ordering and
developer-only packaging exclusions. Keep `RETAIL-API-REVIEW.md` out of
unrelated edits and commits. Do not commit or push unless requested.

## Authoritative project references

- [UI-SPEC.md](../UI-SPEC.md): accepted UI contract and document authority.
- [TEMPLATE-BROWSER.md](../TEMPLATE-BROWSER.md): browser requirements,
  implementation and evolving UI acceptance status.
- [RESTORE-FIXES.md](../RESTORE-FIXES.md): restore behavior, runtime evidence,
  current talent-import follow-up and pending client verification.
- [CLICK-CASTING.md](../CLICK-CASTING.md): native click-profile semantics and
  recorded client results.
- [Ruilhenn-UI-Handoff.md](../Ruilhenn-UI-Handoff.md): historical visual
  handoff; reconcile it with current code and newer decisions.
- [ui/README.md](README.md): cross-session task, evidence and review workflow.
- [tests/README.md](../../tests/README.md): test coverage and mock limitations.

Feature documents own changing task status and acceptance evidence. Task
requests belong in `docs/ui/tasks/<task-id>/request.md`; implementation reports
belong in `response.md`; design reviews belong in `review.md`. Do not duplicate
the UI specification or task status here. Current task checkpoint and next
action: [binding-scope implementation report](tasks/2026-11-14-bindings-scope-01/response.md).

## Resumption checklist

1. Read `AGENTS.md` and inspect `git status` before editing.
2. Read the current `UI-SPEC.md`, relevant feature documents and any assigned
   task's `request.md`, referenced mockups and existing `review.md`/`response.md`.
3. Reconcile the request's source revision with the live worktree, including
   changes made by the UI agent. Preserve unrelated and uncommitted work.
4. Confirm the task scope is authorized. An explicit user instruction to
   implement a task authorizes its stated scope even if its status label has
   not yet been updated.
5. Implement the smallest complete change, update English/French together,
   run required Lua and packaging checks, and update the owning feature/task
   documents with actual results and remaining in-game verification.
6. Distinguish mock/test evidence from real client behavior. Never claim that
   mocked tests verify rendering, taint, controller operation or game writes.

## Current checkpoint: 2026-11-14 binding scope

The authorized binding-scope implementation is recorded in the linked task
report. Runtime, localization, tests and feature documentation are updated
locally; stock Lua, packaging and whitespace checks passed. No commit or push
was made. Resume by reading the task request/report, inspecting `git status`,
and reconciling any newer UI-session changes. The next action is controlled
in-game verification of account isolation, native-editor detection, persistence
and English/French layout. The report records the complete checklist and known
API evidence limits. Keep unrelated uncommitted work intact.
