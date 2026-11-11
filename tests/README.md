# Binding backup regression checks

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
