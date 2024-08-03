{ lib, config, ... }:

let cfg = config.server.minecraft;
in {
  options.server.minecraft = {
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
    server-type = lib.mkOption {
      type = lib.types.str;
      default = "PURPUR";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-minecraft = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.minecraft.settings = {
      project.name = "minecraft";
      networks.proxy.external = true;

      services.minecraft.service = {
        image = "itzg/minecraft-server:latest";
        container_name = "minecraft";
        hostname = config.networking.hostName;
        tty = true;
        environment = {
          EULA = "TRUE";
          TYPE = cfg.server-type;
          SNOOPER_ENABLED = "FALSE";
        };
        ports = (if (cfg.expose) then [ "25565:25565/tcp" ] else [ ])
          ++ (if (cfg.internal) then
            [ "${config.server.tailscale-ip}:25565:25565/tcp" ]
          else
            [ ]);
        volumes = [ "${config.lib.server.mkConfigDir "minecraft"}:/data" ];
        labels = { "com.centurylinklabs.watchtower.enable" = "false"; };
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 25565 ];
  };
}
