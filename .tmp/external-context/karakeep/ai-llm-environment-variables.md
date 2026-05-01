---
source: Official docs
library: Karakeep
package: karakeep
topic: ai-llm-environment-variables
fetched: 2026-05-01T00:00:00Z
official_docs: https://docs.karakeep.app/configuration/environment-variables/
---

# Karakeep AI / LLM environment variables

## AI-related env vars

| Env var | Purpose | Default / Notes |
|---|---|---|
| `OPENAI_API_KEY` | Enables automatic tagging via an OpenAI-compatible inference provider. | Required for OpenAI-based inference; otherwise tagging is skipped unless `OLLAMA_BASE_URL` is set. |
| `OPENAI_BASE_URL` | Points Karakeep at a non-OpenAI OpenAI-compatible API (for example Azure OpenAI). | Not needed for standard OpenAI. |
| `OPENAI_PROXY_URL` | HTTP proxy for OpenAI API requests. | Optional. |
| `OPENAI_SERVICE_TIER` | OpenAI service tier (`auto`, `default`, `flex`). | Optional. |
| `OLLAMA_BASE_URL` | Local Ollama API endpoint for inference. | Enables local inference/tagging. |
| `OLLAMA_KEEP_ALIVE` | How long Ollama keeps the model loaded. | Optional; e.g. `5m`, `-1m`, `0`. |
| `INFERENCE_TEXT_MODEL` | Model used for text inference. | Default: `gpt-4.1-mini`. |
| `INFERENCE_IMAGE_MODEL` | Model used for image inference. | Default: `gpt-4o-mini`. Must support vision if using Ollama. |
| `EMBEDDING_TEXT_MODEL` | Model used for text embeddings. | Default: `text-embedding-3-small`. |
| `INFERENCE_CONTEXT_LENGTH` | Max tokens sent to inference. | Default: `2048`. |
| `INFERENCE_MAX_OUTPUT_TOKENS` | Max generated tokens for AI output. | Default: `2048`. |
| `INFERENCE_USE_MAX_COMPLETION_TOKENS` | Use newer OpenAI `max_completion_tokens` parameter. | OpenAI-only; for GPT-5/o-series. |
| `INFERENCE_LANG` | Language for generated tags. | Default: `english`. |
| `INFERENCE_NUM_WORKERS` | Concurrency for AI inference jobs. | Default: `1`. |
| `INFERENCE_ENABLE_AUTO_TAGGING` | Enables/disables automatic tagging. | Default: `true`. |
| `INFERENCE_ENABLE_AUTO_SUMMARIZATION` | Enables/disables automatic summarization. | Default: `false`. |
| `INFERENCE_JOB_TIMEOUT_SEC` | Timeout for inference jobs. | Default: `30`. |
| `INFERENCE_FETCH_TIMEOUT_SEC` | Ollama fetch timeout. | Ollama-only; default `300`. |
| `INFERENCE_SUPPORTS_STRUCTURED_OUTPUT` | Deprecated structured-output toggle. | Use `INFERENCE_OUTPUT_SCHEMA` instead. |
| `INFERENCE_OUTPUT_SCHEMA` | Output format (`structured`, `json`, `plain`). | Default: `structured`. |
| `OCR_USE_LLM` | Use the inference model for OCR instead of Tesseract. | Falls back to Tesseract if no inference provider is configured. |

## What Karakeep AI is used for

- **Automatic tagging**: primary AI feature.
- **Automatic summarization**: optional, disabled by default.
- **LLM-based OCR**: optional replacement for Tesseract OCR.
- **Embeddings**: via `EMBEDDING_TEXT_MODEL`.

## Model routing behavior

Karakeep does **not** appear to use separate provider endpoints per task. Instead:

- One inference provider is configured through either `OPENAI_API_KEY` / `OPENAI_BASE_URL` or `OLLAMA_BASE_URL`.
- Within that provider, Karakeep routes tasks by model variable:
  - `INFERENCE_TEXT_MODEL` for text tasks
  - `INFERENCE_IMAGE_MODEL` for image / vision tasks
  - `EMBEDDING_TEXT_MODEL` for embeddings
- OCR can optionally reuse the same inference provider when `OCR_USE_LLM=true`.

## Practical notes

- Automatic tagging is enabled if either `OPENAI_API_KEY` or `OLLAMA_BASE_URL` is set.
- If using Ollama, choose models that support the required modality (text or vision).
- If your model does not support structured outputs, switch `INFERENCE_OUTPUT_SCHEMA` to `json` or `plain`.

## Relevant docs

- Official env var reference: https://docs.karakeep.app/configuration/environment-variables/
- AI provider configuration: https://docs.karakeep.app/configuration/different-ai-providers/
- OpenAI admin docs: https://docs.karakeep.app/administration/openai/
