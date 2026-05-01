---
source: Cockpit docs
library: Cockpit
package: cockpit
topic: ws-certs selection
fetched: 2026-04-28T00:00:00Z
official_docs: https://cockpit-project.org/guide/latest/
---
Relevant excerpts:
- Cockpit loads a certificate from /etc/cockpit/ws-certs.d (or below $XDG_CONFIG_DIRS) and uses the last .cert or .crt file in alphabetical order.
- The .cert file should contain OpenSSL-style BEGIN CERTIFICATE blocks; the private key must be in a separate .key file with the same basename, and the key must not be encrypted.
- If no cert is found, Cockpit generates 0-self-signed.cert.
- certmonger example uses 50-certmonger.cert with matching 50-certmonger.key.

Source: https://cockpit-project.org/guide/latest/
