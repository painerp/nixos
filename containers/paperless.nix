{ lib, config, ... }:

let
  cfg = config.server.paperless;
  config-dir = config.lib.server.mkConfigDir "paperless";
  default-version = "latest";
in
{
  options.server.paperless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "pl" else "paperless";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = default-version;
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    ocr-language = lib.mkOption {
      type = lib.types.str;
      default = "deu+eng";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.paperless-env.file = cfg.env-file;
    age.secrets.paperless-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-paperless = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.paperless.settings = {
      project.name = "paperless";
      networks.proxy.external = true;
      networks.internal.internal = true;

      services.paperless-pg.service = {
        image = "docker.io/postgres:18";
        container_name = "paperless-pg";
        hostname = config.networking.hostName;
        networks = [ "internal" ];
        environment = {
          POSTGRES_USER = "paperless";
          POSTGRES_DB = "paperless";
        };
        env_file = [ config.age.secrets.paperless-pg-env.path ];
        volumes = [ "${config-dir}/postgres:/var/lib/postgresql" ];
        restart = "unless-stopped";
      };

      services.paperless-broker.service = {
        image = "docker.io/valkey/valkey:9-alpine";
        container_name = "paperless-broker";
        hostname = config.networking.hostName;
        networks = [ "internal" ];
        volumes = [ "${config-dir}/broker:/data" ];
        restart = "unless-stopped";
      };

      services.paperless.service = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:${cfg.version}";
        container_name = "paperless";
        hostname = config.networking.hostName;
        networks = [
          "proxy"
          "internal"
        ];
        environment = {
          PAPERLESS_REDIS = "redis://paperless-broker:6379";
          PAPERLESS_DBENGINE = "postgresql";
          PAPERLESS_DBHOST = "paperless-pg";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_URL = "https://${cfg.subdomain}.${config.server.domain}";
          PAPERLESS_TIME_ZONE = config.time.timeZone;
          PAPERLESS_OCR_LANGUAGE = cfg.ocr-language;
          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_DISABLE_REGULAR_LOGIN = "false";
        };
        env_file = [ config.age.secrets.paperless-env.path ];
        volumes = [
          "${config-dir}/data:/usr/src/paperless/data"
          "${config-dir}/media:/usr/src/paperless/media"
          "${config-dir}/consume:/usr/src/paperless/consume"
          "${config-dir}/export:/usr/src/paperless/export"
        ]
        ++ cfg.volumes;
        depends_on = [
          "paperless-pg"
          "paperless-broker"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "paperless";
            port = "8000";
            subdomain = cfg.subdomain;
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
  };
}
