{ lib, config, ... }:

let cfg = config.server.bazarr;
in {
  options.server.bazarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ba" else "bazarr";
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
    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "bazarr";
        port = "6767";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.bazarr.service = {
        image = "lscr.io/linuxserver/bazarr:latest";
        container_name = "bazarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
        };
        volumes = [ "${config.lib.server.mkConfigDir "bazarr"}:/config" ]
          ++ cfg.volumes;
        restart = "unless-stopped";
      };
    };
  };
}
