{ lib, config, ... }:

let
  cfg = config.server.gluetun;
in
{
  options.server.gluetun = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "gl" else "gluetun";
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
    env-file = lib.mkOption {
      type = lib.types.str;
    };
    internal-ip = lib.mkOption {
      type = lib.types.str;
      default = "${config.server.tailscape-ip}";
    };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.gluetun-env.file = cfg.env-file;

    systemd.services.arion-gluetun = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.gluetun.settings = {
      project.name = "gluetun";
      networks.proxy.external = true;

      services.gluetun.service = {
        image = "ghcr.io/qdm12/gluetun:latest";
        container_name = "gluetun";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        capabilities.NET_ADMIN = true;
        environment = {
          PUID = 1050;
          GUID = 1050;
          UPDATER_PERIOD = "24h";
        };
        env-file = [ config.age.secrets.gluetun-env.path ];
        volumes = [ "${config.lib.server.mkConfigDir "gluetun"}:/gluetun" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "gluetun";
          port = "8000";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}