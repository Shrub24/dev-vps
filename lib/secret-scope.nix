{
  lib,
}:

/*
  Canonical secret-to-host reader mapping.

  This is the SSOT for which hosts should be able to decrypt
  each secret scope. The mapping is derived from host feature
  enablement except for the explicit exception map below.

  In steady state this mapping should be kept in sync with
  `.sops.yaml` path rules. The validation script
  `lib/check-secret-scope.sh` compares them.
*/
let
  hostFeatures = {
    "oci-melb-1" = [
      "music" # applications.music
      "edge-ingress" # applications.edge-ingress
      "karakeep-pod" # services.karakeep-pod
      "bifrost-gateway" # services.bifrost-gateway
    ];
    "do-admin-1" = [
      "admin" # applications.admin
      "edge-ingress" # applications.edge-ingress
    ];
  };

  # Compute expected readers for each secret scope
  expectedReaders = {
    # Application scopes — readers are hosts that enable the feature
    "applications/music" = builtins.filter (
      host:
      builtins.elem "music" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "applications/admin" = builtins.filter (
      host:
      builtins.elem "admin" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "applications/edge-ingress" = builtins.filter (
      host:
      builtins.elem "edge-ingress" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);

    # Service scopes
    "services/karakeep-pod" = builtins.filter (
      host:
      builtins.elem "karakeep-pod" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "services/bifrost-gateway" = builtins.filter (
      host:
      builtins.elem "bifrost-gateway" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);

    # Host exception scopes — system: host only
    "hosts/oci-melb-1/system" = [ "oci-melb-1" ];
    "hosts/do-admin-1/system" = [ "do-admin-1" ];

    # Host exception scopes — OIDC: host + peer (explicit exception map)
    "hosts/oci-melb-1/oidc" = [
      "oci-melb-1"
      "do-admin-1"
    ];
    "hosts/do-admin-1/oidc" = [
      "do-admin-1"
      "oci-melb-1"
    ];
  };
in
expectedReaders
