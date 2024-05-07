{ lib, config, ... }:

let
  cfg = config.server.immich;
  config-dir = "${config.lib.server.mkConfigDir "immich"}";
  default-env = {
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
  };
in {
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
      default = "release";
    };
    redis.image = lib.mkOption {
      type = lib.types.str;
      default = "redis:alpine";
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

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.immich.settings = {
      project.name = "immich";
      networks.proxy.external = true;
      networks.backend.internal = true;

      services.immich-server.service = {
        image = "ghcr.io/immich-app/immich-server:${cfg.version}";
        container_name = "immich_server";
        hostname = config.networking.hostName;
        command = "start.sh immich";
        networks = [ "proxy" "backend" ];
        environment = default-env;
        env_file = [ config.age.secrets.immich-env.path ];
        volumes = [ "/etc/localtime:/etc/localtime:ro" ] ++ cfg.volumes;
        depends_on = [ "database" "redis" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "immich";
          port = "3001";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        } // {
          "com.centurylinklabs.watchtower.enable" = "false";
        };
        restart = "unless-stopped";
      };

      services.immich-microservices = {
        out.service = {
          deploy.resources.reservations.devices = [{
            driver = "nvidia";
            count = 1;
            capabilities = [ "gpu" "compute" "video" ];
          }];
        };
        service = {
          image = "ghcr.io/immich-app/immich-server:${cfg.version}";
          container_name = "immich_microservices";
          hostname = config.networking.hostName;
          command = "start.sh microservices";
          networks = [ "backend" ];
          environment = default-env;
          env_file = [ config.age.secrets.immich-env.path ];
          volumes = [ "/etc/localtime:/etc/localtime:ro" ] ++ cfg.volumes;
          labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
          depends_on = [ "database" "redis" ];
          restart = "unless-stopped";
        };
      };

      services.immich-machine-learning = {
        out.service = {
          deploy.resources.reservations.devices = [{
            driver = "nvidia";
            count = 1;
            capabilities = [ "gpu" ];
          }];
        };
        service = {
          image =
            "ghcr.io/immich-app/immich-machine-learning:${cfg.version}-cuda";
          container_name = "immich_machine_learning";
          hostname = config.networking.hostName;
          networks = [ "backend" ];
          volumes = [ "${config-dir}/model-cache:/cache" ];
          labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
          restart = "unless-stopped";
        };
      };

      services.redis.service = {
        image = "${cfg.redis.image}";
        container_name = "immich_redis";
        hostname = config.networking.hostName;
        networks = [ "backend" ];
        labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
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
        labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
        restart = "unless-stopped";
      };
    };
  };
}
