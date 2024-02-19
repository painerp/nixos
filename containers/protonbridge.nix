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
      networks.smtp.name = "smtp";

      services.protonbridge.service = {
        image = "shenxn/protonmail-bridge:latest";
        container_name = "protonbridge";
        hostname = config.networking.hostName;
        networks = [ "smtp" ];
        ports = (if (cfg.expose) then [ "25:25/tcp" ] else [ ])
          ++ (if (cfg.internal) then
            [ "${config.server.tailscale-ip}:25:25/tcp" ]
          else
            [ ]);
        volumes = [ "${config.lib.server.mkConfigDir "protonbridge"}:/root" ];
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 25 ];
  };
}
