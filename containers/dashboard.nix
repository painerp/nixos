{ lib, config, ... }:

let
  cfg = config.server.dashboard;
in
{
  options.server.dashboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "da" else "dashboard";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-dashboard = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.dashboard.settings = {
      project.name = "dashboard";
      networks.proxy.external = true;

      services.dashboard.service = {
        image = "ghcr.io/gethomepage/homepage:latest";
        container_name = "dashboard";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        sysctls = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
        environment = {
          HOMEPAGE_ALLOWED_HOSTS = "${cfg.subdomain}.${config.server.domain}";
        };
        volumes = [
          "${config.lib.server.mkConfigDir "dashboard/config"}:/app/config"
          "${config.lib.server.mkConfigDir "dashboard/images"}:/app/public/images"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "dashboard";
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
}
