{ lib, pkgs, config, secrets, ... }:
let
  cfg = config.server.traefik;
  staticConfig = {
    global = {
      checkNewVersion = false;
      sendAnonymousUsage = false;
    };
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
        http.tls = { certResolver = "hetzner"; };
        http3.advertisedPort = 443;
      };
      metrics.address = ":20003";
    } // lib.attrsets.optionalAttrs (cfg.extra-entrypoints != { })
      cfg.extra-entrypoints;
    certificatesResolvers.hetzner.acme = {
      email = "help@${config.server.base-domain}";
      storage = "acme.json";
      dnsChallenge = {
        provider = "hetzner";
        resolvers =
          [ "213.133.100.98:53" "193.47.99.5:53" "88.198.229.192:53" ];
      };
    };
  } // lib.attrsets.optionalAttrs cfg.monitoring {
    metrics.prometheus = {
      entryPoint = "metrics";
      addEntryPointsLabels = true;
      addServicesLabels = true;
    };
  };
  staticConfigFile =
    builtins.toFile "traefik.yaml" (builtins.toJSON staticConfig);
in {
  options.server.traefik = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "tr" else "traefik";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    aliases = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      internal = true;
    };
    wildcard = lib.mkOption {
      type = lib.types.bool;
      description = "Enable wildcard certificate";
      default = false;
    };
    monitoring = lib.mkOption {
      type = lib.types.bool;
      description = "Enable traefik monitoring";
      default = true;
    };
    extra-entrypoints = lib.mkOption {
      type = lib.types.attrs;
      description = "add extra entrypoints to static traefik config";
      default = { };
    };
    extra-ports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "add extra ports to traefik service";
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    lib.server.mkTraefikLabels = options:
      (let
        name = options.name;
        subdomain = if builtins.hasAttr "subdomain" options then
          options.subdomain
        else
          options.name;
        # created if port is specified
        domain = if builtins.hasAttr "domain" options then
          options.domain
        else
          config.server.domain;
        service = if builtins.hasAttr "service" options then
          options.service
        else
          options.name;
        host = if (builtins.hasAttr "root" options && options.root) then
          domain
        else
          "${subdomain}.${domain}";
        rule = if (builtins.hasAttr "rule" options) then
          options.rule
        else
          "Host(`${host}`)";
        forwardAuth =
          (builtins.hasAttr "forwardAuth" options && options.forwardAuth);
      in {
        "traefik.enable" = "true";
        "traefik.http.routers.${name}.rule" = "${rule}";
        "traefik.http.routers.${name}.entrypoints" = "https";
        "traefik.http.routers.${name}.tls" = "true";
        "traefik.http.routers.${name}.tls.certresolver" = "hetzner";
        "traefik.http.routers.${name}.service" = service;
        "traefik.docker.network" = "proxy";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "port" options) {
        "traefik.http.services.${service}.loadbalancer.server.port" =
          "${options.port}";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "scheme" options) {
        "traefik.http.services.${service}.loadbalancer.server.scheme" =
          "${options.scheme}";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "transport" options) {
        "traefik.http.services.${name}.loadbalancer.serverstransport" =
          "${options.transport}";
      } // lib.attrsets.optionalAttrs (builtins.hasAttr "middleware" options) {
        "traefik.http.routers.${name}.middlewares" = "${options.middleware}";
      } // lib.attrsets.optionalAttrs forwardAuth {
        "traefik.http.routers.${name}.middlewares" = "authentik@docker";
      } // lib.attrsets.optionalAttrs
      (service == "api@internal" && config.server.traefik.wildcard) {
        "traefik.http.routers.${name}.tls.domains[0].main" =
          "${config.server.domain}";
        "traefik.http.routers.${name}.tls.domains[0].sans" =
          "*.${config.server.domain}";
      });
    lib.server.mkTraefikAlias = options:
      (let
        domain = if builtins.hasAttr "domain" options then
          options.domain
        else
          config.server.domain;
        host = if (builtins.hasAttr "root" options && options.root) then
          domain
        else
          "${options.subdomain}.${domain}";
      in [ "${host}" ]);

    age.secrets.traefik-env.file = secrets.traefik-env;

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    boot.kernel.sysctl = {
      "net.core.rmem_max" = 2500000;
      "net.core.wmem_max" = 2500000;
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
        ports = (if (cfg.expose) then [
          "80:80/tcp"
          "443:443/tcp"
          "443:443/udp"
        ] else
          [ ]) ++ (if (cfg.internal) then [
            "${config.server.tailscale-ip}:80:80/tcp"
            "${config.server.tailscale-ip}:443:443/tcp"
            "${config.server.tailscale-ip}:443:443/udp"
          ] else
            [ ]) ++ (if (cfg.monitoring) then
              [ "${config.server.tailscale-ip}:20003:20003/tcp" ]
            else
              [ ]) ++ cfg.extra-ports;
        volumes = [
          "${staticConfigFile}:/traefik.yaml"
          "${config.lib.server.mkConfigDir "traefik"}/acme.json:/acme.json"
          "${config.lib.server.mkConfigDir "traefik"}/logs:/var/log/traefik"
          "${config.lib.server.mkConfigDir "traefik/dynamic"}:/dynamic"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        env_file = [ config.age.secrets.traefik-env.path ];
        labels = config.lib.server.mkTraefikLabels {
          name = "traefik";
          service = "api@internal";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        } // {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
