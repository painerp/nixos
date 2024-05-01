{ lib, config, ... }:

let cfg = config.server.radarr;
in {
  options.server.radarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ra" else "radarr";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    volumes = lib.mkOption {
      type = lib.types.list;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "radarr";
        port = "7878";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.radarr.service = {
        image = "lscr.io/linuxserver/radarr:latest";
        container_name = "radarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
        };
        volumes = [ "${config.lib.server.mkConfigDir "radarr"}:/config" ]
          ++ cfg.volumes;
        restart = "unless-stopped";
      };
    };
  };
}
