# Ruilhenn

Ruilhenn is a World of Warcraft addon designed to streamline the management of your character's interface configuration. It provides tools to save, restore, and manage your action bars, key bindings, and macros, ensuring a consistent experience across specializations and sessions.

## Features

### 1. Action Bar Management
Never lose your spell placement again. Ruilhenn allows you to save your action bar layout (spells, items, and macros) specific to your current Class and Specialization.
- **Save**: Snapshots your current action bars.
- **Load**: Restores your action bars to the saved state for your current specialization.
- **Clear**: Quickly empty your action bars to start fresh.

### 2. Key Bindings Manager
Keep your control scheme intact.
- **Save**: Backs up your current key bindings.
- **Load**: Restores your key bindings from the saved profile.

### 3. Talent Manager
Share your builds across characters.
- **Save**: Saves all talent loadouts for your current specialization.
- **Load**: Imports saved talent loadouts to your current character (skips if a loadout with the same name exists).

### 4. Macro Management
Includes utilities to help generate and manage class-specific macros, reducing the manual effort of writing standard utility macros for every character.

### 5. Native Click-Casting Profiles
Save Blizzard's native click-casting bindings per class and specialization.
Restore the saved profile on another character of the same class/spec, with
macro indices resolved by name and account/character scope. Create the
referenced macros first; missing or ambiguous macros abort restoration.
Load replaces the entire native profile, including removing bindings absent
from the backup. Private settings belonging to other click-casting addons
are not included. Combat operations are refused, and restore success is
reported only after native readback matches. Restricted client writes may
be refused; check the reported error and current click-casting settings.
Spells not yet learned by the destination character are skipped with a
warning; the remaining bindings are restored and verified. The saved backup
keeps those spells so they can be restored after learning them.
Save or discard edits and close Blizzard's native click-casting window
before using these commands; reopening it refreshes its staged display.

## Usage

Type `/ruil` or `/ruilhenn` to access the addon.

- `/ruil help` : List all available commands.
- `/ruil bars save` : Save action bars for the current spec.
- `/ruil bars load` : Restore action bars for the current spec.
- `/ruil bindings save` : Save current key bindings.
- `/ruil bindings load` : Restore saved key bindings.
- `/ruil clicks save` : Save native click-casting bindings for the current class/spec.
- `/ruil clicks load` : Replace the current native click-casting profile with its backup.
- `/ruil clicks status` : Show read-only differences for the last attempted restore.
- `/ruil talents save` : Save talent builds for the current spec.
- `/ruil talents load` : Import saved talent builds.

## Why use Ruilhenn?

- **Multi-Spec Friendly**: Automatically handles different layouts for different specializations, so you don't have to manually drag spells around when switching roles.
- **Backup & Restore**: Acts as a safety net for your UI configuration. If your settings get reset or you move to a new PC, you can quickly restore your familiar setup.
- **Setup Speed**: Drastically reduces the time required to set up a new character or fix a broken UI.
