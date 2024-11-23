{ lib, config, ... }:

let
  cfg = config.server.home-assistant;
in
{
  options.server.home-assistant = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ha" else "home-assistant";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-home-assistant = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.home-assistant.settings = {
      project.name = "home-assistant";
      networks.proxy.external = true;

      services.home-assistant.service = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        container_name = "home-assistant";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/run/dbus:/run/dbus:ro"
          "${config.lib.server.mkConfigDir "home-assistant/config"}:/config"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "home-assistant";
            port = "8123";
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
