{
  lib,
  config,
  ...
}:
let
  webServicesPolicy = import ../../policy/web-services.nix;
  policyLib = import ../../lib/policy.nix { inherit lib; };
  resolvedRoutes = policyLib.resolveHostServices webServicesPolicy "do-admin-1";
  edgeRoutes = lib.mapAttrs (_: svc: {
    inherit (svc)
      subdomain
      path
      exposureMode
      category
      stripPrefix
      declarePublic
      upstream
      ;
    cloudflareAccessRequired = svc.access.requireCloudflareAccess;
    authenticatedOriginPullsRequired = svc.cloudflare.authenticatedOriginPulls;
  }) resolvedRoutes;
in
{
  applications.admin.policyServices = resolvedRoutes;

  applications."edge-ingress" = {
    enable = true;
    role = "edge";
    primaryDomain = policyLib.resolvePrimaryDomain webServicesPolicy "do-admin-1";
    acmeEmail = "infra@${policyLib.resolvePrimaryDomain webServicesPolicy "do-admin-1"}";
    cloudflareCredentialsFile = config.sops.templates."caddy-cloudflare.env".path;
    authenticatedOriginPulls = {
      enable = true;
      caCertFile = toString ../../certs/authenticated_origin_pull_ca.pem;
    };
    routes = edgeRoutes;
  };
}
