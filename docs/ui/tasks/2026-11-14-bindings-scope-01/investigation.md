# Copy account bindings: failure and prerequisite clarity

Parent task: `2026-11-14-bindings-scope-01`.
Status: **Ready for investigation**, explicitly requested by the user.
This is a bounded follow-up to the existing task, not a new restore feature.

## User problem and evidence

Clicking Copy produces a generic read/verify failure before confirmation:
[capture](../../feedback/2026-11-14-bindings-copy-read-failure.png).
The user's main concern is that they cannot tell what prerequisites are needed.
Read review.md for the recorded failure, earlier findings and native editor
workflow observations. Do not assume the problem is missing user setup.

## Investigation questions

1. Confirm the exact required conditions and compare them with actual guards:
   out of combat, native editor closed, selected template class/spec compatible,
   binding APIs available. No saved template or pre-enabled character mode is
   required; the accepted action works starting in account OR character mode.
   Source template scope is irrelevant. If implementation imposes other
   requirements, explain whether they are a verified API constraint or a defect.
2. Identify the exact read/load/restore stage behind this capture's error. Verify
   GetBinding arguments/returns, contextual or duplicate keys and LoadBindings
   failure semantics. Distinguish demonstrated causes from hypotheses. Do not
   discard records or bypass guards to manufacture success.
3. Determine why an available-looking action has no clear explanation of what
   the user must do. Propose concise English/French helper copy and targeted
   blocked/failure messages. Separate actionable prerequisites from internal
   failures: “close the editor” and “could not read account bindings” are not
   interchangeable. Avoid presenting implementation details as user setup.

## Scope and boundaries

Inspect native Retail source/contracts and current code/tests. Use only minimal
stage/reason diagnostics if needed; no verbose row dumps or new trace framework.
The baseline read can temporarily change live bindings: preserve and verify live
map/mode restoration, make no account writes, and report uncertainty honestly.
No actual game mutation is authorized merely to diagnose the capture. The user
performs agreed retests. Do not force Quick Keybind and Ruilhenn simultaneously:
the user established Quick Keybind closes Ruilhenn and prevents chat interaction.

Report first in developer-owned response.md: confirmed prerequisites, exact
cause or smallest missing discriminator, relevant API evidence, findings and a
bounded correction proposal with proposed localized copy. Do not silently expand
scope or change the accepted copy-to-character semantics. No speculative runtime
fix before evidence; any diagnostics must be identified and removable afterward.
Keep earlier B01/B02 findings visible in the report.

## Expected outcome and validation

- A player can understand whether the action is usable and what it will do.
- A reproducible internal failure is distinguished from a missing prerequisite;
  unresolved diagnosis has one concrete next test rather than a setup checklist.
- Both starting scopes and missing-template state remain supported by design.
- Account data/source backups and live state are preserved; no false success.

If diagnostics/code are changed, run stock Lua 5.1 tests/run.lua and
python tools/package_release.py --check; add a meaningful case for the confirmed
failure when applicable. Report actual results and unperformed client checks.
For documentation-only investigation, state checks not rerun rather than copying
historical totals as new evidence. Preserve unrelated work, developer response
ownership and RETAIL-API-REVIEW.md. Do not edit request.md/review.md, commit, push,
modify EUI or launch agents/communication automation.
