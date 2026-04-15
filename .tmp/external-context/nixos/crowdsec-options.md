---
source: NixOS module source
library: nixos
package: nixpkgs
topic: crowdsec options
fetched: 2026-04-15T00:00:00Z
official_docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/security/crowdsec.nix
---

## Required fields
- `services.crowdsec.enable = true`
- At least one acquisition under `services.crowdsec.localConfig.acquisitions`
- At least one remediation profile under `services.crowdsec.localConfig.profiles`

## Minimal config snippet
```nix
{
  services.crowdsec = {
    enable = true;

    localConfig = {
      acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
      ];

      profiles = [
        {
          name = "default_ip_remediation";
          filters = [ "Alert.Remediation == true && Alert.GetScope() == 'Ip'" ];
          decisions = [ { type = "ban"; duration = "4h"; } ];
          on_success = "break";
        }
      ];
    };
  };
}
```

## Caveats
- The module defaults `crowdsec_service.enable = true` and writes acquisition YAML from `localConfig.acquisitions`.
- `services.crowdsec.localConfig.profiles` defaults to IP and range remediation profiles; overriding it with `[]` disables action on alerts.
- `services.crowdsec.localConfig.acquisitions = []` means CrowdSec will not read any source.
- `services.crowdsec.openFirewall` is optional; default is `false`.
- Journal access depends on the `crowdsec` user being in `systemd-journal`, but `PrivateUsers=true` is set on the service in nixpkgs 25.11; journal acquisition can silently fail in some setups.
