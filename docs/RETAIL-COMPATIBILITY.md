# Retail compatibility delivery: #15–#19

Target: Retail 12.1.5. Source pin: `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783), resolved 2026-11-12. Interface: 120105.

Authorization: implement, validate, commit, push and close each issue in order.
Keep the pre-existing untracked `RETAIL-API-REVIEW.md` outside these commits.
Do not mark unavailable client evidence as passed.

| Requirement | Acceptance | Implementation / verification |
| --- | --- | --- |
| REQ-15 | Client-derived macro range, update every character slot, report full/rejected writes | Delivered in `4cc03dd`; #15 closed. Runtime not run. |
| REQ-16 | Serialize loadout creation, handle rejection/events, prevent duplicate requests and unsafe combat writes | Delivered in `fe78444`; #16 closed. Runtime not run. |
| REQ-17 | Wait for item data, resume safely, never persist UnknownItem, report permanent failure | Delivered in `e9ffea7`; #17 closed. Runtime not run. |
| REQ-18 | Refuse clearing in combat before cursor mutation; preserve normal clearing | Implemented; 87 normal tests pass, including 5 clearing cases. Ready for delivery. Runtime not run. |
| REQ-19 | Validate packaging, TOC, build and actual-client acceptance; record precise evidence | Pending fixes; current host has no confirmed live WoW connection. |
| REQ-LOCALE | New visible errors have English fallback and French catalog entries | Applicable per slice; placeholder consistency tested. Separate linguistic/client review not run. |

No new configurable setting or visible panel is planned. Existing slash
commands remain the entry points. UI mock-ups and controller navigation are
not applicable to these internal fixes; preserve existing bindings.

## Evidence and limitations

- #15 constants: [Retail macro constants](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua).
- User reported their client is 12.1.5 and earlier in-game checks were all OK
  after #12/#13. This is user-reported evidence, not an exact build capture or
  a pass for the later #14–#18 changes.
- Lua tests use explicit mocks. No actual WoW persistence, combat restrictions,
  server delivery, spell availability or third-party UI integration is certified.

## Resume checkpoint

Current slice: #18 ready to commit/push/close. Next: complete automated release
checks and obtain a current user runtime capture for #19. Read issue #19,
`tests/README.md` and the remaining known-defect cases. Do not convert missing
runtime evidence into a pass or close #19 as completed prematurely.
