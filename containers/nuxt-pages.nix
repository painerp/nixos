{ lib, config, secrets, ... }:

let
  cfg = config.server.nuxt-pages;
  config-dir = config.lib.server.mkConfigDir "nuxt-pages";
in {
  options.server.nuxt-pages = {
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
    app = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "nu" else "nuxt";
      };
      root = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
      image = lib.mkOption {
        type = lib.types.str;
        description = "The docker image to use for the nuxt app";
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
    g2g = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "d4" else "diablo4";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
      image = lib.mkOption {
        type = lib.types.str;
        description = "The docker image to use for the g2g app";
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
    mysql.env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (cfg.pma.enable || cfg.app.enable || cfg.g2g.enable) {
    age.secrets = {
      nuxt-pages-mysql-env.file = cfg.mysql.env-file;
    } // lib.mkIf (cfg.app.enable) { nuxt-pages-env.file = cfg.app.env-file; }
      // lib.mkIf (cfg.pma.enable) {
        nuxt-pages-pma-env.file = cfg.pma.env-file;
      } // lib.mkIf (cfg.g2g.enable) {
        nuxt-pages-g2g-env.file = cfg.g2g.env-file;
      };

    systemd.services.arion-nuxt-pages = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = with config.lib.server;
      mkTraefikAlias {
        subdomain = cfg.app.subdomain;
        root = cfg.app.root;
      } ++ mkTraefikAlias { subdomain = cfg.g2g.subdomain; }
      ++ mkTraefikAlias { subdomain = cfg.pma.subdomain; };

    virtualisation.arion.projects.nuxt-pages.settings = {
      project.name = "nuxt-pages";
      networks.proxy.external = true;
      networks.teamspeak.external = true;
      networks.backend.internal = true;

      services = {
        mysql.service = {
          image = "mariadb:latest";
          container_name = "nuxt-mysql";
          networks = [ "backend" ];
          environment = { MARIADB_AUTO_UPGRADE = "yes"; };
          env_file = [ config.age.secrets.nuxt-pages-mysql-env.path ];
          volumes = [ "${config-dir}/mysql:/var/lib/mysql" ];
          restart = "unless-stopped";
        };

      } // lib.attrsets.optionalAttrs (cfg.pma.enable) {
        phpmyadmin.service = {
          image = "phpmyadmin:latest";
          container_name = "nuxt-pma";
          networks = [ "backend" "proxy" ];
          depends_on = [ "mysql" ];
          environment = {
            PMA_HOST = "nuxt-mysql";
            PMA_PMADB = "phpmyadmin";
            PMA_CONTROLUSER = "root";
            HIDE_PHP_VERSION = "yes";
            UPLOAD_LIMIT = "64M";
          };
          env_file = [ config.age.secrets.nuxt-pages-pma-env.path ];
          labels = config.lib.server.mkTraefikLabels {
            name = "nuxt-pma";
            port = "80";
            subdomain = "${cfg.pma.subdomain}";
            forwardAuth = cfg.pma.auth;
          };
          restart = "unless-stopped";
        };

      } // lib.attrsets.optionalAttrs (cfg.app.enable) {
        app.service = {
          image = "${cfg.app.image}";
          container_name = "nuxt-app";
          depends_on = [ "mysql" ];
          networks = [ "backend" "proxy" "teamspeak" ];
          env_file = [ config.age.secrets.nuxt-pages-env.path ];
          volumes = [
            "${config-dir}/nuxt-app/upload:/srv/upload"
            "${config-dir}/nuxt-app/cache:/srv/public/cache"
          ];
          labels = config.lib.server.mkTraefikLabels {
            name = "nuxt-app";
            port = "3000";
            subdomain = "${cfg.app.subdomain}";
            forwardAuth = cfg.app.auth;
            root = cfg.app.root;
          };
          restart = "unless-stopped";
        };

      } // lib.attrsets.optionalAttrs (cfg.g2g.enable) {
        g2g.service = {
          image = "${cfg.g2g.image}";
          container_name = "nuxt-g2g";
          depends_on = [ "mysql" ];
          networks = [ "backend" "proxy" ];
          env_file = [ config.age.secrets.nuxt-pages-g2g-env.path ];
          labels = config.lib.server.mkTraefikLabels {
            name = "nuxt-g2g";
            port = "3000";
            subdomain = "${cfg.g2g.subdomain}";
            forwardAuth = cfg.g2g.auth;
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
