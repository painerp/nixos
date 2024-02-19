{ lib, config, ... }:

let cfg = config.server.prdl;
in {
  options.server.prdl = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    image = lib.mkOption { type = lib.types.str; };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.prdl-env.file = cfg.env-file;

    virtualisation.arion.projects.gluetun.settings = {
      services.prdl.service = {
        image = "${cfg.image}";
        container_name = "prdl";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        environment = {
          RATING_THRESHOLD = 7;
          RATELIMIT = 8;
          DOWNLOAD_PATH = "/motion";
          DOWNLOAD_AMOUNT = 2;
          SCHEDULE = "10 */2 * * *";
          TZ = config.time.timeZone;
        };
        env_file = [ config.age.secrets.prdl-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "prdl"}/db.sqlite:/app/db.sqlite"
          "${config.lib.server.mkConfigDir "prdl"}/log.txt:/app/log.txt"
          "/mnt/motion/Filme:/motion/Filme"
          "/mnt/motion/Serien:/motion/Serien"
        ];
        restart = "unless-stopped";
      };
    };
  };
}
