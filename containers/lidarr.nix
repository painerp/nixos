{ lib, config, ... }:

let
  cfg = config.server.lidarr;
in
{
  options.server.lidarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "li" else "lidarr";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "lidarr";
        port = "8686";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.lidarr.service = {
        image = "lscr.io/linuxserver/lidarr:latest";
        container_name = "lidarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
        };
        volumes = [ "${config.lib.server.mkConfigDir "lidarr"}:/config" ] ++ cfg.volumes;
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
