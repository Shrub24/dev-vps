## 1. Runtime and Service Boundary

- [x] 1.1 Define a pinned declarative OCI runtime path for Bifrost suitable for `oci-melb-1`
- [x] 1.2 Create a thin local Bifrost service wrapper module that exposes repo-owned options for file-driven mode, persistence, rendered config, and downstream endpoint defaults
- [x] 1.3 Choose the first deployment host and wire the wrapper into host composition without exposing UI-managed config-store mode as baseline behavior

## 2. Canonical Config and Secrets

- [x] 2.1 Render canonical Bifrost `config.json` declaratively from repo-owned settings with `config_store` disabled in baseline mode
- [x] 2.2 Add host-scoped SOPS secret declarations/templates for provider credentials and render an environment file consumed by the gateway service
- [x] 2.3 Define explicit persistence paths for non-canonical runtime state such as logs, cache, or optional vector data without treating those stores as configuration truth

## 3. Routing Contract and Consumer Integration

- [x] 3.1 Define repo-owned model/provider alias structure for text, image or multimodal, embedding, and fallback routing behind one OpenAI-compatible endpoint
- [x] 3.2 Wire at least one downstream consumer pattern to the gateway contract to validate that the endpoint abstraction works for real app settings
- [x] 3.3 Document the operational posture, including why UI/config-store mode is out of baseline scope and what would require a future hybrid-control change

## 4. Validation and OpenSpec Coherence

- [x] 4.1 Run targeted Nix evaluation/build checks to confirm OCI runtime wiring, wrapper-module rendering, and host configuration compile cleanly on the chosen target system
- [x] 4.2 Validate secret/template rendering and confirm canonical gateway config does not embed live provider secrets
- [x] 4.3 Run `openspec validate --strict add-declarative-bifrost-gateway` and keep proposal/design/specs/tasks aligned with the implemented operating mode

## 5. Runtime Permission Bugfix Extension

- [x] 5.1 Align Bifrost OCI app-dir ownership and writable subdirectory layout with the container's UID/GID expectations so `/app/data` can initialize successfully on `oci-melb-1`

## 6. Runtime Bind Contract Extension (OCI entrypoint)

- [x] 6.1 Align Bifrost OCI runtime wiring with the image's `APP_*` entrypoint contract so configured host/port settings are honored and the service binds on the declared host port
