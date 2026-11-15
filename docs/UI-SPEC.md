# Accepted UI specification

Established 2026-11-13. Target: the installed Retail addon. This is the entry
point for the accepted UI contract, not a claim of visual or runtime acceptance.

## Authority and source ownership

The accepted specification incorporates these existing sections by reference;
they are intentionally not copied into a second specification:

| Subject | Authoritative source |
| --- | --- |
| Shared layout, visual hierarchy and representative states | [Handoff: shared layout](Ruilhenn-UI-Handoff.md#shared-layout-specification) and [representative screens](Ruilhenn-UI-Handoff.md#representative-screens) |
| Product contract | [Handoff: agreed product contract](Ruilhenn-UI-Handoff.md#agreed-product-contract) and [browser feature requirements](TEMPLATE-BROWSER.md) |
| Observable redesign acceptance | [Handoff AC01–AC13](Ruilhenn-UI-Handoff.md#acceptance-criteria); current evidence belongs in [TEMPLATE-BROWSER.md](TEMPLATE-BROWSER.md#handoff-acceptance-and-verification) |
| Restoration effects, guards and newer talent/bar decisions | [RESTORE-FIXES.md](RESTORE-FIXES.md), read through its latest follow-up; [CLICK-CASTING.md](CLICK-CASTING.md) for native profile semantics |
| Player journeys and original design brief | [UI-DESIGN-PROMPT.md](UI-DESIGN-PROMPT.md) |
| Accepted artwork | [Reference register](ui/reference/README.md) |

Newer explicit user decisions and feature-document corrections take precedence
over the archive handoff. Code establishes implementation evidence, not automatic
acceptance of a changed requirement. Resolve discrepancies explicitly rather than
silently rewriting the accepted contract to match code.

## Reconciliation with the live checkout

The handoff's first implementation slice is already present locally. Its old
“ready” task and copy/paste starter are historical instructions, not a new work
queue. [The baseline review](ui/BASELINE-2026-11-13.md) maps the current code and
remaining evidence gaps. Do not restart that slice from the archive.

The richer talent, action-bar and binding redesigns, Utilities navigation and
inline asynchronous result layer remain deferred as recorded in the handoff.
Existing chat results remain the completion channel. Newer talent safeguards,
action-state refresh and partial bar restoration must be preserved; see the
restore feature document for their exact scope and outstanding runtime checks.

Geometry in the handoff is a starting point for in-game review. Teal, sample
names/dates/counts, generated icons and artwork are illustrative. The filled
navigation selection and Utilities entry in the PNG do not override the written
accent-label/marker decision or deferred scope. The older HTML is historical.

## Maintaining this contract

Accepted [binding-scope direction](TEMPLATE-BROWSER.md#key-binding-scope-question--2026-11-14):
future browser imports default to character-specific bindings regardless of
source scope. The accepted reset action copies account bindings to replace the
current character's own set, leaves character-specific mode active and preserves
account bindings. The bounded bindings-scope task now has a developer report of
local implementation; independent review and actual-client verification remain
pending in the feature/task records. Do not treat reported implementation as
accepted runtime behavior.

Accepted [accent decision](TEMPLATE-BROWSER.md#selection-and-class-identity-review--2026-11-14):
follow EUI's configured live accent; users choose another accent in EUI rather
than through a separate Ruilhenn preference. Keep the standalone fallback.
The same feature record now owns accepted destination/source class-color roles
and category icon scope; source names use a subdued class-to-gray blend rather
than the earlier neutral-only treatment.

Accepted [color roles](TEMPLATE-BROWSER.md#accepted-color-policy) govern the
hierarchy pass; exact API-compatible shades remain implementation choices
subject to readable contrast and capture review.

Accepted copy amendment: [browser Refresh preview label](TEMPLATE-BROWSER.md#refresh-preview-label--2026-11-13)
supersedes the handoff's Refresh wording for that button; its behavior is unchanged.

Record accepted behavior changes and evolving acceptance/status in the relevant
feature document, then update this index when its references change. Keep
evidence and implementation requests in the [review workflow](ui/README.md).
Proposals do not become accepted requirements until the user agrees. No task is
Ready for implementation without authorization of its bounded scope.

Mouse, keyboard, controller-cursor access, English/French layout, optional EUI
and standalone rendering remain acceptance dimensions. Existing documentation
does not claim native directional focus. Static code and fixture results do not
verify input access, readability, clipping, taint or real client writes.
