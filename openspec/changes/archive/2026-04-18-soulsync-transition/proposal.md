## Why

The current automated ingest path is beets-inbox-centric and album-oriented, which creates friction for DJ-style workflows (singles, promos, partial releases, and selected cuts) and limits source/metadata flexibility. We need to transition to a SoulSync-primary pipeline now so `oci-melb-1` keeps the same stable media/storage contract while improving day-to-day ingest quality and operator UX.

**Core Value:** Keep fleet media operations reproducible and low-complexity by preserving the existing `/srv/media` contract and edge-access model, while upgrading ingest behavior to better match real-world music workflows.

## What Changes

- Replace `beets-inbox` as the primary automated ingest pipeline with SoulSync on `oci-melb-1`.
- Keep beets installed as fallback/rescue tooling, but remove it from the default automated promotion path.
- Preserve the existing canonical media paths and roles:
  - `/srv/media/inbox/slskd` (download landing)
  - `/srv/media/library` (canonical organized library)
  - `/srv/media/quarantine/untagged` (unresolved review lane)
  - `/srv/media/quarantine/approved` (fallback handoff lane)
- Use SoulSync as the preferred final promotion flow from approved rescue material into library.
- Add SoulSync as a public, Cloudflare Access-gated service on the existing `do-admin-1` edge route model (`tailscale-upstream`, AOP enabled).
- Keep day-1 public posture as control-plane/UI-first with best-effort playback suppression where practical.
- Keep initial rollout conservative: SoulSync can read existing library context but must not run broad mutation jobs over pre-existing library content.
- Support day-1 provider wiring for slskd, Discogs, Spotify (URLs + OAuth), Deezer, YouTube, and Navidrome sync, with optional enablement only when credentials/config are present.

## Capabilities

### New Capabilities
- `soulsync-ingest`: Introduce SoulSync as the primary music ingest service (containerized, path-mapped to existing media contract), including import/staging, metadata enrichment flow, and promotion into canonical library.

### Modified Capabilities
- `media-services`: Change media application composition and behavior to make SoulSync primary, refine Navidrome scope to `library + quarantine` (exclude inbox), and preserve Syncthing scope expectations.
- `beets-automation`: Change requirements so beets is fallback/rescue tooling rather than the default automated ingest/promotion backend.
- `edge-proxy-ingress`: Add a new Access-gated public route for SoulSync through the established `do-admin-1` edge model (`tailscale-upstream`, AOP).
- `secrets-management`: Add/adjust host-scoped secret requirements and template rendering for SoulSync service/provider credentials.

## Impact

- **Affected code/systems**
  - `modules/services/` (new SoulSync module; beets role reduced)
  - `modules/applications/music.nix` (composition and defaults)
  - `hosts/oci-melb-1/default.nix` (SoulSync secrets/templates)
  - `policy/web-services.nix` and `hosts/do-admin-1/default.nix` (new SoulSync route)
  - docs/decision records describing canonical ingest flow
- **Operational impact**
  - Primary ingest operations move from beets-inbox jobs to SoulSync UI/pipeline
  - Fallback remains available via beets rescue flow without day-1 automated fallback jobs
- **Security/network impact**
  - Public exposure remains aligned with existing guarded edge pattern (Cloudflare Access + AOP + private upstream)
  - No direct-origin public exposure on `oci-melb-1`
- **Risk boundaries**
  - Preserve existing filesystem contract and quarantine semantics
  - Defer any future automated beets fallback policy to a later explicit decision
