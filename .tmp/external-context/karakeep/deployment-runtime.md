---
source: official docs + Context7
library: Karakeep
package: karakeep
topic: deployment-runtime expectations
fetched: 2026-04-30T00:00:00Z
official_docs: https://docs.karakeep.app/installation/docker
---

## Concise findings

1. **Recommended deployment**: Docker / Docker Compose is the documented default installation path.
2. **Supporting services**: typical full deployment includes the web app, Meilisearch, and a Chrome browser container. The app also commonly uses an external AI provider (OpenAI or Ollama) for tagging; database/storage are embedded via the app/data volume.
3. **Compose as primary path**: yes — the official Docker install docs center on `docker compose up -d`, and the repo ships a compose file.
4. **Typical service count**: usually 3 containers in the default Docker compose setup (`web`, `chrome`, `meilisearch`), plus optional external AI/OCR/SMTP/OAuth services depending on features enabled.
5. **Env / secrets / persistence**: required env includes `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, `DATA_DIR`; search needs `MEILI_MASTER_KEY`; optional `OPENAI_API_KEY` or `OLLAMA_BASE_URL`. Persistence is via `/data` (db + assets by default) and a Meilisearch volume; S3 can replace local asset storage. Changes to env require restarting compose.
6. **Non-container guidance**: official docs also provide a minimal Docker run path, Kubernetes manifests, and a minimal-install mode; no first-class bare-metal/non-container runtime guide was found in the official docs reviewed.

## Source URLs
- https://docs.karakeep.app/Installation/docker
- https://docs.karakeep.app/configuration
- https://docs.karakeep.app/security-considerations
- https://docs.karakeep.app/installation/minimal-install
- https://docs.karakeep.app/installation/kubernetes
- https://github.com/karakeep-app/karakeep/blob/main/docker/docker-compose.yml
- https://github.com/karakeep-app/karakeep/blob/main/README.md
