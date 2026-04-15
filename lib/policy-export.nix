{
  hostName ? "do-admin-1",
}:
let
  flake = builtins.getFlake (toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  policy = import ../policy/web-services.nix;
  policyLib = import ./policy.nix { inherit lib; };
in
policyLib.resolveHostServices policy hostName
