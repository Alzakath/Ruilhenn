# UI specification and review workflow

For session role and resumption, read [UI-AGENT.md](UI-AGENT.md).
Start with [UI-SPEC.md](../UI-SPEC.md). Feature documents own requirements,
acceptance and evolving feature status. Review records link to those documents
instead of keeping competing acceptance tables.

## Ownership and files

| Path | Purpose / owner |
| --- | --- |
| `reference/` | Accepted visual references; UI design session |
| `feedback/<review-id>/` | User-supplied screenshots and observations; UI design session records findings |
| `tasks/<task-id>/request.md` | Bounded implementation request; UI design session |
| `tasks/<task-id>/response.md` | Implementation report and questions; Lua developer only |
| `tasks/<task-id>/review.md` | Review findings and acceptance recommendation; UI design session |

Use descriptive stable IDs, for example `2026-11-13-clicks-01`. Create a feedback
or task directory when real evidence or a concrete authorized/proposed task
exists. No speculative implementation task was created during setup.

The design session may inspect runtime code/tests but does not edit Lua,
localization, tests or developer responses without explicit implementation
authorization. Shared files do not notify or wake the other session. The user
hands requests and responses between sessions. Coordinate edits to shared
feature documents; avoid editing a file while the developer owns an active edit.

## Evidence and review

For each screenshot batch, record filenames, user observations/reproduction,
date, revision plus relevant uncommitted changes, client build/locale,
resolution/UI scale, EUI enabled/theme and active versus selected spec when
known. Mark missing context unknown. Retain originals; separate annotated
images from original captures.

Distinguish **observed** evidence, **inferred risk**, and **unverified behavior**.
For each finding record priority, affected journey/state, evidence, proposed
correction, and whether the user has accepted it. A code observation is not an
observed in-game defect. Link later evidence to the same finding.

Read `response.md` without editing it; review code and developer evidence, then
record remaining findings or an acceptance recommendation in `review.md`.
Only actual-client evidence supports in-game verification. Automated passes and
user reports retain their stated scope and revision. Record accepted decisions
in the owning feature document and link them from UI-SPEC.md as needed.

## Required request contents

Every `request.md` must include:

- Task ID and status: **Proposed** or **Ready for implementation**. Ready requires
  user authorization of that scope; record its source. File creation never starts implementation.
- User problem and intended outcome; accepted requirement links versus proposals.
- Source commit, relevant working-tree changes, unknown revision details and dependencies.
- Scope and explicit exclusions; files/areas the developer may change.
- Referenced screenshots/mockups and their evidence context.
- Layout, copy, behavior, input access and relevant UI states, including disabled,
  missing/empty, inactive specialization, combat and confirmations where relevant.
- Observable acceptance criteria linked to the owning feature requirements.
- Required automated checks and in-game verification; separate rendering/input
  evidence from manager operation evidence.
- Open questions and dependencies. Do not silently settle unresolved product choices.

Normal implementation checks are stock Lua 5.1 `tests/run.lua` and
`python tools/package_release.py --check`, following [tests/README.md](../../tests/README.md).
The design session need not rerun runtime tests for documentation-only edits.
`docs/` is already excluded by `.pkgmeta`; the local packager uses a TOC-driven
allowlist. Keep this arrangement for future screenshots and task artifacts.
