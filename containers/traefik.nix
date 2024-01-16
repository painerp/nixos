{ lib, pkgs, config, secrets, ...}:
let
  cfg = config.server.traefik;
  staticConfig = {
    global = {
			checkNewVersion = false;
			sendAnonymousUsage = false;
		};
		experimental.http3 = true;
    api = {
			dashboard = true;
    	insecure = true;
    	debug = false;
		};
		log = {
		  level = "ERROR";
		  format = "common";
		  filePath = "/var/log/traefik/traefik.log";
		};
		accesslog = {
			format = "common";
			filePath = "/var/log/traefik/access.log";
		};
		providers = {
		  docker = {
		    endpoint = "unix:///var/run/docker.sock";
		    exposedByDefault = false;
		  };
		  file = {
		    directory = "/dynamic";
		    watch = true;
		  };
		};
    entrypoints = {
      http = {
        address = ":80";
        http.redirections.entryPoint = {
          to = "https";
          scheme = "https";
        };
      };
      https = {
        address = ":443";
        http.tls = {
          certResolver = "hetzner";
        };
        http3.advertisedPort = 443;
      };
    } // lib.attrsets.optionalAttrs (cfg.nextcloud-talk-proxy) {
      talktcp.address = ":3478";
      talkudp.address = ":3478/udp";
		};
    certificatesResolvers = {
      hetzner = {
        acme = {
          email = "help@${config.server.base-domain}";
          storage = "acme.json";
          dnsChallenge = {
          	provider = "hetzner";
          	resolvers = [ "213.133.100.98:53" "193.47.99.5:53" "88.198.229.192:53" ];
          };
        };
      };
    };
  };
  staticConfigFile = builtins.toFile "traefik.yaml" (builtins.toJSON staticConfig);
in
{
  options.server.traefik = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "tr" else "traefik";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enabled;
    };
    aliases = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      internal = true;
    };
    wildcard = lib.mkOption {
      type = lib.types.bool;
      description = "Enable wildcard certificate";
      default = false;
    };
	  nextcloud-talk-proxy = lib.mkOption {
	    type = lib.types.bool;
	    description = "Enable proxy for nextcloud talk";
	    default = false;
	  };
  };

  config = lib.mkIf (cfg.enabled) {
    lib.server.mkTraefikLabels = options: (
      let
        name = options.name;
        subdomain = if builtins.hasAttr "subdomain" options then options.subdomain else options.name;
        # created if port is specified
        domain = if builtins.hasAttr "domain" options then options.domain else config.server.domain;
        service = if builtins.hasAttr "service" options then options.service else options.name;
        host = if (builtins.hasAttr "root" options && options.root) then domain else "${subdomain}.${domain}";
        rule = if (builtins.hasAttr "rule" options) then options.rule else "Host(`${host}`)";
        forwardAuth = (builtins.hasAttr "forwardAuth" options && options.forwardAuth);
      in
      {
        "traefik.enable" = "true";
        "traefik.http.routers.${name}.rule" = "${rule}";
        "traefik.http.routers.${name}.entrypoints" = "https";
        "traefik.http.routers.${name}.tls" = "true";
        "traefik.docker.network" = "proxy";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "port" options) {
        "traefik.http.routers.${name}.service" = service;
        "traefik.http.services.${service}.loadbalancer.server.port" = "${options.port}";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "scheme" options) {
        "traefik.http.routers.${name}.service" = service;
        "traefik.http.services.${service}.loadbalancer.server.scheme" = "${options.scheme}";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "service" options) {
        "traefik.http.routers.${name}.service" = service;
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "middleware" options) {
        "traefik.http.routers.${name}.middlewares" = "${options.middleware}";
      } // lib.attrsets.optionalAttrs forwardAuth {
        "traefik.http.routers.${name}.middlewares" = "authentik@docker";
      } // lib.attrsets.optionalAttrs (service == "api@internal" && config.server.traefik.wildcard) {
		    "traefik.http.routers.${name}.tls.domains[0].main" = "${config.server.domain}";
		    "traefik.http.routers.${name}.tls.domains[0].sans" = "*.${config.server.domain}";
      } // lib.attrsets.optionalAttrs (!config.server.traefik.wildcard) {
        "traefik.http.routers.${name}.tls.certresolver" = "hetzner";
      }
    );
    lib.server.mkTraefikAlias = options: (
      let
        domain = if builtins.hasAttr "domain" options then options.domain else config.server.domain;
        host = if (builtins.hasAttr "root" options && options.root) then domain else "${options.subdomain}.${domain}";
      in
      [ "${host}" ]
    );

    age.secrets.traefik-env.file = secrets.traefik-env;

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.traefik.settings = {
      project.name = "traefik";
      networks.proxy.name = "proxy";

      services.traefik.service = {
        image = "traefik:latest";
        container_name = "traefik";
        hostname = config.networking.hostName;
        networks.proxy.aliases = cfg.aliases;
        stop_signal = "SIGINT";
        ports = [
          "80:80/tcp"
          "443:443/tcp"
          "443:443/udp"
        ];
        volumes = [
          "${staticConfigFile}:/traefik.yaml"
          "${config.lib.server.mkConfigDir "traefik" }/acme.json:/acme.json"
          "${config.lib.server.mkConfigDir "traefik" }/logs:/var/log/traefik"
          "${config.lib.server.mkConfigDir "traefik/dynamic" }:/dynamic"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        env_file = [ config.age.secrets.traefik-env.path ];
        labels = config.lib.server.mkTraefikLabels {
          name = "traefik";
          service = "api@internal";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}