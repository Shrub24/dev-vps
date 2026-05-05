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
