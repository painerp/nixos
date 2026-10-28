{
  lib,
  pkgs,
  config,
  secrets,
  ...
}:
let
  cfg = config.server.traefik;
  tn = import ../tailnet.nix;
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
      file.filename = "/dynamic.yaml";
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
      metrics.address = ":20003";
    }
    // lib.attrsets.optionalAttrs (cfg.extra-entrypoints != { }) cfg.extra-entrypoints;
    certificatesResolvers.hetzner.acme = {
      email = "help@${config.server.base-domain}";
      storage = "acme.json";
      dnsChallenge = {
        provider = "hetzner";
        resolvers = [
          "213.133.100.98:53"
          "193.47.99.5:53"
          "88.198.229.192:53"
        ];
      };
    };
  }
  // lib.attrsets.optionalAttrs cfg.monitoring {
    metrics.prometheus = {
      entryPoint = "metrics";
      addEntryPointsLabels = true;
      addServicesLabels = true;
    };
  };
  staticConfigFile = builtins.toFile "traefik.yaml" (builtins.toJSON staticConfig);
  dynamicConfigFile = builtins.toFile "traefik-dynamic.yaml" (
    builtins.toJSON config.lib.server.traefikDynamic
  );
in
{
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
    extra-hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "add extra hosts to traefik service";
      default = [ ];
    };
    dynamic = lib.mkOption {
      type = (pkgs.formats.json { }).type;
      description = "traefik dynamic config for the file provider (routes to non-container targets, shared middlewares)";
      default = { };
    };
    restrict-servers = lib.mkOption {
      type = lib.types.bool;
      description = "block the tailnet.nix hosts from every router they aren't granted in their outgoing";
      default = false;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    lib.server.mkTraefikRule =
      name: rule:
      let
        hostName = config.networking.hostName;
        granted = tn.incoming.${hostName}.${name} or [ ];
        blocked = lib.attrValues (removeAttrs tn.hosts ([ hostName ] ++ granted));
      in
      {
        # traefik rejects an empty `!()`
        rule =
          if !cfg.restrict-servers || blocked == [ ] then
            rule
          else
            "(${rule}) && !(${lib.concatMapStringsSep " || " (ip: "ClientIP(`${ip}`)") blocked})";
        # traefik's default priority, so the guard doesn't reorder routers
        priority = lib.stringLength rule;
      };
    lib.server.mkTraefikRoute =
      {
        name,
        url,
        subdomain ? name,
        middlewares ? [ "default-headers" ],
        transport ? null,
      }:
      {
        http.routers.${name} = {
          rule = "Host(`${subdomain}.${config.server.domain}`)";
          entryPoints = [ "https" ];
          tls.certResolver = "hetzner";
          service = name;
        }
        // lib.optionalAttrs (middlewares != [ ]) { inherit middlewares; };
        http.services.${name}.loadBalancer = {
          servers = [ { inherit url; } ];
        }
        // lib.optionalAttrs (transport != null) { serversTransport = transport; };
      };
    lib.server.traefikDynamic = cfg.dynamic // {
      http = (cfg.dynamic.http or { }) // {
        routers = lib.mapAttrs (
          name: router:
          let
            guarded = config.lib.server.mkTraefikRule name router.rule;
          in
          router
          // {
            inherit (guarded) rule;
          }
          // lib.optionalAttrs (guarded.rule != router.rule) { inherit (guarded) priority; }
        ) (cfg.dynamic.http.routers or { });
      };
    };
    server.traefik.dynamic.http = {
      serversTransports.skip-verify.insecureSkipVerify = true;
      middlewares.default-headers.headers = {
        frameDeny = true;
        browserXssFilter = true;
        contentTypeNosniff = true;
        forceSTSHeader = true;
        stsIncludeSubdomains = true;
        stsPreload = true;
        stsSeconds = 15552000;
        customFrameOptionsValue = "SAMEORIGIN";
        customRequestHeaders.X-Forwarded-Proto = "https";
        hostsProxyHeaders = [ "X-Forwarded-Host" ];
        referrerPolicy = "same-origin";
      };
    };
    lib.server.mkTraefikLabels =
      options:
      (
        let
          name = options.name;
          subdomain = if builtins.hasAttr "subdomain" options then options.subdomain else options.name;
          # created if port is specified
          domain = if builtins.hasAttr "domain" options then options.domain else config.server.domain;
          service = if builtins.hasAttr "service" options then options.service else options.name;
          host =
            if (builtins.hasAttr "root" options && options.root) then domain else "${subdomain}.${domain}";
          rule = if (builtins.hasAttr "rule" options) then options.rule else "Host(`${host}`)";
          guarded = config.lib.server.mkTraefikRule name rule;
          forwardAuth = (builtins.hasAttr "forwardAuth" options && options.forwardAuth);
          compress = (builtins.hasAttr "compress" options && options.compress);
          middlewares = lib.filter (m: m != "") (
            lib.optional forwardAuth "authentik@docker"
            ++ lib.optional (builtins.hasAttr "middleware" options) options.middleware
            ++ lib.optional compress "compress@docker"
          );
        in
        {
          "traefik.enable" = "true";
          "traefik.http.routers.${name}.rule" = guarded.rule;
          "traefik.http.routers.${name}.entrypoints" = "https";
          "traefik.http.routers.${name}.tls" = "true";
          "traefik.http.routers.${name}.tls.certresolver" = "hetzner";
          "traefik.http.routers.${name}.service" = service;
          "traefik.docker.network" = "proxy";
        }
        // lib.attrsets.optionalAttrs (guarded.rule != rule) {
          "traefik.http.routers.${name}.priority" = toString guarded.priority;
        }
        // lib.attrsets.optionalAttrs (builtins.hasAttr "port" options) {
          "traefik.http.services.${service}.loadbalancer.server.port" = "${options.port}";
        }
        // lib.attrsets.optionalAttrs (builtins.hasAttr "scheme" options) {
          "traefik.http.services.${service}.loadbalancer.server.scheme" = "${options.scheme}";
        }
        // lib.attrsets.optionalAttrs (builtins.hasAttr "transport" options) {
          "traefik.http.services.${name}.loadbalancer.serverstransport" = "${options.transport}";
        }
        // lib.attrsets.optionalAttrs (middlewares != [ ]) {
          "traefik.http.routers.${name}.middlewares" = lib.concatStringsSep "," middlewares;
        }
        // lib.attrsets.optionalAttrs (service == "api@internal" && config.server.traefik.wildcard) {
          "traefik.http.routers.${name}.tls.domains[0].main" = "${config.server.domain}";
          "traefik.http.routers.${name}.tls.domains[0].sans" = "*.${config.server.domain}";
        }
      );
    lib.server.mkTraefikAlias =
      options:
      (
        let
          domain = if builtins.hasAttr "domain" options then options.domain else config.server.domain;
          host =
            if (builtins.hasAttr "root" options && options.root) then
              domain
            else
              "${options.subdomain}.${domain}";
        in
        [ "${host}" ]
      );

    age.secrets.traefik-env.file = secrets.traefik-env;

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    boot.kernel.sysctl = {
      "net.core.rmem_max" = 2500000;
      "net.core.wmem_max" = 2500000;
    };

    services.logrotate = {
      enable = true;
      settings.traefik = {
        files = "${config.lib.server.mkConfigDir "traefik/logs"}/access.log";
        frequency = "daily";
        rotate = 90;
        missingok = true;
        notifempty = true;
        compress = true;
        minsize = "10M";
        postrotate = ''
          /run/current-system/sw/bin/docker kill --signal="USR1" traefik
        '';
      };
    };

    systemd.services.logrotate.serviceConfig = {
      ReadWritePaths = [ "${config.lib.server.mkConfigDir "traefik/logs"}" ];
      ProtectHome = lib.mkForce false;
    };

    virtualisation.arion.projects.traefik.settings = {
      project.name = "traefik";
      networks.proxy.name = "proxy";

      services.traefik.service = {
        image = "docker.io/traefik:latest";
        container_name = "traefik";
        hostname = config.networking.hostName;
        networks.proxy.aliases = cfg.aliases;
        stop_signal = "SIGINT";
        extra_hosts = cfg.extra-hosts;
        ports =
          (
            if (cfg.expose) then
              [
                "80:80/tcp"
                "443:443/tcp"
                "443:443/udp"
              ]
            else
              [ ]
          )
          ++ (
            if (cfg.internal) then
              [
                "${config.server.tailscale-ip}:80:80/tcp"
                "${config.server.tailscale-ip}:443:443/tcp"
                "${config.server.tailscale-ip}:443:443/udp"
              ]
            else
              [ ]
          )
          ++ (if (cfg.monitoring) then [ "127.0.0.1:20003:20003/tcp" ] else [ ])
          ++ cfg.extra-ports;
        volumes = [
          "${staticConfigFile}:/traefik.yaml"
          "${config.lib.server.mkConfigDir "traefik"}/acme.json:/acme.json"
          "${config.lib.server.mkConfigDir "traefik/logs"}:/var/log/traefik"
          "${dynamicConfigFile}:/dynamic.yaml:ro"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        env_file = [ config.age.secrets.traefik-env.path ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "traefik";
            service = "api@internal";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "traefik.http.middlewares.compress.compress" = "true";
            "traefik.http.middlewares.compress.compress.includedContentTypes" =
              "text/html,text/css,text/plain,text/javascript,application/javascript,application/json,application/manifest+json,image/svg+xml,application/xml";
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };
    };
  };
}
