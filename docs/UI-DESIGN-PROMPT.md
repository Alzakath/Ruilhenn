# Prompt: design the Ruilhenn addon UI

Design a polished in-game interface for **Ruilhenn**, a World of Warcraft Retail addon that saves and restores character configurations through shared templates.

## What Ruilhenn does

Ruilhenn helps players configure multiple characters of the same class and specialization without repeatedly rebuilding their talents, action bars, key bindings and click-casting setup.

A player uses a well-configured character as a template source, then loads that configuration on other compatible characters. Different specializations can use different source characters. For example:

- Oakheart is the source for Druid / Guardian.
- Wildclaw is the source for Druid / Feral.
- Other druids can load the appropriate template when that specialization is active.

Templates are shared by class and specialization. Each configuration category is saved separately and displays its own source character, realm and save date. Saving one category does not update the others. There is one current shared snapshot per category and specialization, rather than a collection of named whole-character profiles.

## Features to represent

### Talent loadouts

Browse saved named talent builds, inspect or copy their export strings, and import one selected build or all missing builds. Show which names already exist on the current character; existing names are kept unchanged. Importing a build does not activate it. Imports may take time while the game creates loadouts, and can be refused if talent points remain unspent.

### Action bars

Save and restore spell, item and macro placements, including additional action pages and druid forms. Let players inspect the saved layout using understandable bar/slot labels and recognizable icons. Restoring fills saved placements; empty saved slots do not clear the current layout. Some item information may load asynchronously.

### Key bindings

Save and restore both keys assigned to an action. Display whether the saved bindings apply to the account or character, since account bindings affect other characters. Loading applies saved assignments without clearing every other binding.

### Click casting

Save and restore Blizzard's native click-casting configuration: mouse buttons, modifier combinations, spells, macros and interactions such as targeting or opening a unit menu.

Loading replaces the current native click-casting profile. Spells the destination character has not learned are skipped with a warning, while the complete template remains available for later use. Use a simple availability code:

- **Green:** binding available to restore.
- **Amber:** spell not learned; binding will be skipped.

Keep text labels and a legend so color is not the only cue. For example, a level-80 character loading a higher-level template might restore nine bindings while skipping Blessing of Freedom.

Missing or ambiguous macros can prevent restoration. The native click-casting editor must be closed before saving/loading. Report success only after the game confirms the resulting profile. This feature covers native Blizzard bindings, not private settings from other click-casting addons.

### Supporting utilities

Ruilhenn also provides class-specific macro-generation utilities and client/API diagnostics. These can be secondary tools; keep the main interface focused on browsing, saving and loading templates.

## Primary user journeys

1. **Create or update a template:** log into the source character, select its active specialization and a configuration category, inspect the existing source if present, then save the current configuration after confirmation.
2. **Configure another character:** open Ruilhenn on a character of the same class, choose the matching specialization, inspect the available template and warnings, then confirm loading the selected category.
3. **Explore another specialization:** inspect its saved configuration without changing the character's active specialization or applying anything.
4. **Inspect a talent build:** select a named loadout, see whether it already exists, copy its export or import it individually.
5. **Understand partial restoration:** see which click-casting spells are unavailable before loading, then receive a clear result showing what was restored and what was skipped.

## Agreed navigation and behavior

- Show only specializations belonging to the current character's class.
- Place specialization selection **horizontally above the content**, allowing room for up to four choices without a specialization scrollbar.
- Offer existing saved specializations and the current specialization, so the current configuration can be saved even when no template exists yet.
- Keep the current character and configuration-category navigation in the **left column**.
- Allow browsing other saved specializations of the same class, but enable Save/Load only when **both the class and active specialization match**.
- Clearly distinguish the **template source** from the **current destination character**. Source and save date can differ between categories.
- Present saved contents, availability and relevant warnings before loading.
- Confirm actions that replace a shared saved category or apply settings to the current character. Explain each category's actual effects.
- Allow browsing during combat, but disable saving/loading until combat ends. Dismiss pending confirmations if combat or specialization changes.
- Do not automatically apply templates or switch specialization.
- Existing backups may have an unknown source/date; display that honestly until they are saved again.
- Distinguish an empty saved category from a category with no backup.
- Show pending asynchronous operations separately from confirmed completion, and communicate errors clearly.

## Visual direction

The player uses an **EllesmereUI-based interface**, so Ruilhenn should feel consistent with it: dark panels, restrained boundaries, clear typography, compact controls and a visible selected state using the user's accent color.

Use EllesmereUI's **public Skinning API** for the eventual in-game implementation. Ruilhenn should have its own window, optionally styled by EUI, with a usable standalone fallback. Keep EUI integration optional and avoid relying on its private implementation. Left-column navigation should use its button styling and an accent-colored selected label.

The interface opens with `/ruil` or `/ruil ui`, and is also accessible from **Settings → AddOns → Ruilhenn**.

Support English and French, including longer translated labels. Provide clear hover, focus, selected and disabled states. Account for mouse, keyboard and controller-cursor access, readable contrast, scrolling only when needed, and reasonable behavior at different UI scales.

Keep the interface focused on player decisions. Use recognizable spells, actions and readable modifier names. Avoid exposing internal identifiers or technical diagnostics in ordinary workflows.

## Requested design deliverables

Propose a coherent visual hierarchy and interaction design, then show representative screens for:

1. An overview of an available template, with clear source/destination information.
2. Talent-loadout browsing and individual selection.
3. Click casting with available and skipped bindings.
4. A saved specialization that can be browsed but cannot currently be loaded.
5. A category with no saved backup.
6. A save/load confirmation and a pending, successful or partial-result state.

Explain the main save/load journeys briefly. Preserve the behaviors above, and label any suggested new functionality as a proposal rather than assuming it already exists. Focus on the addon and user experience; a database schema is not needed.
