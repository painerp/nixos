{
  lib,
  config,
  secrets,
  ...
}:

let
  cfg = config.server.bachelor;
  config-dir = config.lib.server.mkConfigDir "bachelor";
in
{
  options.server.bachelor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "${config.server.domain}";
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ba" else "bachelor";
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
      description = "The docker image to use for the service";
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.bachelor-env.file = cfg.env-file;
    age.secrets.bachelor-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-bachelor = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
      domain = cfg.domain;
      root = cfg.root;
    };

    virtualisation.arion.projects.bachelor.settings = {
      project.name = "bachelor";
      networks.proxy.external = true;
      networks.backend.internal = true;

      services.postgres.service = {
        image = "postgres:latest";
        container_name = "bachelor-pg";
        networks = [ "backend" ];
        environment = {
          POSTGRES_USER = "bachelor";
          POSTGRES_DB = "bachelor";
        };
        env_file = [ config.age.secrets.bachelor-pg-env.path ];
        volumes = [ "${config-dir}/postgres:/var/lib/postgresql/data" ];
        restart = "unless-stopped";
      };

      services.redis.service = {
        image = "redis:alpine";
        container_name = "bachelor-redis";
        networks = [ "backend" ];
        volumes = [ "${config-dir}/redis:/data" ];
        restart = "unless-stopped";
      };

      services.inventurpro.service = {
        image = "${cfg.image}";
        container_name = "bachelor-ip";
        networks = [
          "backend"
          "proxy"
        ];
        env_file = [ config.age.secrets.bachelor-env.path ];
        volumes = [ "${config-dir}/logs:/var/log/apache2" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "bachelor";
          port = "80";
          domain = "${cfg.domain}";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
          root = cfg.root;
        };
        restart = "unless-stopped";
      };
    };
  };
}
