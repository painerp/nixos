{ lib, config, ... }:

let
  cfg = config.server.dawarich;
  config-dir = "${config.lib.server.mkConfigDir "dawarich"}";
  default-env = {
    RAIL_ENV = "development";
    REDIS_URL = "redis://redis:6379/0";
    DATABASE_HOST = "database";
    DATABASE_USERNAME = "postgres";
    DATABASE_NAME = "dawarich";
    MIN_MINUTES_SPENT_IN_CITY = 60;
    APPLICATION_HOSTS = "localhost,${cfg.subdomain}.${config.server.domain}";
    TIME_ZONE = config.time.timeZone;
  };
in {
  options.server.dawarich = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "tr" else "track";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "latest";
    };
    redis.image = lib.mkOption {
      type = lib.types.str;
      default = "redis:7.0-alpine";
    };
    postgres = {
      image = lib.mkOption {
        type = lib.types.str;
        default = "postgres:14.2-alpine";
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.dawarich-env.file = cfg.env-file;
    age.secrets.dawarich-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-dawarich = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.dawarich.settings = {
      project.name = "dawarich";
      networks.proxy.external = true;
      networks.backend.internal = true;

      services.dawarich-server = {
        service = {
          image = "freikin/dawarich:${cfg.version}";
          container_name = "dawarich_app";
          hostname = config.networking.hostName;
          networks = [ "proxy" "backend" ];
          command = [ "bin/dev" ];
          environment = default-env;
          env_file = [ config.age.secrets.dawarich-env.path ];
          volumes = [
            "${config-dir}/gem-cache:/usr/local/bundle/gems"
            "${config-dir}/public:/var/app/public"
          ];
          depends_on = [ "database" "redis" ];
          labels = config.lib.server.mkTraefikLabels {
            name = "dawarich";
            port = "3000";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          } // {
            "com.centurylinklabs.watchtower.enable" = "false";
          };
          restart = "unless-stopped";
        };
      };

      services.dawarich-sidekiq = {
        service = {
          image = "freikin/dawarich:${cfg.version}";
          container_name = "dawarich_sidekiq";
          hostname = config.networking.hostName;
          networks = [ "proxy" "backend" ];
          command = [ "sidekiq" ];
          environment = default-env // {
            BACKGROUND_PROCESSING_CONCURRENCY = "10";
          };
          env_file = [ config.age.secrets.dawarich-env.path ];
          volumes = [
            "${config-dir}/gem-cache:/usr/local/bundle/gems"
            "${config-dir}/public:/var/app/public"
          ];
          depends_on = [ "database" "redis" "dawarich-server" ];
          labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
          restart = "unless-stopped";
        };
      };

      services.redis.service = {
        image = "${cfg.redis.image}";
        container_name = "dawarich_redis";
        hostname = config.networking.hostName;
        networks = [ "backend" ];
        labels = { "com.centurylinklabs.watchtower.enable" = "true"; };
        restart = "unless-stopped";
      };

      services.database.service = {
        image = "${cfg.postgres.image}";
        container_name = "dawarich_postgres";
        hostname = config.networking.hostName;
        networks = [ "backend" ];
        environment = {
          POSTGRES_USER = "${default-env.DATABASE_USERNAME}";
          POSTGRES_DB = "${default-env.DATABASE_NAME}";
        };
        env_file = [ config.age.secrets.dawarich-pg-env.path ];
        volumes = [ "${config-dir}/postgres:/var/lib/postgresql/data" ];
        labels = { "com.centurylinklabs.watchtower.enable" = "true"; };
        restart = "unless-stopped";
      };
    };
  };
}
