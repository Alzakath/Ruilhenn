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
| REQ-18 | Refuse clearing in combat before cursor mutation; preserve normal clearing | Delivered in `7298ab3`; #18 closed. Runtime not run. |
| REQ-19 | Validate packaging, TOC, build and actual-client acceptance; record precise evidence | 92 normal tests pass; 25-file ZIP and TOC verified. Installed executable/build metadata confirm 12.1.5.70783. Current runtime feature checks await the user; keep #19 open. |
| REQ-LOCALE | New visible errors have English fallback and French catalog entries | Applicable per slice; placeholder consistency tested. Separate linguistic/client review not run. |

No new configurable setting or visible panel was added. Slash commands remain
the entry points, including the read-only `/ruil validate` diagnostic. UI
mock-ups and controller navigation are not applicable to these internal fixes
and diagnostic chat output; preserve existing bindings.

## Evidence and limitations

- #15 constants: [Retail macro constants](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua).
- User reported their client is 12.1.5 and earlier in-game checks were all OK
  after #12/#13. This is user-reported evidence, not an exact build capture or
  a pass for the later #14–#18 changes.
- Lua tests use explicit mocks. No actual WoW persistence, combat restrictions,
  server delivery, spell availability or third-party UI integration is certified.
- On 2026-11-12 the local `Wow.exe` version and active Retail `.build.info`
  product entry both report 12.1.5.70783. No running WoW process was observed.
- GitHub Actions passed for #15 (`4cc03dd`), #16 (`fe78444`), #17 (`e9ffea7`)
  and #18 (`7298ab3`). Automated ZIP check/build produced a verified 25-file
  artifact in `dist/`. Actual-client acceptance is tracked separately in
  `docs/RETAIL-VALIDATION.md`.
- Release checks also repaired the remaining event-dispatch/logger unit
  failures and made English text a genuine base catalog for all locales.

## Resume checkpoint

Current slice: automated #19 work ready for commit/push. A user runtime-results
question is pending. Next: collect `/ruil validate` output and the feature
checklist results, record pass/fail/not-run precisely, then close #19 only
when its actual-client acceptance is satisfied. #5 remains planned after #19.
