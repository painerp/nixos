{ lib, config, secrets, ... }:

let
  cfg = config.server.unknown;
  config-dir = config.lib.server.mkConfigDir "unknown";
in {
  options.server.unknown = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "un" else "unknown";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    image = lib.mkOption {
      type = lib.types.str;
      description = "The docker image to use for the unknown app";
    };
    extras-dir = lib.mkOption {
      type = lib.types.path;
      description = "The directory to mount as /srv/extras/files";
      default = "${config-dir}/extras";
    };
    env-file = lib.mkOption { type = lib.types.path; };
    mysql.env-file = lib.mkOption { type = lib.types.path; };
    pma = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "pa" else "phpmyadmin";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && (cfg.enable)) {
    age.secrets = {
      unknown-env.file = cfg.env-file;
      unknown-mysql-env.file = cfg.mysql.env-file;
    } // (if (cfg.pma.enable) then {
      unknown-pma-env.file = cfg.pma.env-file;
    } else
      { });

    systemd.services.arion-unknown = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.unknown.settings = {
      project.name = "unknown";
      networks.proxy.external = true;
      networks.backend.internal = true;

      services = {
        mysql.service = {
          image = "mariadb:latest";
          container_name = "unknown-mysql";
          networks = [ "backend" ];
          environment = { MARIADB_AUTO_UPGRADE = "yes"; };
          env_file = [ config.age.secrets.unknown-mysql-env.path ];
          volumes = [ "${config-dir}/mysql:/var/lib/mysql" ];
          restart = "unless-stopped";
        };

        unknown.service = {
          image = "${cfg.image}";
          container_name = "unknown";
          depends_on = [ "mysql" ];
          networks = [ "backend" "proxy" ];
          env_file = [ config.age.secrets.unknown-env.path ];
          volumes = [
            "${cfg.extras-dir}/files:/srv/extras/files"
            "${cfg.extras-dir}/thumbnails:/srv/extras/thumbnails"
          ];
          labels = config.lib.server.mkTraefikLabels {
            name = "unknown";
            port = "3000";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          };
          restart = "unless-stopped";
        };

      } // lib.attrsets.optionalAttrs (cfg.pma.enable) {
        phpmyadmin.service = {
          image = "phpmyadmin:latest";
          container_name = "unknown-pma";
          networks = [ "backend" "proxy" ];
          depends_on = [ "mysql" ];
          environment = {
            PMA_HOST = "unknown-mysql";
            PMA_PMADB = "phpmyadmin";
            PMA_CONTROLUSER = "root";
            PMA_ABSOLUTE_URI =
              "https://${cfg.pma.subdomain}.${cfg.subdomain}.${config.server.domain}";
            HIDE_PHP_VERSION = "yes";
            UPLOAD_LIMIT = "64M";
          };
          env_file = [ config.age.secrets.unknown-pma-env.path ];
          labels = config.lib.server.mkTraefikLabels {
            name = "unknown-pma";
            port = "80";
            subdomain = "${cfg.pma.subdomain}.${cfg.subdomain}";
            forwardAuth = cfg.pma.auth;
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
