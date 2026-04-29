---
source: Context7 API
library: Cockpit
package: cockpit
topic: login connect to field remote host authentication reverse proxy origin
fetched: 2026-04-24T00:00:00Z
official_docs: https://github.com/cockpit-project/cockpit/blob/main/doc/authentication.md
---

## Relevant findings

- Remote logins can be done by visiting `https://server:9090/=hostname` or by entering the hostname in the login page’s **Connect to** field.
- The login request includes the user/password plus `known_hosts` data stored in browser localStorage.
- `cockpit-ws` reads the target host from the URL and uses `[Ssh-Login]` `Command` or `UnixPath` from `cockpit.conf`; default is `cockpit.beiboot`.
- SSH password auth can be used for remote login flows; docs show enabling `PasswordAuthentication yes` on the remote SSH server.
- Kerberos login requires a valid client Kerberos ticket and browser configuration allowing Kerberos for the domain.
- SSH private keys can be configured per-host or globally via `COCKPIT_SSH_KEY_PATH_*` / `COCKPIT_SSH_KEY_PATH`.
- For reverse proxies, Cockpit requires WebSocket upgrade handling, correct `Host` and `X-Forwarded-Proto` headers, and `proxy_buffering off`.

## Notes on your questions

1. **[WebService] LoginTo**: I did not find a direct doc snippet for `[WebService] LoginTo` in the retrieved Context7 text; the login-page field is described as accepting a hostname and feeding the SSH remote login flow.
2. **Auto-populated vs typed**: The docs imply the user enters/specifies the hostname in the login page; no auto-population behavior was documented in the retrieved snippets.
3. **Auth methods**: Passwords, Kerberos, and SSH key-based flows are documented; password-based SSH on the remote host must be enabled for password login.
4. **Reverse proxies/origins**: Cockpit behind a proxy needs WebSocket upgrades and proper forwarding headers; origin-specific constraints were not explicit in the retrieved snippets beyond correct proxy headers.
