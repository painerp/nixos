{ lib, config, ... }:

let
  cfg = config.server.protonbridge;
in
{
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
    image = lib.mkOption {
      type = lib.types.str;
      default = "shenxn/protonmail-bridge:latest";
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
        image = "${cfg.image}";
        container_name = "protonbridge";
        hostname = config.networking.hostName;
        ports =
          (if (cfg.expose) then [ "25:25/tcp" ] else [ ])
          ++ (if (cfg.internal) then [ "${config.server.tailscale-ip}:25:25/tcp" ] else [ ]);
        volumes = [ "${config.lib.server.mkConfigDir "protonbridge"}:/root" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
