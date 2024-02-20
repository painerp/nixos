{ lib, config, ... }:

let cfg = config.server.protonbridge;
in {
  options.server.protonbridge = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-protonbridge = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.protonbridge.settings = {
      project.name = "protonbridge";

      services.protonbridge.service = {
        image = "shenxn/protonmail-bridge:latest";
        container_name = "protonbridge";
        hostname = config.networking.hostName;
        ports = (if (cfg.expose) then [ "25:25/tcp" ] else [ ])
          ++ (if (cfg.internal) then
            [ "${config.server.tailscale-ip}:25:25/tcp" ]
          else
            [ ]);
        volumes = [ "${config.lib.server.mkConfigDir "protonbridge"}:/root" ];
        labels = {
          "traefik.enable" = "true";
          "traefik.tcp.routers.protonbridge.rule" = "HostSNI(`*`)";
          "traefik.tcp.routers.protonbridge.entrypoints" = "smtp";
          "traefik.tcp.routers.protonbridge.service" = "protonbridge";
          "traefik.tcp.services.protonbridge.loadbalancer.server.port" = "25";
          "traefik.tcp.services.protonbridge.loadbalancer.proxyProtocol.version" =
            "2";
        };
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 25 ];
  };
}
