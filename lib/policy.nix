{ lib }:
rec {
  mergeDefaults =
    globalDefaults: hostDefaults: serviceCfg:
    lib.recursiveUpdate (lib.recursiveUpdate globalDefaults hostDefaults) serviceCfg;

  mkUpstream =
    resolved: "${resolved.origin.scheme}://${resolved.origin.host}:${toString resolved.origin.port}";

  resolveHostServices =
    policy: hostName:
    let
      host = policy.hosts.${hostName} or (throw "Unknown host '${hostName}' in policy/web-services.nix");
      globalDefaults = policy.defaults or { };
      hostDefaults = host.defaults or { };
      services = host.services or { };
    in
    lib.mapAttrs (
      serviceName: serviceCfg:
      let
        resolved = mergeDefaults globalDefaults hostDefaults serviceCfg;
      in
      resolved
      // {
        service = serviceName;
        upstream = mkUpstream resolved;
      }
    ) services;

  exportHostJson = policy: hostName: builtins.toJSON (resolveHostServices policy hostName);

  hostPorts =
    policy: hostName: lib.mapAttrs (_: svc: svc.origin.port) (resolveHostServices policy hostName);
}
