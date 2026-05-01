## 1. Gateway Policy Generalization

- [x] 1.1 Generalize the canonical AI gateway policy shape so alias roles and backing providers/models are expressed declaratively rather than as one hardcoded OpenAI-only mapping
- [x] 1.2 Preserve stable logical alias names for downstream consumers while making provider/model backing extensible

## 2. Host Rendering and Secrets

- [x] 2.1 Extend `oci-melb-1` Bifrost settings so multiple providers can be rendered declaratively in `config.json`
- [x] 2.2 Add Google and DeepSeek provider API keys to host-scoped Bifrost secret declarations and rendered environment file content
- [x] 2.3 Update `hosts/oci-melb-1/secrets.template.yaml` with placeholders for the new provider credentials

## 3. Consumer Compatibility and Validation

- [x] 3.1 Confirm downstream consumers such as Karakeep still point at one stable gateway URL and alias contract after the provider generalization
- [x] 3.2 Run targeted Nix evaluation checks to confirm rendered Bifrost settings and secret templates include the generalized provider structure without embedding live secrets
- [x] 3.3 Run `openspec validate --strict generalize-bifrost-provider-config` and keep proposal/design/specs/tasks aligned with the implemented behavior

## 4. Provider Shape Refinement Extension

- [x] 4.1 Remove the transitional OpenAI provider entry and centralize the concrete Bifrost provider `keys` structure directly in `policy/globals.nix` so `hosts/oci-melb-1/default.nix` can consume `providers = globals.aiGateway.providers` without per-provider host assembly

## 5. Exact Config and Dynamic Alias Extension

- [x] 5.1 Refactor the canonical AI gateway definition so `policy/globals.nix` owns an exact upstream-shaped `config.json` attrset rather than only partial provider fragments
- [x] 5.2 Replace provider-key-scoped alias hacks with documented global alias behavior under `governance.routing_rules`
- [x] 5.3 Restart the Bifrost OCI unit automatically when the rendered config or env file changes and revalidate the resulting runtime contract

## 6. Dedicated Policy File Extension

- [x] 6.1 Move the exact upstream-shaped AI gateway config into a dedicated policy file and keep host wiring consuming that file without rebuilding the schema shape inline

## 7. DeepSeek Provider-Specific Config Restoration

- [x] 7.1 Restore the DeepSeek `custom_provider_config` and `network_config.base_url` fields in the dedicated AI gateway policy file so provider-specific runtime behavior is preserved after the schema-shaped file split

## 8. Literal JSON Policy Source Extension

- [x] 8.1 Move the canonical Bifrost config into a checked-in literal `policy/bifrost-config.json` file so operators can inspect and schema-validate the exact runtime artifact directly
- [x] 8.2 Rewire the Bifrost module and host config to consume the literal policy file while preserving env-based secrets, restart-on-change behavior, and the currently tested Gemini/DeepSeek values

## 9. Governance Priority Fix Extension

- [x] 9.1 Assign explicit unique `priority` values to each global Bifrost routing rule in `policy/bifrost-config.json` so runtime governance sync does not fail on duplicate default priority `0`
