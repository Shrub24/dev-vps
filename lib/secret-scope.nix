{
  lib,
}:

let
  hostFeatures = {
    "oci-melb-1" = [
      "music"
      "edge-ingress"
      "karakeep-pod"
      "bifrost-gateway"
    ];
    "do-admin-1" = [
      "admin"
      "edge-ingress"
    ];
  };

  expectedReaders = {
    "applications/music" = builtins.filter (
      host: builtins.elem "music" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "applications/admin" = builtins.filter (
      host: builtins.elem "admin" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "applications/edge-ingress" = builtins.filter (
      host: builtins.elem "edge-ingress" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);

    "services/karakeep-pod" = builtins.filter (
      host: builtins.elem "karakeep-pod" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);
    "services/bifrost-gateway" = builtins.filter (
      host: builtins.elem "bifrost-gateway" hostFeatures.${host}
    ) (builtins.attrNames hostFeatures);

    "hosts/oci-melb-1/system" = [ "oci-melb-1" ];
    "hosts/do-admin-1/system" = [ "do-admin-1" ];

    "hosts/oci-melb-1/oidc" = [ "oci-melb-1" "do-admin-1" ];
    "hosts/do-admin-1/oidc" = [ "do-admin-1" "oci-melb-1" ];
  };
in
expectedReaders
