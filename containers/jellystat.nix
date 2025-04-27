{ lib, config, ... }:

let
  cfg = config.server.jellystat;
in
{
  options.server.jellystat = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "js" else "jellystat";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
    extra-hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.jellystat-env.file = cfg.env-file;
    age.secrets.jellystat-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-jellystat = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.jellystat.settings = {
      project.name = "jellystat";

      networks.proxy.external = true;
      networks.internal.internal = true;

      services.jellystat-pg.service = {
        image = "postgres:16-alpine";
        container_name = "jellystat-pg";
        hostname = config.networking.hostName;
        networks = [ "internal" ];
        environment = {
          POSTGRES_USER = "postgres";
        };
        env_file = [ config.age.secrets.jellystat-pg-env.path ];
        volumes = [ "${config.lib.server.mkConfigDir "jellystat"}:/var/lib/postgresql/data" ];
        restart = "unless-stopped";
      };

      services.jellystat = {
        out.service = {
          deploy.resources.limits = {
            cpus = "0.2";
            memory = "1G";
          };
        };
        service = {
          image = "cyfershepard/jellystat:latest";
          container_name = "jellystat";
          hostname = config.networking.hostName;
          networks = [
            "proxy"
            "internal"
          ];
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_IP = "jellystat-pg";
            POSTGRES_PORT = 5432;
            TZ = config.time.timeZone;
          };
          env_file = [ config.age.secrets.jellystat-env.path ];
          extra_hosts = cfg.extra-hosts;
          depends_on = [ "jellystat-pg" ];
          labels =
            config.lib.server.mkTraefikLabels {
              name = "jellystat";
              port = "3000";
              subdomain = "${cfg.subdomain}";
              forwardAuth = cfg.auth;
            }
            // {
              "com.centurylinklabs.watchtower.enable" = "true";
            };
          restart = "unless-stopped";
        };
      };
    };
  };
}
