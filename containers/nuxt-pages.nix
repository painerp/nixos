{ lib, config, secrets, ... }:

let
  cfg = config.server.nuxt-pages;
  config-dir = config.lib.server.mkConfigDir "nuxt-pages";
in
{
  options.server.nuxt-pages = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    pma = {
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "pa" else "phpmyadmin";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enabled;
      };
    };
    app = {
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
        default = config.server.authentik.enabled;
      };
      image = lib.mkOption {
				type = lib.types.str;
				description = "The docker image to use for the nuxt app";
			};
    };
    g2g = {
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "d4" else "diablo4";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enabled;
      };
      image = lib.mkOption {
	      type = lib.types.str;
	      description = "The docker image to use for the g2g app";
      };
    };
  };

  config = lib.mkIf (cfg.enabled) {
    age.secrets.nuxt-pages-env.file = secrets.nuxt-pages-env;
    age.secrets.nuxt-pages-mysql-env.file = secrets.nuxt-pages-mysql-env;
    age.secrets.nuxt-pages-pma-env.file = secrets.nuxt-pages-pma-env;
    age.secrets.nuxt-pages-g2g-env.file = secrets.nuxt-pages-g2g-env;

    systemd.services.arion-nuxt-pages = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = with config.lib.server; mkTraefikAlias {
      subdomain = cfg.app.subdomain;
      root = cfg.app.root;
    } ++ mkTraefikAlias {
      subdomain = cfg.g2g.subdomain;
    } ++ mkTraefikAlias {
      subdomain = cfg.pma.subdomain;
    };

    virtualisation.arion.projects.nuxt-pages.settings = {
      project.name = "nuxt-pages";
      networks.proxy.external = true;
      networks.teamspeak.external = true;
      networks.backend.internal = true;

      services.mysql.service = {
        image = "mariadb:latest";
        container_name = "nuxt-mysql";
        networks = [ "backend" ];
        environment = {
          MARIADB_AUTO_UPGRADE = "yes";
        };
        env_file = [ config.age.secrets.nuxt-pages-mysql-env.path ];
        volumes = [ "${config-dir}/mysql:/var/lib/mysql" ];
        restart = "unless-stopped";
      };

      services.phpmyadmin.service = {
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

      services.app.service = {
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

      services.g2g.service = {
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
}