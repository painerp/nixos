{ lib, config, ... }:

let
  cfg = config.server.adguardhome;
  config-dir = config.lib.server.mkConfigDir "adguardhome";
in {
  options.server.adguardhome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ah" else "adguardhome";
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    dot = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-adguardhome = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.adguardhome.settings = {
      project.name = "adguardhome";

      networks.proxy.external = true;
      networks.adguardhome.name = "adguardhome";

      services.adguardhome.service = {
        image = "adguard/adguardhome:latest";
        container_name = "adguardhome";
        hostname = config.networking.hostName;
        networks = [ "proxy" "adguardhome" ];
        volumes = [
          "${config-dir}/work:/opt/adguardhome/work"
          "${config-dir}/conf:/opt/adguardhome/conf"
        ];
        environment = { TZ = config.time.timeZone; };
        ports = (if (cfg.expose) then [ "53:53/tcp" "53:53/udp" ] else [ ])
          ++ (if (cfg.dot && cfg.expose) then [ "853:853/tcp" ] else [ ])
          ++ (if (cfg.internal) then [
            "${config.server.tailscale-ip}:53:53/tcp"
            "${config.server.tailscale-ip}:53:53/udp"
          ] else
            [ ]) ++ (if (cfg.dot && cfg.internal) then
              [ "${config.server.tailscale-ip}:853:853/tcp" ]
            else
              [ ]);
        labels = config.lib.server.mkTraefikLabels {
          name = "adguardhome";
          port = "3000";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 53 ];
  };
}
