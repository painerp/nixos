{ lib, config, ... }:

let
  cfg = config.server.mailflow;
  url = "https://${config.lib.server.mkServiceSubdomain cfg.subdomain}";
in
{
  options.server.mailflow = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "mf" else "mailflow";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.mailflow-env.file = cfg.env-file;
    age.secrets.mailflow-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-mailflow = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.services.mailflow-pg-backup = config.lib.server.mkDbBackup {
      type = "postgres";
      container = "mailflow-pg";
      dir = "${config.lib.server.mkConfigDir "mailflow"}/postgres-backup";
    };
    modules.borg.exclude = [
      (lib.removePrefix "/root/" (config.lib.server.mkConfigDir "mailflow/postgres"))
    ];

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.mailflow.settings = {
      project.name = "mailflow";

      networks.proxy.external = true;
      networks.internal.internal = true;

      services.mailflow-pg.service = {
        image = "docker.io/postgres:16-alpine";
        container_name = "mailflow-pg";
        hostname = config.networking.hostName;
        networks = [ "internal" ];
        environment = {
          POSTGRES_USER = "mailflow";
          POSTGRES_DB = "mailflow";
        };
        env_file = [ config.age.secrets.mailflow-pg-env.path ];
        volumes = [ "${config.lib.server.mkConfigDir "mailflow/postgres"}:/var/lib/postgresql/data" ];
      };

      services.mailflow-backend.service = {
        image = "ghcr.io/maathimself/mailflow-backend:latest";
        container_name = "mailflow-backend";
        hostname = config.networking.hostName;
        # proxy for outbound IMAP/SMTP, internal has no egress
        networks = [
          "proxy"
          "internal"
        ];
        environment = {
          NODE_ENV = "production";
          PORT = "3000";
          APP_URL = url;
          FRONTEND_URL = url;
          DB_HOST = "mailflow-pg";
          # traefik + mailflow's caddy
          TRUST_PROXY_HOPS = "2";
        };
        env_file = [ config.age.secrets.mailflow-env.path ];
        stop_grace_period = "30s";
        depends_on = [ "mailflow-pg" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
      };

      services.mailflow.service = {
        image = "ghcr.io/maathimself/mailflow-frontend:latest";
        container_name = "mailflow";
        hostname = config.networking.hostName;
        networks = [
          "proxy"
          "internal"
        ];
        environment = {
          TLS_MODE = "off";
          BACKEND_HOST = "mailflow-backend";
        };
        depends_on = [ "mailflow-backend" ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "mailflow";
            port = "80";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
      };
    };
  };
}
