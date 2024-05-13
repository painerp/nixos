{ lib, config, ... }:

let cfg = config.server.prowlarr;
in {
  options.server.prowlarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "po" else "prowlarr";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "prowlarr";
        port = "9696";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.prowlarr.service = {
        image = "lscr.io/linuxserver/prowlarr:latest";
        container_name = "prowlarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
        };
        volumes = [ "${config.lib.server.mkConfigDir "prowlarr"}:/config" ];
        restart = "unless-stopped";
      };
    };
  };
}
