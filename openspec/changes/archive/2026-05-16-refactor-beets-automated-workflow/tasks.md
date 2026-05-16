## 1. Framework and Config Boundary Reshape

- [x] 1.1 Create a dedicated `modules/services/beets/` folder and move Beets service logic under it with clear file/module boundaries.
- [x] 1.2 Move Beets config assets out of `scripts/` into the Beets/music ownership boundary and update references accordingly.
- [x] 1.3 Define the initial generic Beets framework interface for config sources, built-in runner kinds, runner instances, trigger/timer wiring, pre/post hooks, and service defaults.

## 2. Music-Owned Workflow Composition

- [x] 2.1 Refactor the Beets service layer into reusable scaffolding for runtime setup, generated runners, generated timers, optional trigger/hook plumbing, hardened units, and config/template plumbing without hardcoding music workflow ownership.
- [x] 2.2 Make `modules/applications/music.nix` authoritative for concrete Beets workflow policy, including which runner instances exist and which config each stage uses.
- [x] 2.3 Ensure the quarantine/manual review path remains operator-invoked over SSH TTY and does not use quiet/headless import flags.
- [x] 2.4 Ensure hardened service units include required rendered secret/config access paths.

## 3. Runner Simplification (approved-promotion + convert removed, ffmpeg-preprocess added)

- [x] 3.0 Remove `approved-promotion` runner kind — operator promotes via quarantine-interactive. Remove beetsConfigs.approved and approved SOPS template.
- [x] 3.0a Remove `convert` runner kind (in-library beet convert stays in reconcile; pre-import convert replaced by ffmpeg-preprocess).
- [x] 3.0b Add `ffmpeg-preprocess` systemd oneshot service + path unit: watches inbox, converts flac/wav → aiff, chains to beets-inbox via OnSuccess.
- [x] 3.0c Simplify `import` runner: keep .tmp lock + settle delay + `beet import -q -C` + baked-in demotion to untagged. Remove embedded `beets-inbox-runner.sh` dependency.
- [x] 3.0d Remove `modules/services/systemd-helpers/` — too thin. Move `hardenedServiceDefaults` into beets module; inline timer/path generation.

## 4. Validation and Operational Smoke Checks

- [x] 4.1 Run repository validation (`nix fmt`, `nix flake check --no-build`) and resolve issues.
- [ ] 4.2 Run targeted smoke checks on oci-melb-1: inbox import, quarantine interactive, ffmpeg-preprocess path trigger, reconcile runner, permission-reconcile runner.
- [ ] 4.3 Document operator invocation examples and expected stage outcomes in change notes.

## 5. Clean Cutover Constraint

- [x] 5.1 Remove the legacy Beets runner architecture (old `beets-inbox-runner.sh`, `beets-inbox.nix`, stale scripts/) as part of the same change so the repo lands on the new framework in one complete cutover.
- [x] 5.2 Delete `scripts/beets-inbox-runner.sh`, `scripts/beets-approved-config.yaml`, `scripts/beets-config.yaml`, `scripts/beets-quarantine-config.yaml`, `modules/services/beets-inbox.nix`.
