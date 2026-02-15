{ lib, config, ... }:

let
  cfg = config.server.adguardhome-sync;
in
{
  options.server.adguardhome-sync = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ahs" else "adguardhome-sync";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.adguardhome-sync-env.file = cfg.env-file;

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.adguardhome-sync.settings = {
      project.name = "adguardhome-sync";

      networks.proxy.external = true;

      services.adguardhome-sync.service = {
        image = "ghcr.io/bakito/adguardhome-sync:latest";
        container_name = "adguardhome-sync";
        hostname = config.networking.hostName;
        command = [ "run" ];
        networks = [ "proxy" ];
        volumes = [
          "${config.lib.server.mkConfigDir "adguardhome-sync"}:/config"
        ];
        environment = {
          TZ = config.time.timeZone;
          CRON = "*/10 * * * *";
          RUN_ON_START = "true";
        };
        env_file = [ config.age.secrets.adguardhome-sync-env.path ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "adguardhome-sync";
            port = "8080";
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
}
