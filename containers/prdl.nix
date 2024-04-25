{ lib, config, ... }:

let cfg = config.server.prdl;
in {
  options.server.prdl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "pd" else "prdl";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    image = lib.mkOption { type = lib.types.str; };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.prdl-env.file = cfg.env-file;

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "prdl";
        port = "9612";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.prdl.service = {
        image = "${cfg.image}";
        container_name = "prdl";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          RATING_THRESHOLD = 7;
          RATELIMIT = 8;
          TZ = config.time.timeZone;
        };
        env_file = [ config.age.secrets.prdl-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "prdl"}/db.sqlite:/app/db.sqlite"
          "${config.lib.server.mkConfigDir "prdl"}/log.txt:/app/log.txt"
          "/mnt/motion/Downloads/Filme:/movies"
          "/mnt/motion/Downloads/Serien:/tvshows"
        ];
        restart = "unless-stopped";
      };
    };
  };
}
