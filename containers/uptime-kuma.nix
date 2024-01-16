{ lib, config, ... }:

let
  cfg = config.server.uptime-kuma;
in
{
  options.server.uptime-kuma = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "up" else "uptime-kuma";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enabled;
    };
  };

  config = lib.mkIf (cfg.enabled) {
    systemd.services.arion-uptime-kuma = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.uptime-kuma.settings = {
      project.name = "uptime-kuma";
      networks.proxy.external = true;

      services.uptime-kuma.service = {
        image = "louislam/uptime-kuma:latest";
        container_name = "uptime-kuma";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        volumes = [
          "${config.lib.server.mkConfigDir "uptime-kuma"}:/app/data"
        ];
        labels = config.lib.server.mkTraefikLabels {
          name = "uptime-kuma";
          port = "3001";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}