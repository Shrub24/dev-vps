{ lib, ... }:
{
  services.resolved.enable = true;

  # Keep cloud-init for metadata only; systemd-networkd owns host networking.
  services.cloud-init.network.enable = false;

  networking.useDHCP = lib.mkForce false;
  networking.dhcpcd.enable = lib.mkForce false;
  systemd.network.enable = true;

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens3";
    address = [
      "10.16.0.5/16"
      "157.245.43.175/20"
    ];
    gateway = [ "157.245.32.1" ];
    networkConfig = {
      DHCP = "no";
      IgnoreCarrierLoss = "3s";
    };
  };

  systemd.network.networks."20-vpc" = {
    matchConfig.Name = "ens4";
    address = [ "10.106.0.2/20" ];
    networkConfig = {
      DHCP = "no";
      IgnoreCarrierLoss = "3s";
    };
  };

  system.activationScripts.doAdminNetworkCleanup.text = ''
    rm -f /etc/systemd/network/10-cloud-init-ens3.network
    rm -f /etc/systemd/network/10-cloud-init-ens4.network
  '';

  networking.firewall.trustedInterfaces = lib.mkAfter [
    "podman0"
    "cni-podman0"
  ];

  networking.nat = {
    enable = true;
    externalInterface = "ens3";
    internalInterfaces = [
      "podman0"
      "cni-podman0"
    ];
  };

  # Split DNS for Termix container traffic:
  # - tailnet names route to Tailscale MagicDNS
  # - everything else routes to public resolvers
  services.dnsmasq = {
    enable = true;
    settings = {
      no-resolv = true;
      server = [
        "/tail0fe19b.ts.net/100.100.100.100"
        "1.1.1.1"
        "8.8.8.8"
      ];
      "listen-address" = [
        "127.0.0.1"
        "10.88.0.1"
      ];
      "bind-dynamic" = true;
      "cache-size" = 1000;
    };
  };

  networking.nameservers = [
    "67.207.67.3"
    "67.207.67.2"
    "1.1.1.1"
    "8.8.8.8"
  ];
}
