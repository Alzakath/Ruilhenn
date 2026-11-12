# Retail 12.1.5 validation evidence

Date: 2026-11-12. Source: `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783). Target interface: 120105. This is the evidence record for #19.

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Installed build | PASS (filesystem) | `Wow.exe` and active Retail `.build.info` both report 12.1.5.70783. This does not capture a running session. |
| TOC, case and file order | PASS | `python tools/package_release.py --check`; 25 distributable files. |
| Local ZIP | PASS | `dist/Ruilhenn-retail-12.1.5.zip`; CRC and exact entry list verified, one `Ruilhenn/` root, no developer files. |
| Lua regression suite | PASS | 92 normal cases on stock Lua 5.1.5; all former known-defect cases promoted to normal suites. |
| CI for #15–#18 | PASS | GitHub Unit tests succeeded for `4cc03dd`, `fe78444`, `e9ffea7`, `7298ab3`. |
| Earlier game check | USER-REPORTED PASS | User said everything was OK on 12.1.5 after #12/#13; not evidence for subsequent changes. |
| Current runtime build/API observation | NOT RUN | No live-client tools or running WoW process available. Run `/ruil validate`. |
| Macro slots/full storage/repeat initialization | NOT RUN (game) | Mocked coverage passes; current client result needed. |
| Multiple missing talent loadouts | NOT RUN (game) | State-machine tests pass; real server delivery needed. |
| Uncached items and failure handling | NOT RUN (game) | Mocked event tests pass; genuine cold-cache result needed. |
| Bar clearing and combat restrictions | NOT RUN (game) | Cursor/slot mock checks pass; game restrictions needed. |
| Fallback APIs disabled | NOT RUN (game) | All fixtures omit deprecated globals; actual-client setting not captured. |
| Reload/logout/restart persistence | NOT RUN (current changes) | Earlier coarse user confirmation predates the current changes. |
| Template spell behavior / learned availability | NOT RUN (game) | Diagnostic checks metadata only, not gameplay behavior or whether spells are learned. |

## Client procedure

Use a backed-up disposable profile; with WoW closed, back up WTF before
testing shared bindings or macros. Disable unrelated addons for the baseline,
then test EllesmereUI integration separately. No game state is changed by the
diagnostic command itself.

1. Enable Lua errors (`/console scriptErrors 1`), reload, and run
   `/ruil validate`. Record its build/interface/locale and missing-API output.
   The saved diagnostic can be inspected with `/dump RuilhennDB.validation`.
2. Verify the addon loads with out-of-date addons disabled. Test binding
   save/load with two keys on one action and the intended account/character set.
3. Test `/ruil macro init` twice, including an existing generated macro in a
   late character slot and full character storage. Existing macros should
   update; new macros should fail clearly when full. Inspect template spell
   metadata reported by the diagnostic and test applicable macros manually.
4. Save disposable talent builds containing choice and hero talents. Restore
   with two names missing. Only one creation should be pending at a time;
   both should complete without retrying the command. Try combat/spec changes
   while pending, and note rejected requests or timeouts rather than calling
   them successful imports. Compare exports and selected nodes.
5. Save bars including an item, spell and macro. Restore with an item whose
   data is genuinely uncached if available; no slots should change until item
   data arrives. Test an item-based macro too. Mark cold-cache testing NOT RUN
   if cache state cannot be established; do not infer it from a cached pass.
6. Save a disposable layout and test `/ruil bars clear 1` outside combat.
   In combat, both that command and `/ruil bars clear` must refuse without
   moving the cursor or changing any slot. Restore the disposable layout.
7. Record the original `loadDeprecationFallbacks` value from the diagnostic.
   If the client permits changing it, test with `/console loadDeprecationFallbacks 0`
   followed by `/reload`, then restore the original value after testing. If
   refused, record the restriction and leave this check NOT RUN.
8. Repeat persistence verification after reload, clean logout/login, and full
   restart. Restore the original error-display setting when finished.

For each scenario record PASS/FAIL/NOT RUN, trigger, observed result and any
Lua/protected-action error. A success chat message alone is not a feature pass.
Keep #19 open until the remaining runtime acceptance has been supplied.
