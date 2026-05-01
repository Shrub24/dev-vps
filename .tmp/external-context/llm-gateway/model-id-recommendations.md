---
source: official provider docs
scope: Bifrost/OpenAI-compatible gateway config
fetched: 2026-05-01T00:00:00Z
official_docs:
  - https://ai.google.dev/gemini-api/docs/models
  - https://api-docs.deepseek.com/quick_start/pricing
  - https://api-docs.deepseek.com/api/list-models
---

## Conservative model ID recommendations

### 1) Google text/default model
- **Recommended:** `gemini-2.5-flash`
- **Why:** Stable, documented Google text model; Google describes it as a best price-performance model for low-latency, high-volume reasoning tasks.
- **Confidence:** High

### 2) Google image or multimodal-capable model
- **Recommended:** `gemini-2.5-pro`
- **Why:** Documented as Google’s most advanced general model; Google also documents multimodal/image-related model families separately, and `Gemini 2.5 Pro` is the safest conservative multimodal-capable default among text models.
- **Alternate if you need image generation/editing specifically:** `imagen-4` or `nano-banana`
- **Confidence:** Medium for multimodal general use; High that `imagen-4`/`nano-banana` are documented image models

### 3) Google embedding model
- **Recommended:** `gemini-embedding-2`
- **Why:** Explicitly documented as Google’s first multimodal embedding model.
- **Confidence:** High

### 4) DeepSeek default chat/fallback model
- **Recommended:** `deepseek-v4-flash`
- **Why:** DeepSeek docs list it as the current model, and explicitly say `deepseek-chat` maps to the non-thinking mode of `deepseek-v4-flash` for compatibility.
- **Fallback alias:** `deepseek-chat` (compatibility alias, but deprecated later)
- **Confidence:** High

## Notes
- DeepSeek’s docs say `deepseek-chat` and `deepseek-reasoner` will be deprecated in favor of `deepseek-v4-flash` / `deepseek-v4-pro`.
- For a conservative gateway config, prefer versioned/current canonical IDs over legacy aliases.
- I did not find a concrete Bifrost-specific model-name override that was more authoritative than the provider docs in this pass.

## Official docs
- https://ai.google.dev/gemini-api/docs/models
- https://api-docs.deepseek.com/quick_start/pricing
- https://api-docs.deepseek.com/api/list-models
