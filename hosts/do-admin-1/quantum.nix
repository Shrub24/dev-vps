{ config, ... }:
{
  services.admin.quantum = {
    enable = true;
    environmentFile = config.sops.templates."quantum-auth.env".path;
    oidc.enabled = true;
    managedSourceEnabled = false;

    localSources = [
      {
        name = "do-admin-1";
        path = "/srv/data";
      }
    ];

    sftp = {
      identityFile = "/run/secrets/admin.ssh.identity";
      knownHostsFile = "/run/secrets/admin.ssh.known_hosts";
      hosts = [
        {
          name = "oci-melb-1";
          host = "oci-melb-1.tail0fe19b.ts.net";
          user = "dev";
          remotePath = "/srv";
          readOnly = false;
        }
        {
          name = "arch-root";
          host = "arch";
          user = "saurabhj";
          remotePath = "/";
          readOnly = true;
        }
      ];
    };
  };
}
