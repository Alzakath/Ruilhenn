# Ruilhenn Changelog

## Unreleased
- Add client/API diagnostics and release validation; repair stock Lua 5.1 event dispatch and English locale fallback found during validation (#19).
- Refuse bar clearing during combat before touching the cursor; validate bar arguments and report rejected pickups (#18).
- Wait for uncached item data before writing macros or restoring bars; handle failure, superseded requests and unsafe delayed callbacks (#17).
- Restore missing talent loadouts in sequence using server creation events, with rejection, timeout, combat and specialization handling (#16).
- Search all client-defined character macro slots and report full storage or rejected writes (#15).
- Use current Retail specialization and action-text APIs without deprecated fallback wrappers (#14).
- Decode and validate Retail talent import strings before restoring loadouts; fix import argument order and report game rejection details (#13).
- Fix key binding backups to preserve both keys and exclude the binding category (#12).
- Reject incompatible older binding backups with instructions to save them again.
- Report failed key assignments without saving an incomplete restore or reporting success.

## v0.4.0
- Feature: Added Talent Manager to save and load talent builds across characters.

## v0.3.3
- Update TOC Interface versions to include 11.0.7 and 12.0.1.
- Bump addon version to 0.3.3.
- Add CHANGELOG.md.
