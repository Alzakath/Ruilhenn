# Ruilhenn unit tests

Run from the addon root with stock **Lua 5.1**; no test dependencies or game
client are required:

```sh
lua tests/run.lua
```

The default suite includes the existing binding regression checks plus tests
for command parsing, configuration persistence, logging, task scheduling,
event subscriptions/dispatch, action snapshots and restoration, macro
creation/updates/templates, talent exports and guards, locale catalog
consistency, and addon loading through the actual TOC. GitHub Actions runs
this command on pushes to `main` and pull requests.

Each test loads production files in an isolated Lua environment. Minimal
WoW API mocks capture mutations without touching real bindings, macros,
talents or action bars. Frame updates are advanced explicitly, so deferred
execution, frame budgets and failures can be tested deterministically.
Tests are not included in the addon's TOC.

## Known defect reproductions

```sh
lua tests/run.lua --known-issues
```

This opt-in run adds desired-behavior tests for existing defects. It **exits
nonzero while those defects remain**; failures are not swallowed or counted
as passing tests. Move each case into the normal suite when its fix lands.

| Area | Reproduced defect |
| --- | --- |
| #13 | Reversed talent import arguments and non-array placeholder entries (two tests) |
| #14 | Action snapshots require deprecated specialization globals |
| #15 | Character macros in slot 150 are missed |
| #16 | Failed loadout creation is announced as requested |
| #17 | Uncached item data is persisted as `UnknownItem` |
| #18 | Bar clearing mutates action slots during combat |
| Untracked | Invalid bars crash because `INVALID_ACTION_BAR` is absent from catalogs |
| Untracked | EventManager debug toggle calls nonexistent `Log:Info` |
| Stock Lua 5.1 | Event delivery fails without `table.unpack` |

The normal event-dispatch test explicitly supplies a sandbox-local
`table.unpack = unpack` alias to isolate dispatch behavior. The stock Lua
case does not supply that alias. Neither result certifies whether the
installed WoW build supplies this extension. Frame naming/protection, secure
execution, contextual binding semantics, network responses, spell availability,
actual rendering, and persistence across game reload/logout are not simulated.

Local results (2026-11-11, Lua 5.1.5): **36 normal tests passed**; all **10
known-defect tests failed** in their intended behavior paths. Those counts
include the existing #12 regression file as one aggregate test; it retains
its individual assertions. `git diff --check` passed. GitHub Actions has not
run for these unpushed changes. Production addon behavior was not changed.

## Binding backup regression checks

Issue: [#12](https://github.com/Alzakath/Ruilhenn/issues/12). Target: Retail.

Run from the addon root with a Lua 5.1 interpreter:

```sh
lua tests/BindingsManagerTest.lua
```

The test loads the production binding manager with mocked WoW APIs. It checks
two-key round trips, secondary-only and unbound commands, saved binding-set
selection, rejected and no-result assignments, incompatible backup rejection,
empty/missing backups, combat protection, and English/French error formatting
with an unknown-locale English fallback. No real bindings are modified.

New backups use `RuilhennDB.keyBindingsVersion = 1`. Unversioned backups cannot
recover the second key lost by the old return-value mapping, so loading them
is blocked before mutation. Configure the intended live bindings and run
`/ruil bindings save` to replace an old backup. Failed restores are not passed
to `SaveBindings`; successful assignments can still affect the current session.

API evidence was rechecked on 2026-11-11 against Retail source commit
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783):
[Blizzard keybindings implementation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Keybindings.lua).
It confirms `GetBinding` return order and boolean failure handling for
`SetBinding`. No new API, settings option, or interactive UI was introduced.

Validated locally with stock Lua 5.1.5 and `git diff --check`. In-game checks,
saved binding persistence across reload/logout, contextual binding behavior,
and native error rendering remain untested. English/French text was exercised
in the mocked tests; it has not had separate linguistic or in-game review.
