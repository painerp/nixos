{ lib, config, ... }:

let
  cfg = config.server.gotify;
in
{
  options.server.gotify = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "go" else "gotify";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enabled;
    };
  };

  config = lib.mkIf (cfg.enabled) {
    systemd.services.arion-gotify = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.gotify.settings = {
      project.name = "gotify";
      networks.proxy.external = true;

      services.gotify.service = {
        image = "gotify/server:latest";
        container_name = "gotify";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          TZ = "Europe/Berlin";
        };
        volumes = [
          "${config.lib.server.mkConfigDir "gotify"}:/app/data"
        ];
        labels = config.lib.server.mkTraefikLabels {
          name = "gotify";
          port = "80";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}