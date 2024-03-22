{ lib, config, ... }:

let cfg = config.server.linkwarden;
in {
  options.server.linkwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "lw" else "linkwarden";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.linkwarden-env.file = cfg.env-file;
    age.secrets.linkwarden-pg-env.file = cfg.postgres.env-file;

    systemd.services.arion-linkwarden = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.linkwarden.settings = {
      project.name = "linkwarden";

      networks.proxy.external = true;
      networks.internal.internal = true;

      services.linkwarden-pg.service = {
        image = "postgres:alpine";
        container_name = "linkwarden-pg";
        hostname = config.networking.hostName;
        networks = [ "internal" ];
        environment = { POSTGRES_USER = "postgres"; };
        env_file = [ config.age.secrets.linkwarden-pg-env.path ];
        volumes = [
          "${
            config.lib.server.mkConfigDir "linkwarden/postgres"
          }:/var/lib/postgresql/data"
        ];
        restart = "unless-stopped";
      };

      services.linkwarden.service = {
        image = "ghcr.io/linkwarden/linkwarden:latest";
        container_name = "linkwarden";
        hostname = config.networking.hostName;
        networks = [ "proxy" "internal" ];
        environment = { NEXT_PUBLIC_DISABLE_REGISTRATION = "true"; };
        volumes =
          [ "${config.lib.server.mkConfigDir "linkwarden/data"}:/data/data" ];
        env_file = [ config.age.secrets.linkwarden-env.path ];
        depends_on = [ "linkwarden-pg" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "linkwarden";
          port = "3000";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}
