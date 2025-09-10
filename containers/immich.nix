{ lib, config, ... }:

let
  cfg = config.server.immich;
  config-dir = "${config.lib.server.mkConfigDir "immich"}";
  default-env = {
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
  };
  default-version = "release";
  default-redis-image = "redis:alpine";
in
{
  options.server.immich = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "im" else "immich";
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
      default = default-version;
    };
    redis.image = lib.mkOption {
      type = lib.types.str;
      default = default-redis-image;
    };
    postgres = {
      image = lib.mkOption { type = lib.types.str; };
      env-file = lib.mkOption { type = lib.types.path; };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.immich-env.file = cfg.env-file;
    age.secrets.immich-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-immich = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.immich.settings = {
      project.name = "immich";
      networks.outbound.name = "outbound";
      networks.proxy.external = true;
      networks.backend.internal = true;

      services.immich-server = {
        out.service = {
          deploy.resources.reservations.devices = [
            {
              driver = "cdi";
              device_ids = [ "nvidia.com/gpu=all" ];
              capabilities = [
                "gpu"
                "compute"
                "video"
              ];
            }
          ];
        };
        service = {
          image = "ghcr.io/immich-app/immich-server:${cfg.version}";
          container_name = "immich_server";
          hostname = config.networking.hostName;
          networks = [
            "proxy"
            "backend"
          ];
          environment = default-env;
          env_file = [ config.age.secrets.immich-env.path ];
          volumes = [ "/etc/localtime:/etc/localtime:ro" ] ++ cfg.volumes;
          depends_on = [
            "database"
            "redis"
          ];
          labels =
            config.lib.server.mkTraefikLabels {
              name = "immich";
              port = "2283";
              subdomain = "${cfg.subdomain}";
              forwardAuth = cfg.auth;
            }
            // {
              "com.centurylinklabs.watchtower.enable" = config.lib.server.boolToStr (
                cfg.version == default-version
              );
            };
          restart = "unless-stopped";
        };
      };

      services.immich-machine-learning = {
        out.service = {
          deploy.resources.reservations.devices = [
            {
              driver = "cdi";
              device_ids = [ "nvidia.com/gpu=all" ];
              capabilities = [ "gpu" ];
            }
          ];
        };
        service = {
          image = "ghcr.io/immich-app/immich-machine-learning:${cfg.version}-cuda";
          container_name = "immich_machine_learning";
          hostname = config.networking.hostName;
          networks = [
            "backend"
            "outbound"
          ];
          volumes = [ "${config-dir}/model-cache:/cache" ];
          labels = {
            "com.centurylinklabs.watchtower.enable" = config.lib.server.boolToStr (
              cfg.version == default-version
            );
          };
          restart = "unless-stopped";
        };
      };

      services.redis.service = {
        image = "${cfg.redis.image}";
        container_name = "immich_redis";
        hostname = config.networking.hostName;
        networks = [ "backend" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = config.lib.server.boolToStr (
            cfg.redis.image == default-redis-image
          );
        };
        restart = "unless-stopped";
      };

      services.database.service = {
        image = "${cfg.postgres.image}";
        container_name = "immich_postgres";
        hostname = config.networking.hostName;
        networks = [ "backend" ];
        environment = {
          POSTGRES_USER = "${default-env.DB_USERNAME}";
          POSTGRES_DB = "${default-env.DB_DATABASE_NAME}";
        };
        env_file = [ config.age.secrets.immich-pg-env.path ];
        volumes = [ "${config-dir}/postgres:/var/lib/postgresql/data" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = config.lib.server.boolToStr (
            cfg.version == default-version
          );
        };
        restart = "unless-stopped";
      };
    };
  };
}
