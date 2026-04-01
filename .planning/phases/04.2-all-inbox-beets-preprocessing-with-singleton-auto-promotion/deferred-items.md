# Deferred Items (Out of Scope)

Recorded during phase 04.2 execution per scope-boundary rules.

## Regression gate findings not fixed in this phase

1. `tests/phase-03-access-contract.sh` fails on existing Termix/admin assertions unrelated to the 04.2 Beets promotion scope.
2. `tests/phase-03-operations-contract.sh` fails on existing operations contract assertions unrelated to the 04.2 Beets promotion scope.
3. `tests/phase-02-03-host-contract.sh` fails on existing host contract assertions unrelated to the 04.2 Beets promotion scope.
4. `tests/phase-04.1-beets-contract.sh` fails because 04.2 intentionally supersedes the 04.1 slskd-only/no-promotion contract boundary.

These items were not auto-fixed because they are either pre-existing outside task scope (1-3) or intentionally superseded policy checks (4).
