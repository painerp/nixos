{ lib, config, ... }:

let cfg = config.server.readarr;
in {
  options.server.readarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "re" else "readarr";
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
        name = "readarr";
        port = "8787";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.readarr.service = {
        image = "lscr.io/linuxserver/readarr:develop";
        container_name = "readarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
        };
        volumes = [ "${config.lib.server.mkConfigDir "readarr"}:/config" ]
          ++ cfg.volumes;
        labels = { "com.centurylinklabs.watchtower.enable" = "true"; };
        restart = "unless-stopped";
      };
    };
  };
}
