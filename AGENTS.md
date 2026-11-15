# Ruilhenn project guidance

## Scope of this file

Keep this file focused on Ruilhenn-specific decisions and repository navigation.
Use the installed `wow-addon-dev` plugin and its applicable skills for general
WoW development, client/API research, UI construction, localization, controller
support and validation. Do not copy those skill instructions or API reference
material into this file. Avoid version-specific plugin installation paths.

## Product and project decisions

Ruilhenn shares configuration templates between characters of the same class
and specialization. Different specializations may have different source
characters; categories are saved independently.

Read the relevant project document before changing its behavior:

- [Readme.md](Readme.md): player-facing features and command behavior.
- [docs/TEMPLATE-BROWSER.md](docs/TEMPLATE-BROWSER.md): browser requirements,
  storage relationships, user decisions, implementation checkpoint and acceptance.
  This includes current-class filtering, exact class/spec load compatibility,
  horizontal specialization selection and optional EllesmereUI skinning.
- [docs/CLICK-CASTING.md](docs/CLICK-CASTING.md): native profile replacement,
  macro identity, skipped unlearned spells and recorded runtime results.
- [docs/UI-DESIGN-PROMPT.md](docs/UI-DESIGN-PROMPT.md): addon/product design brief.
- [docs/Ruilhenn-UI-Handoff.md](docs/Ruilhenn-UI-Handoff.md): subsequent accepted
  UI direction, first redesign scope and acceptance criteria. Inspect its
  referenced three-screen image before implementing visual fidelity changes.
  The HTML mock-up is an earlier design artifact; later recorded user decisions
  take precedence where its layout differs.
- [docs/RETAIL-VALIDATION.md](docs/RETAIL-VALIDATION.md) and
  [docs/RETAIL-COMPATIBILITY.md](docs/RETAIL-COMPATIBILITY.md): historical Retail
  evidence. Reconcile older checkpoints with newer feature notes and code.

Update the relevant feature document when requirements or acceptance change.
Keep evolving task status there rather than in this file.

## Code navigation

- `Core.lua` defines the addon namespace; `Main.lua` initializes the addon and
  dispatches slash commands. `Ruilhenn.toc` defines runtime loading order.
- `*Manager.lua` files own category save/load operations. `TalentImport.lua`
  decodes talent exports; `ItemData.lua` handles deferred item information.
- `TemplateStore.lua` provides template discovery, provenance and action
  dispatch; `TemplateBrowser.lua` presents it. Keep restore behavior in the
  existing managers rather than implementing a second restore path in the UI.
- `RuilhennDB` is the persisted shared configuration. Preserve legacy backups;
  the feature notes describe mixed spec-index/spec-ID keys and scoped bindings.
- `l10n/` contains English/French catalogs; `macros/` contains class templates.
- EllesmereUI is a sibling addon and an optional integration. Its installed
  public `SKINNING_API.md` documents the supported interface. Work on Ruilhenn's
  integration, not EllesmereUI's implementation.

## Repository checks and packaging

From the addon root:

```sh
lua5.1 tests/run.lua
python tools/package_release.py --check
```

Use the available stock Lua 5.1 executable if its name differs. See
[tests/README.md](tests/README.md) for fixtures and verification limits.
`python tools/package_release.py` builds and verifies the local ZIP in `dist/`.
Keep `.pkgmeta` exclusions consistent with developer-only files; the local
packager includes runtime files through the TOC.

`RETAIL-API-REVIEW.md` is a pre-existing user-owned review file; leave it out of
unrelated edits and commits.
