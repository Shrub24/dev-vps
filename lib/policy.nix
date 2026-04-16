{ lib }:
rec {
  hostPolicy =
    policy: hostName:
    policy.hosts.${hostName} or (throw "Unknown host '${hostName}' in policy/web-services.nix");

  resolvePrimaryDomain =
    policy: hostName:
    let
      host = hostPolicy policy hostName;
      defaults = policy.defaults or { };
      hostDefaults = host.defaults or { };
    in
    hostDefaults.primaryDomain or defaults.primaryDomain
      or (throw "Missing primaryDomain for host '${hostName}' in policy/web-services.nix");

  mergeDefaults =
    globalDefaults: hostDefaults: serviceCfg:
    lib.recursiveUpdate (lib.recursiveUpdate globalDefaults hostDefaults) serviceCfg;

  mkUpstream =
    resolved: "${resolved.origin.scheme}://${resolved.origin.host}:${toString resolved.origin.port}";

  mkPublicHost =
    primaryDomain: resolved:
    if resolved.subdomain != null then "${resolved.subdomain}.${primaryDomain}" else primaryDomain;

  resolveHostServices =
    policy: hostName:
    let
      host = hostPolicy policy hostName;
      globalDefaults = policy.defaults or { };
      hostDefaults = host.defaults or { };
      services = host.services or { };
      primaryDomain = resolvePrimaryDomain policy hostName;

      mkPublicUrl =
        resolved:
        let
          base = "https://${mkPublicHost primaryDomain resolved}";
        in
        if resolved.path == "/" then base else "${base}${resolved.path}";

      mkHealthUrl = resolved: "${mkUpstream resolved}${resolved.health.path}";
    in
    lib.mapAttrs (
      serviceName: serviceCfg:
      let
        resolved = mergeDefaults globalDefaults hostDefaults serviceCfg;
      in
      resolved
      // {
        service = serviceName;
        inherit primaryDomain;
        publicHost = mkPublicHost primaryDomain resolved;
        upstream = mkUpstream resolved;
        publicUrl = mkPublicUrl resolved;
        healthUrl = mkHealthUrl resolved;
      }
    ) services;

  hostService =
    policy: hostName: serviceName:
    let
      services = resolveHostServices policy hostName;
    in
    services.${serviceName}
      or (throw "Unknown service '${serviceName}' for host '${hostName}' in policy/web-services.nix");

  exportHostJson = policy: hostName: builtins.toJSON (resolveHostServices policy hostName);

  hostPorts =
    policy: hostName: lib.mapAttrs (_: svc: svc.origin.port) (resolveHostServices policy hostName);
}
