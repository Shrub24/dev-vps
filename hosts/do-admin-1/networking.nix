{ lib, ... }:
{
  services.resolved.enable = true;

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
    "1.1.1.1"
    "8.8.8.8"
  ];
}
