{
  aiGateway = {
    provider = "openai";

    aliases = {
      text = "shrublab-text";
      image = "shrublab-image";
      embedding = "shrublab-embedding";
      fallback = "shrublab-fallback";
    };

    upstreamModels = {
      text = "gpt-4o-mini";
      image = "gpt-4o";
      embedding = "text-embedding-3-small";
      fallback = "gpt-4.1-mini";
    };
  };

  s3 = {
    endpoint = "https://bef816e6776e8f13f5c03d2af70b036e.r2.cloudflarestorage.com/karakeep";
    region = "auto";
    bucket = "karakeep";
    forcePathStyle = true;
  };
}
