---
source: official docs
library: gethomepage/homepage
package: homepage
topic: credential security cautions
fetched: 2026-04-23T00:00:00Z
official_docs: https://gethomepage.dev/widgets/services/customapi/
---

## Security cautions

From the official docs:

- `customapi` supports inline `username`, `password`, and `headers` values.
- `iframe` requests are not proxied and run in the browser.

## Implications

- Treat Homepage configs as sensitive if they contain API keys, passwords, or auth headers.
- Prefer read-only service accounts or scoped API keys.
- Keep secrets out of public repositories and restrict access to the config store.
- If possible, place secret values in a secret manager or env/secrets mechanism rather than plain YAML.

## Caveat

The docs do not provide a dedicated secret-hygiene model for every widget, so secure storage is an operational concern you must enforce yourself.