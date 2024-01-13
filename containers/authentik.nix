{ lib, config, secrets, ... }:

let
  cfg = config.server.authentik;
  config-dir = config.lib.server.mkConfigDir "authentik";
in
{
  options.server.authentik = {
		enabled = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
		subdomain = lib.mkOption {
			type = lib.types.str;
			default = if config.server.short-subdomain then "auth" else "authentik";
		};
  };

  config = lib.mkIf (cfg.enabled) {
		age.secrets.authentik-env.file = secrets.authentik-env;
		age.secrets.authentik-pg-env.file = secrets.authentik-pg-env;

		systemd.services.arion-authentik = {
			wants = [ "network-online.target" ];
			after = [ "network-online.target" ];
		};

		virtualisation.arion.projects.authentik.settings = {
			project.name = "authentik";
			networks.proxy.external = true;
			networks.smtp.external = true;
			networks.authentik-internal.internal = true;

				services = {
				postgresql.service = {
					image = "docker.io/library/postgres:12-alpine";
					container_name = "authentik-pg";
					restart = "unless-stopped";
					healthcheck = {
						test = [
							"CMD-SHELL"
							"pg_isready -d authentik -U authentik"
						];
						start_period = "20s";
						interval = "30s";
						retries = 5;
						timeout = "5s";
					};
					volumes = [ "${config-dir}/database:/var/lib/postgresql/data" ];
					networks = [ "authentik-internal" ];
					environment = {
						POSTGRES_USER = "authentik";
						POSTGRES_DB = "authentik";
					};
					env_file = [ config.age.secrets.authentik-pg-env.path ];
				};

				redis.service = {
					image = "docker.io/library/redis:alpine";
					container_name = "authentik-redis";
					command = "--save 60 1 --loglevel warning";
					restart = "unless-stopped";
					healthcheck = {
						test = [ "CMD-SHELL" "redis-cli ping | grep PONG" ];
						start_period = "20s";
						interval = "30s";
						retries = 5;
						timeout = "3s";
					};
					volumes = [ "${config-dir}/redis:/data" ];
					networks = [ "authentik-internal" ];
				};

				server.service = {
					image = "ghcr.io/goauthentik/server:latest";
					container_name = "authentik-server";
					restart = "unless-stopped";
					command = "server";
					environment = {
						AUTHENTIK_REDIS__HOST = "authentik-redis";
						AUTHENTIK_POSTGRESQL__HOST = "authentik-pg";
						AUTHENTIK_POSTGRESQL__USER = "authentik";
						AUTHENTIK_POSTGRESQL__NAME = "authentik";
						AUTHENTIK_EMAIL__HOST = "protonbridge";
						AUTHENTIK_EMAIL__PORT = 25;
						AUTHENTIK_EMAIL__TIMEOUT = 10;
					};
					volumes = [
						"${config-dir}/media:/media"
						"${config-dir}/custom-templates:/templates"
					];
					env_file = [ config.age.secrets.authentik-env.path ];
					depends_on = [ "postgresql" "redis" ];
					networks = [
						"proxy"
						"authentik-internal"
						"smtp"
					];
					labels = config.lib.server.mkTraefikLabels {
						name = "authentik";
						port = "9000";
						subdomain = "${cfg.subdomain}";
						rule = "(Host(`${cfg.subdomain}.${config.server.domain}`) || HostRegexp(`{subdomain:[a-z0-9]+}.${config.server.domain}`) && PathPrefix(`/outpost.goauthentik.io/`))";
					} // {
						"traefik.http.middlewares.authentik.forwardauth.address" = "http://authentik-server:9000/outpost.goauthentik.io/auth/traefik";
						"traefik.http.middlewares.authentik.forwardauth.trustForwardHeader" = "true";
						"traefik.http.middlewares.authentik.forwardauth.authResponseHeaders" = "X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid,X-authentik-jwt,X-authentik-meta-jwks,X-authentik-meta-outpost,X-authentik-meta-provider,X-authentik-meta-app,X-authentik-meta-version";
					};
				};

				worker.service = {
					image = "ghcr.io/goauthentik/server:latest";
					container_name = "authentik-worker";
					restart = "unless-stopped";
					command = "worker";
					networks = [ "authentik-internal" "smtp" ];
					environment = {
						AUTHENTIK_REDIS__HOST = "authentik-redis";
						AUTHENTIK_POSTGRESQL__HOST = "authentik-pg";
						AUTHENTIK_POSTGRESQL__USER = "authentik";
						AUTHENTIK_POSTGRESQL__NAME = "authentik";
						AUTHENTIK_EMAIL__HOST = "protonbridge";
						AUTHENTIK_EMAIL__PORT = 25;
						AUTHENTIK_EMAIL__TIMEOUT = 10;
					};
					user = "root";
					volumes = [
						"/var/run/docker.sock:/var/run/docker.sock"
						"${config-dir}/media:/media"
						"${config-dir}/certs:/certs"
						"${config-dir}/templates:/templates"
					];
					env_file = [ config.age.secrets.authentik-env.path ];
					depends_on = [ "postgresql" "redis" ];
				};
			};
		};
	};
}