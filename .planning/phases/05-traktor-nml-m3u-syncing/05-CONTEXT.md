# Phase 5: traktor nml m3u syncing - Context

**Gathered:** 2026-03-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Define and implement the Traktor NML/M3U synchronization behavior so Traktor-driven playlist updates are reflected into Navidrome-facing M3Us on the server, while allowing Navidrome-side M3U edits to be re-imported through Traktor's own import workflow.

</domain>

<decisions>
## Implementation Decisions

### Sync authority and direction
- **D-01:** Traktor is the final source of truth for collection and playlist state.
- **D-02:** Sync model is bounded bidirectional: Traktor -> Navidrome M3U generation on NML updates, plus Navidrome-edited M3U -> Traktor via Traktor import.
- **D-03:** There is no direct M3U-to-NML automation outside Traktor; Traktor import UI is the reconciliation point.
- **D-04:** Conflict handling defaults to Traktor winning, with merges resolved in Traktor during import/load workflow.

### Update behavior
- **D-05:** Playlist rename handling is recreate-style for downstream artifacts (old M3U removed/replaced by regenerated output).
- **D-06:** Generated Navidrome M3Us must mirror current Traktor playlist membership/order exactly.
- **D-07:** Deletion semantics during Navidrome -> Traktor path are decided by Traktor import behavior; pre-merge tooling is out of scope.
- **D-08:** No direct NML mutation/write-back by sync tooling.

### Matching and path handling
- **D-09:** Primary matching identity is file path.
- **D-10:** Path-base normalization/remap is owned by the selected bridge CLI/service configuration (set base path; avoid manual custom matching logic where tool-native behavior exists).
- **D-11:** Unresolved tracks should be kept as unresolved intent where possible and reported, not silently dropped.
- **D-12:** Duplicate/ambiguous match behavior should defer to bridge CLI defaults unless explicitly overridden later.

### Run mode and operations
- **D-13:** Sync runs on the server host.
- **D-14:** Automatic execution trigger is NML change detection after Syncthing delivers updates.
- **D-15:** Operator feedback must include structured logs and a last-run summary.
- **D-16:** Partial failures should continue processing other playlists and mark failed items for retry/report.

### the agent's Discretion
- Exact bridge CLI/tool selection and wrapper shape, as long as it honors Traktor-final authority and no direct NML mutation.
- Exact implementation of trigger mechanics (service/timer/path watcher/event glue) as long as it is NML-change driven on server host.
- Exact log schema and summary presentation format, as long as structured logs plus last-run status are provided.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and project constraints
- `.planning/ROADMAP.md` - Phase 5 boundary and dependency position.
- `.planning/PROJECT.md` - Core constraints: low complexity, single canonical data flow, private operations.
- `.planning/REQUIREMENTS.md` - Current requirement baseline and out-of-scope guardrails.
- `.planning/STATE.md` - Prior locked decisions, including `/srv/media` media authority and service-flow continuity.

### Existing media/service architecture
- `docs/architecture.md` - Current host/service composition and media path ownership model.
- `docs/decisions.md` - Prior decisions on media authority and service boundaries (`/srv/media` vs service-state paths).

### Active code integration surface
- `modules/services/syncthing.nix` - Syncthing media folder and authoritative path wiring.
- `modules/services/navidrome.nix` - Navidrome media/data folder expectations.
- `modules/services/slskd.nix` - Shared media/inbox path layout that must remain compatible.
- `modules/applications/music.nix` - Music application composition boundary.
- `tests/phase-04-service-flow-contract.sh` - Existing contract checks protecting service/media path invariants.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/applications/music.nix`: central composition point for music-related services; natural place to wire sync process ownership.
- `modules/services/syncthing.nix`: provides the NML-arrival side context through existing Syncthing-managed media path.
- Existing shell-based phase contract test style (`tests/phase-04-service-flow-contract.sh`) can be reused for sync behavior assertions.

### Established Patterns
- `/srv/media` is the authoritative shared media path.
- Service-state/config paths stay separate under `/srv/data`.
- Private/Tailscale-first operations and conservative blast-radius behavior are already established.

### Integration Points
- Trigger point: Syncthing-delivered NML updates landing on server storage.
- Processing point: server-host sync job/service that regenerates Navidrome-facing M3Us.
- Validation point: contract tests alongside existing phase service-flow checks.

</code_context>

<specifics>
## Specific Ideas

- Use a bridge CLI/service (example mentioned: Traktor bridge) for path/base mapping and matching behaviors where available.
- Workflow intent: mobile/on-the-go edits happen against Navidrome M3Us; Traktor import on launch/load performs final reconciliation.

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 05-traktor-nml-m3u-syncing*
*Context gathered: 2026-03-29*
