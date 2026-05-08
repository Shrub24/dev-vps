{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.postgres-shared;
in
{
  options.services.postgres-shared = {
    enable = lib.mkEnableOption "shared PostgreSQL platform substrate";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/data/postgres";
      description = "PostgreSQL data directory on the shared service-state mount.";
    };

    niks3 = {
      enable = lib.mkEnableOption "dedicated niks3 database and user on the shared PostgreSQL instance";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      dataDir = cfg.dataDir;

      # Let niks3 create its database on first connection.
      ensureDatabases = lib.mkIf cfg.niks3.enable [ "niks3" ];
      ensureUsers = lib.mkIf cfg.niks3.enable [
        {
          name = "niks3";
          ensureDBOwnership = true;
        }
      ];

      authentication = lib.mkIf cfg.niks3.enable ''
        # Allow niks3 local peer access to its own database.
        local niks3 niks3 peer
      '';

      settings = {
        max_connections = "20";
        shared_buffers = "64MB";
        effective_cache_size = "128MB";
        maintenance_work_mem = "16MB";
        wal_buffers = "4MB";
        random_page_cost = "1.1";
        effective_io_concurrency = "200";
        work_mem = "4MB";
        huge_pages = "off";
      };
    };

    systemd.services.postgresql.serviceConfig = {
      ReadWritePaths = [ cfg.dataDir ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 postgres postgres - -"
    ];
  };
}
