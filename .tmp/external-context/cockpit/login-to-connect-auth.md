---
source: Context7 API
library: Cockpit
package: cockpit
topic: login-to-connect-auth
fetched: 2026-04-24T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/man/pages/cockpit.conf.5.adoc
---

## [WebService] `LoginTo`
- Official man page section: `cockpit.conf(5) > WebService > LoginTo/AllowMultiHost`
- Behavior: controls whether users can log into other servers from the login screen.
- Recommended setting when Cockpit is exposed to the public internet and can reach private hosts: `LoginTo = false`
- Related setting: `AllowMultiHost` enables multiple servers in one session and should only be enabled for fully trusted hosts.

## Connect-to remote login
- Cockpit supports password-based authentication for remote login.
- SSH server requirement: password auth must be enabled on the target SSH server.
- For local Cockpit auth, docs show enabling password auth only on `127.0.0.1,::1` in `sshd_config`.

## Recommended value to keep Connect-to editable
- Keep `LoginTo = false` if you want to prevent arbitrary host login from the login screen.
- Do **not** enable `AllowMultiHost` unless all hosts are trusted.

## Official source URLs
- `cockpit.conf(5)`: https://github.com/cockpit-project/cockpit/blob/main/doc/man/pages/cockpit.conf.5.adoc
- Authentication guide: https://github.com/cockpit-project/cockpit/blob/main/doc/guide/pages/authentication.adoc
- Authentication details: https://github.com/cockpit-project/cockpit/blob/main/doc/authentication.md
- Password auth for localhost support: https://github.com/cockpit-project/cockpit/blob/main/containers/ws/README.md
