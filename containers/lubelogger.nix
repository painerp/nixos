{ lib, config, ... }:

let
  cfg = config.server.lubelogger;
  config-dir = config.lib.server.mkConfigDir "lubelogger";
in
{
  options.server.lubelogger = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ll" else "lubelogger";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-lubelogger = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.lubelogger.settings = {
      project.name = "lubelogger";
      networks.proxy.external = true;

      services.lubelogger.service = {
        image = "ghcr.io/hargata/lubelogger:latest";
        container_name = "lubelogger";
        hostname = config.networking.hostName;
        networks = [
          "proxy"
        ];
        volumes = [
          "${config-dir}/data:/App/data"
          "${config-dir}/keys:/root/.aspnet/DataProtection-Keys"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "lubelogger";
            port = "8080";
            subdomain = "${cfg.subdomain}";
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };
    };
  };
}
