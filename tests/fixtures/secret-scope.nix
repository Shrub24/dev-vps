{
  "applications/music" = [ "oci-melb-1" ];
  "applications/admin" = [ "do-admin-1" ];
  "applications/edge-ingress" = [ "oci-melb-1" "do-admin-1" ];

  "services/karakeep-pod" = [ "oci-melb-1" ];
  "services/bifrost-gateway" = [ "oci-melb-1" ];

  "hosts/oci-melb-1/system" = [ "oci-melb-1" ];
  "hosts/do-admin-1/system" = [ "do-admin-1" ];

  "hosts/oci-melb-1/oidc" = [ "oci-melb-1" "do-admin-1" ];
  "hosts/do-admin-1/oidc" = [ "do-admin-1" "oci-melb-1" ];
}
