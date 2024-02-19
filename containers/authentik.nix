{ lib, config, secrets, ... }:

let
  cfg = config.server.authentik;
  config-dir = config.lib.server.mkConfigDir "authentik";
  address = if cfg.proxy then "authentik-proxy" else "authentik-server";
  use-smtp = if cfg.email-host == "protonbridge" then true else false;
  subdomain = if cfg.proxy then "auth-proxy" else cfg.subdomain;
  labels = config.lib.server.mkTraefikLabels {
    name = "authentik";
    port = "9000";
    subdomain = "${subdomain}";
    rule =
      "(Host(`${subdomain}.${config.server.domain}`) || HostRegexp(`{subdomain:[a-z0-9]+}.${config.server.domain}`) && PathPrefix(`/outpost.goauthentik.io/`))";
  } // {
    "traefik.http.middlewares.authentik.forwardauth.address" =
      "http://${address}:9000/outpost.goauthentik.io/auth/traefik";
    "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" =
      "true";
    "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" =
      "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
  };
  env-auth = {
    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-pg";
    AUTHENTIK_POSTGRESQL__USER = "authentik";
    AUTHENTIK_POSTGRESQL__NAME = "authentik";
    AUTHENTIK_EMAIL__HOST = "${cfg.email-host}";
    AUTHENTIK_EMAIL__PORT = 25;
    AUTHENTIK_EMAIL__TIMEOUT = 10;
  };
in {
  options.server.authentik = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "auth" else "authentik";
    };
    proxy = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    email-host = lib.mkOption {
      type = lib.types.str;
      default = "protonbridge";
    };
    env-file = lib.mkOption { type = lib.types.path; };
    postgres.env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets = if (cfg.proxy) then {
      authentik-proxy-env.file = cfg.env-file;
    } else {
      authentik-env.file = cfg.env-file;
      authentik-pg-env.file = cfg.postgres.env-file;
    };

    systemd.services.arion-authentik = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = subdomain; };

    virtualisation.arion.projects.authentik.settings = {
      project.name = "authentik";
      networks.proxy.external = true;
      networks.smtp.external = lib.mkIf (!cfg.proxy || use-smtp) true;
      networks.authentik-internal.internal = lib.mkIf (!cfg.proxy) true;

      services = if (cfg.proxy) then {
        authentik-proxy.service = {
          image = "ghcr.io/goauthentik/proxy:latest";
          container_name = "authentik-proxy";
          networks = [ "proxy" ];
          environment = { AUTHENTIK_DISABLE_STARTUP_ANALYTICS = "true"; };
          env_file = [ config.age.secrets.authentik-proxy-env.path ];
          inherit labels;
          restart = "unless-stopped";
        };
      } else {
        postgresql.service = {
          image = "docker.io/library/postgres:12-alpine";
          container_name = "authentik-pg";
          networks = [ "authentik-internal" ];
          environment = {
            POSTGRES_USER = "authentik";
            POSTGRES_DB = "authentik";
          };
          env_file = [ config.age.secrets.authentik-pg-env.path ];
          healthcheck = {
            test = [ "CMD-SHELL" "pg_isready -d authentik -U authentik" ];
            start_period = "20s";
            interval = "30s";
            retries = 5;
            timeout = "5s";
          };
          volumes = [ "${config-dir}/database:/var/lib/postgresql/data" ];
          restart = "unless-stopped";
        };

        redis.service = {
          image = "docker.io/library/redis:alpine";
          container_name = "authentik-redis";
          command = "--save 60 1 --loglevel warning";
          networks = [ "authentik-internal" ];
          healthcheck = {
            test = [ "CMD-SHELL" "redis-cli ping | grep PONG" ];
            start_period = "20s";
            interval = "30s";
            retries = 5;
            timeout = "3s";
          };
          volumes = [ "${config-dir}/redis:/data" ];
          restart = "unless-stopped";
        };

        server.service = {
          image = "ghcr.io/goauthentik/server:latest";
          container_name = "authentik-server";
          command = "server";
          environment = env-auth;
          volumes = [
            "${config-dir}/media:/media"
            "${config-dir}/custom-templates:/templates"
          ];
          env_file = [ config.age.secrets.authentik-env.path ];
          depends_on = [ "postgresql" "redis" ];
          networks = [ "proxy" "authentik-internal" ]
            ++ (if use-smtp then [ "smtp" ] else [ ]);
          inherit labels;
          restart = "unless-stopped";
        };

        worker.service = {
          image = "ghcr.io/goauthentik/server:latest";
          container_name = "authentik-worker";
          command = "worker";
          user = "root";
          networks = [ "authentik-internal" ]
            ++ (if use-smtp then [ "smtp" ] else [ ]);
          environment = env-auth;
          env_file = [ config.age.secrets.authentik-env.path ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "${config-dir}/media:/media"
            "${config-dir}/certs:/certs"
            "${config-dir}/templates:/templates"
          ];
          depends_on = [ "postgresql" "redis" ];
          restart = "unless-stopped";
        };
      };
    };
  };
}
