---
source: GitHub issue
url: https://github.com/cockpit-project/cockpit/issues/20914
topic: cockpit-ws-user.service dependency loop
fetched: 2026-04-23T00:00:00Z
---

- Issue reports `cockpit-ws-user.service` entering an ordering/dependency loop on reboot after login, with `basic.target` involved in the stop cycle.
- The issue author observed that `systemctl show -p Before,After cockpit-ws-user.service` included `After=... basic.target`.
- Suggested workaround: remove default dependencies (`DefaultDependencies=no`) from `cockpit-ws-user.service`.
- Why: the `After=basic.target` dependency makes stop/start ordering interact badly with shutdown, producing a cycle around `basic.target/stop`, `sockets.target/stop`, and `cockpit-wsinstance-https-factory.socket/stop`.
- Actionable takeaway: avoid letting this user-session unit inherit the normal `basic.target` default ordering; the stop cycle is the symptom of that dependency chain.

Reference: https://github.com/cockpit-project/cockpit/issues/20914