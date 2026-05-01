## Why

The current Bifrost baseline on `oci-melb-1` proves the gateway works, but its provider/model configuration is still effectively hardcoded to a single OpenAI provider path. We want a more general provider configuration contract now so downstream apps can keep one stable OpenAI-compatible endpoint while the repo chooses which providers and model IDs back text, image or multimodal, embedding, and fallback behavior.

For this first generalization wave, we want the structure to be broader than one provider while only adding concrete credentials for **Google** and **DeepSeek**.

**Core Value:** Turn the Bifrost configuration from a one-provider bootstrap into a repo-owned multi-provider gateway contract with stable aliases, host-scoped env-backed secrets, and an exact literal `bifrost-config.json` policy source under Git/Nix control.

## What Changes

- Generalize the canonical AI gateway policy shape so aliases and provider-backed model routing are expressed through a repo-owned literal `policy/bifrost-config.json` rather than one hardcoded OpenAI-only mapping.
- Update `oci-melb-1` Bifrost rendering to support multiple providers declaratively, with Google and DeepSeek added as the first non-OpenAI concrete providers.
- Extend host-scoped Bifrost secret templates and env-file rendering so provider API keys remain env-backed and host-local.
- Keep downstream consumer integration stable by preserving one OpenAI-compatible endpoint and stable alias names for apps like Karakeep.

## Capabilities

### Modified Capabilities
- `ai-gateway`: Generalize provider/model routing so one gateway endpoint can expose stable aliases backed by multiple configured providers.
- `secrets-management`: Extend host-scoped gateway provider secret handling for multiple provider credentials without promoting them to shared scope.

## Impact

- **Affected code**: `policy/bifrost-config.json`, `policy/globals.nix`, `hosts/oci-melb-1/default.nix`, `hosts/oci-melb-1/secrets.template.yaml`, `modules/services/bifrost-gateway.nix`, and OpenSpec artifacts/specs.
- **Operational impact**: `oci-melb-1` gains a more maintainable Bifrost config model that can add providers without rewriting downstream app contracts.
- **Security impact**: New provider credentials remain host-scoped and env-backed; committed gateway config continues to avoid live secret values.
- **Initial provider scope**: Add Google and DeepSeek API-backed provider entries now, while keeping the structure general for future providers.
