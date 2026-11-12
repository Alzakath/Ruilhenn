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
| REQ-17 | Wait for item data, resume safely, never persist UnknownItem, report permanent failure | Implemented; 82 normal tests pass, including 9 item-data cases. Ready for delivery. Runtime not run. |
| REQ-18 | Refuse clearing in combat before cursor mutation; preserve normal clearing | Next slice. |
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

Current slice: #17 ready to commit/push/close. Next: implement combat guard
and clearing acceptance for #18. Read `ActionBarsManager.lua` and
`tests/KnownIssuesTest.lua`. Update this record after each slice.
