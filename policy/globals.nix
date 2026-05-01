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
    endpoint = "https://bef816e6776e8f13f5c03d2af70b036e.r2.cloudflarestorage.com/karakeep";
    region = "auto";
    bucket = "karakeep";
    forcePathStyle = true;
  };
}
