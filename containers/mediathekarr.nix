{ lib, config, ... }:

let
  cfg = config.server.mediathekarr;
in
{
  options.server.mediathekarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ma" else "mediathekarr";
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
        name = "mediathekarr";
        port = "5007";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.mediathekarr.service = {
        image = "pcjones/mediathekarr:latest";
        container_name = "mediathekarr";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          TZ = config.time.timeZone;
          DOWNLOAD_FOLDER_PATH_MAPPING = "/downloads";
        };
        volumes = cfg.volumes;
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
