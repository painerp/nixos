{ lib, config, ... }:

let
  cfg = config.server.goaccess;
in
{
  options.server.goaccess = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ga" else "goaccess";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-goaccess = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.goaccess.settings = {
      project.name = "goaccess";
      networks.proxy.external = true;

      services.nginx.service = {
        image = "nginx:latest";
        container_name = "nginx";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          TZ = config.time.timeZone;
        };
        volumes = [
          "${config.lib.server.mkConfigDir "goaccess/public"}:/usr/share/nginx/html"
          "${config.lib.server.mkConfigDir "goaccess/config"}:/etc/nginx"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "goaccess";
            port = "80";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };

      services.goaccess.service = {
        image = "allinurl/goaccess:latest";
        container_name = "goaccess";
        hostname = config.networking.hostName;
        command = [
          "--no-global-config"
          "--config-file=/srv/config/goaccess.conf"
        ];
        environment = {
          TZ = config.time.timeZone;
        };
        volumes =
          [
            "${config.lib.server.mkConfigDir "goaccess/config"}:/srv/config"
            "${config.lib.server.mkConfigDir "goaccess/geoip"}:/srv/geoip"
            "${config.lib.server.mkConfigDir "goaccess/public"}:/srv/report"
          ]
          ++ (
            if (config.server.traefik.enable) then
              [ "${config.lib.server.mkConfigDir "traefik/logs"}:/srv/logs" ]
            else
              [ ]
          );
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
