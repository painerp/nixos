{ lib, config, ... }:

let
  cfg = config.server.nginx;
in
{
  options.server.nginx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ng" else "nginx";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    root = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    rule = lib.mkOption {
      type = lib.types.str;
      default = "Host(`${cfg.subdomain}.${config.server.domain}`)";
    };
    middleware = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    labels = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-nginx = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.nginx.settings = {
      project.name = "nginx";
      networks.proxy.external = true;

      services.nginx.service = {
        image = "nginx:alpine";
        container_name = "nginx";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        sysctls = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
        volumes = [
          "${config.lib.server.mkConfigDir "nginx/public"}:/usr/share/nginx/html:ro"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "nginx";
            port = "80";
            subdomain = cfg.subdomain;
            root = cfg.root;
            rule = cfg.rule;
            forwardAuth = cfg.auth;
            middleware = cfg.middleware;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          }
          // cfg.labels;
        restart = "unless-stopped";
      };
    };
  };
}
