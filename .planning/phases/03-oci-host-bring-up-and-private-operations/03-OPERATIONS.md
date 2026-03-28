# Phase 03 Operations Runbook (Day-2)

Use this sequence for routine updates after initial host bootstrap.

## Canonical Routine

1. Run phase verification before update:

   ```bash
    just verify-phase-03
    ```

2. Capture pre-change break-glass baseline (record the current generation as known-good):

   ```bash
   just breakglass-baseline
   ```

3. Apply host-targeted rebuild:

   ```bash
   just redeploy
   ```

4. Confirm host health:

   ```bash
   just status
   ```

5. Confirm private network state:

   ```bash
   just tailscale-status
   ```

## Rollback Pointer

If update verification fails or host access regresses, follow:

- `.planning/phases/03-oci-host-bring-up-and-private-operations/03-BREAKGLASS.md`

Routine operations rely on the same declared console and key contracts in `03-BREAKGLASS.md`; treat any drift there as a blocker before continuing day-2 changes.

## Scope Guard

This phase keeps deployment workflow host-targeted and **no deploy-rs adoption yet**.
