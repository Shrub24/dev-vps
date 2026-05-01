{ lib, ... }:
{
  options.fleet.worker.enable = lib.mkEnableOption "future worker interface";
}
