# Phase 1: Repository Cutover - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md`; this log preserves alternatives considered.

**Date:** 2026-03-21
**Phase:** 01-repository-cutover
**Areas discussed:** Repo layout, Legacy asset policy, Docs authority

---

## Repo layout

| Option | Description | Selected |
|--------|-------------|----------|
| Full cutover | Introduce target fleet structure now and move active paths to it in this phase | Yes |
| Bridge layout | Keep a temporary hybrid between old and new structures | |
| Minimal rename | Make naming tweaks now and postpone structural migration | |

**User's choice:** Full cutover.
**Notes:** Host identity should live in `hosts/oci-melb-1`, reusable logic grouped under `modules/core`, `modules/profiles`, `modules/services`, and scaffolding should be only what is wired immediately.

---

## Legacy asset policy

| Option | Description | Selected |
|--------|-------------|----------|
| Remove from mainline | Remove legacy provider-specific and personal baseline wiring from active paths | Yes |
| Archive in-repo | Keep large legacy trees in active repo under archive folders | |
| Long dual-run | Maintain old and new paths concurrently for an extended period | |

**User's choice:** Remove from mainline.
**Notes:** Mostly keep history in git, not in-repo legacy trees. Drop broken legacy references (including missing `home/` and `pkgs/` references). Remove baseline dependence on personal-tooling concerns.

---

## Docs authority

| Option | Description | Selected |
|--------|-------------|----------|
| `docs/` canonical | Keep durable architecture and decisions in `docs/` | Yes |
| Split authority | Keep multiple equal sources (`README.md`, `.planning/`, generated files) | |
| Generated-first | Treat generated guidance as primary truth | |

**User's choice:** `docs/` canonical.
**Notes:** `README.md` should remain thin orientation; `CLAUDE.md` is a derived mirror; when conflicts appear, fix or archive immediately.

---

## the agent's Discretion

- Exact migration sequencing and commit slicing for structural moves.
- Internal naming details for submodules as long as host/module boundaries stay clear.
- Tactical cleanup ordering for non-canonical docs during cutover.

## Deferred Ideas

- Canonical naming area was presented but not selected for deep dive in this session.
