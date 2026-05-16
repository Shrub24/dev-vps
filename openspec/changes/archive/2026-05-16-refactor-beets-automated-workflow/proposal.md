## Why

The Beets workflow has evolved beyond the current spec and module shape: we now need a clearly defined automated inbox path, an interactive quarantine review path, and a reusable Beets runner framework that separates generic execution scaffolding from music-specific workflow policy. Capturing this now prevents drift between implementation and intended operations, especially as metadata sources and conversion/reconciliation stages expand.

## What Changes

- Refactor the Beets service layer into a dedicated `modules/services/beets/` boundary that provides reusable runner, timer, config, trigger, hook, and service scaffolding rather than owning music workflow policy directly.
- Make `modules/applications/music.nix` authoritative for concrete Beets workflow composition, including stage semantics, config ownership, and which runner instances are enabled.
- Define a runner instance as a generated Beets systemd unit built from a built-in runner kind, with defaulted-but-overridable args/config plus optional triggers and pre/post command hooks.
- Formalize distinct processing modes:
  - headless automated inbox processing,
  - interactive quarantine/untagged review,
  - approved-to-library promotion,
  - reconciliation and conversion maintenance flows.
- Standardize Beets config variants and plugin policy for the current metadata strategy (Bandcamp/Discogs/Spotify/Deezer; no MusicBrainz dependency in this workflow), with config material living under `modules/applications/music/files/` rather than loose `scripts/` files.
- Limit the generic Beets framework to built-in runner kinds and typed hooks rather than arbitrary custom command runners.
- Define explicit secrets templating and rendered-path access expectations for Beets service units.

## Capabilities

### New Capabilities
- `beets-workflow-stages`: Define stage contracts (inbox, quarantine, approved, reconcile/convert) and operator invocation model.

### Modified Capabilities
- `beets-automation`: Update requirements to reflect the new stage model, interactive quarantine flow, deterministic duplicate handling behavior by stage, reusable runner framework boundaries, and explicit secrets/rendered-path access guarantees.

## Impact

- Affected code: `modules/services/beets/`, `modules/applications/music.nix`, `modules/applications/music/files/`, and related runner/package exports.
- Affected operations: service invocation patterns, manual review workflow over SSH TTY, reconcile/convert maintenance execution.
- Affected secrets: Beets template placeholders and service filesystem access to rendered secret templates.
