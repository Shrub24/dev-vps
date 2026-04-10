---
phase: quick-260410-r8p-codify-syncthing-library-write-acl
plan: 01
subsystem: infra
tags: [nixos, syncthing, acl, contracts]
requirements-completed: [QUICK-260410-R8P-01]
completed: 2026-04-10
---

# Phase quick-260410-r8p Plan 01 Summary

Codified Syncthing write ACL on `/srv/media/library` for folder-marker reproducibility and updated contracts accordingly.

- Added library ACL entries in `modules/applications/music.nix`:
  - `a+ /srv/media/library - - - - user:syncthing:rwx`
  - `a+ /srv/media/library - - - - default:user:syncthing:rwx`
- Updated `tests/phase-04-service-flow-contract.sh` to assert both rules.
- Relaxed the negative ACL guard to allow only the new library ACL plus existing quarantine ACLs.
- Verified with:
  - `bash tests/phase-04-service-flow-contract.sh`
  - `bash tests/phase-04-syncthing-contract.sh`
