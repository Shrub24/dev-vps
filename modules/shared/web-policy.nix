{
  lib,
  config,
  ...
}:
let
  policyLib = import ../../lib/policy.nix { inherit lib; };
  webServicesPolicy = import ../../policy/web-services.nix;
  currentHostName = config.networking.hostName or null;
  resolvedHosts = lib.mapAttrs (
    hostName: _host:
    {
      primaryDomain = policyLib.resolvePrimaryDomain webServicesPolicy hostName;
      services = policyLib.resolveHostServices webServicesPolicy hostName;
      cloudflare.hosts = policyLib.resolveCloudflareHosts webServicesPolicy hostName;
    }
  ) (webServicesPolicy.hosts or { });
in
{
  options.repo.web = {
    hosts = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Resolved web-services policy for all hosts.";
    };

    currentHost = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Resolved web-services policy for the current host.";
    };
  };

  config.repo.web = {
    hosts = resolvedHosts;
    currentHost =
      if currentHostName != null && builtins.hasAttr currentHostName resolvedHosts then
        resolvedHosts.${currentHostName}
      else
        { };
  };
}
