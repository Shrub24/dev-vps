---
source: Context7 API
library: Kanidm
package: kanidm
topic: web-ui-vs-cli-identity-management
fetched: 2026-05-03T00:00:00Z
official_docs: https://github.com/kanidm/kanidm/tree/master/book
---

## Practical answer

Kanidm is **not** “fully managed in the web UI” for identity administration.

### Web UI is mainly for
- **Self-service / end-user actions**
- Viewing account info and completing user-facing flows
- Some application portal interactions tied to user access

### Use `kanidm` CLI / API for
- **Creating and managing users/person accounts**
- **Creating and managing groups**
- **Creating and configuring OAuth2/OIDC clients/resources**
- Delegated admin tasks and bulk/automatable provisioning

## Authoritative signals from docs
- People account lifecycle is documented as `kanidm person create ...`.
- Group lifecycle is documented as `kanidm group create/add-members/delete ...`.
- OAuth2 client setup is documented via `kanidm system oauth2 create ...`, `create-public`, `add-redirect-url`, and scope/claim mapping commands.
- Kanidm docs describe a **REST API**, **administrative CLI tools**, a **Python client library**, and a **web UI for self-service**.

## Operator guidance
For a homelab operator:
- Put **repeatable identity provisioning** in CLI/API or declarative automation.
- Reserve the **web UI** for self-service and light interactive tasks.
- Treat users/groups/OAuth2 app registration as **admin/tooling-managed**, not primarily web-UI managed.

## Official docs links
- Kanidm docs/book: https://github.com/kanidm/kanidm/tree/master/book
- People accounts: https://github.com/kanidm/kanidm/blob/master/book/src/accounts/people_accounts.md
- Groups / CLI examples: https://context7.com/kanidm/kanidm/llms.txt
- OAuth2 integration docs: https://github.com/kanidm/kanidm/blob/master/book/src/integrations/oauth2.md
- OAuth2 examples: https://github.com/kanidm/kanidm/blob/master/book/src/integrations/oauth2/examples.md
