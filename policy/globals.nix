{
  aiGateway = {
    aliases = {
      text = "shrublab-text";
      image = "shrublab-image";
      embedding = "shrublab-embedding";
      fallback = "shrublab-fallback";
    };
    configFile = ./bifrost-config.json;
  };

  s3 = {
    endpoint = "https://bef816e6776e8f13f5c03d2af70b036e.r2.cloudflarestorage.com";
    region = "auto";
    forcePathStyle = true;
  };

  # Canonical non-secret defaults for application stacks.
  # Application modules import this attrset and apply values
  # via lib.mkDefault so hosts can override without touching
  # the module definition.
  applications = {
    music = {
      dataRoot = "/srv/data";
      mediaRoot = "/srv/media";
    };
    admin = {
      dataRoot = "/srv/data";
    };
    edge-ingress = {
      enable = false;
      role = "none";
    };
  };

  services = {
    nix = {
      substituters = [
        "ssh://eu.nixbuild.net?priority=0"
        "https://cache.shrublab.xyz"
      ];
      trustedSubstituters = [
        "ssh://eu.nixbuild.net?priority=0"
        "https://cache.shrublab.xyz"
      ];
      trustedPublicKeys = [
        "nixbuild.net/HWWKWC-1:dnSfpPDHQN/U9wexkK6r3GTaYrwqNwKS70SNGXistKg="
        "nix-cache-1:FW0bJll9BP5ch0mHI+bXOImcD0RKLrH117WfQC+CU4A="
      ];
    };

    karakeep-pod = {
      dataDir = "/srv/data/karakeep";
      port = 3010;
      s3.bucket = "karakeep";
    };
    bifrost-gateway = {
      dataDir = "/srv/data/bifrost";
    };
  };
}
