{ ... }@args:
let
  hasFlakeSelf = args ? self;
  hasFlakeOutPath = hasFlakeSelf && args.self ? outPath;
  configurationRevision =
    if !hasFlakeSelf then
      null
    else if args.self ? rev then
      args.self.rev
    else if args.self ? dirtyRev then
      args.self.dirtyRev
    else
      null;
in
{
  environment.etc =
    if hasFlakeOutPath then
      {
        "nixos-source".source = args.self.outPath;
      }
    else
      { };

  system.configurationRevision = configurationRevision;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.settings.auto-optimise-store = true;
  nix.settings.trusted-users = [
    "root"
    "dev"
  ];

  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.loader.efi.canTouchEfiVariables = false;

  security.sudo.wheelNeedsPassword = false;
}
