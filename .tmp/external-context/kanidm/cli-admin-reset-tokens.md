---
source: Context7 API
library: Kanidm
package: kanidm
topic: cli-admin-reset-tokens
fetched: 2026-05-03T00:00:00Z
official_docs: https://github.com/kanidm/kanidm/blob/master/book/src/accounts/authentication_and_credentials.md
---

## OIDC / LDAP sequencing

Kanidm documents LDAP as a separate integration layer from OIDC/OAuth2. The LDAP docs expose `kanidm system domain set-ldap-basedn` and `set-ldap-allow-unix-password-bind`, and the design docs describe Kanidm as supporting:

- modern OAuth2/OIDC for web apps
- a separate HTTPS channel for Linux/UNIX integration
- an LDAPS gateway for legacy apps

Repo-relevant reading: if you are already on the OIDC path and have not yet committed to legacy LDAP consumers, LDAP can be deferred until a real consumer needs it. The docs do not present LDAP as a prerequisite for the OIDC phase.

## Reset / setup token commands

Password reset token:

```bash
kanidm person credential create-reset-token <account_id> [<time to live in seconds>]
```

Examples:

```bash
kanidm person credential create-reset-token demo_user --name idm_admin
kanidm person credential create-reset-token demo_user 86400 --name idm_admin
```

The token max TTL is 24 hours.

Credential update intent token / self-service flow:

```bash
kanidm person credential-update-intent demo_user --name idm_admin
kanidm person credential-update-intent demo_user --ttl 3600 --name idm_admin
kanidm person credential-update-intent-send demo_user --email user@example.com --name idm_admin
kanidm person credential-update demo_user --name demo_user
```

User consumption of reset token:

```bash
kanidm person credential use-reset-token 8qDRG-AE1qC-zjjAT-0Fkd6
```

## CLI identity / execution notes

Documented usage shows the CLI authenticates as a named identity via `--name` or `-D`, e.g.:

```bash
kanidm login --name idm_admin
kanidm login -D idm_admin
```

The docs do not require the CLI to be executed as the system user `kanidm`. The important part is running the client with the right config and authenticating as an admin identity. On NixOS, the practical caveat is that the `kanidm` binary must be installed in PATH for the invoking user (system package, shell profile, or explicit package invocation), and the client config must point at the server URI and CA.

Client config example:

```bash
uri = "https://idm.example.com"
ca_path = "/path/to/ca.pem"
```

Fallback install path noted in the docs:

```bash
docker run --rm -i -t ... kanidm/tools:latest /sbin/kanidm --help
```
