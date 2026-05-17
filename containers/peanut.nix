{ lib, config, ... }:

let
  cfg = config.server.peanut;
in
{
  options.server.peanut = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "pn" else "peanut";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-peanut = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.peanut.settings = {
      project.name = "peanut";
      networks.proxy.external = true;

      services.peanut.service = {
        image = "docker.io/brandawg93/peanut:latest";
        container_name = "peanut";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        sysctls = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
        volumes = [
          "${config.lib.server.mkConfigDir "peanut"}:/config"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "peanut";
            port = "8080";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };
    };
  };
}
