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
    env-file = lib.mkOption { type = lib.types.path; };
    server-type = lib.mkOption {
      type = lib.types.str;
      default = "PURPUR";
    };
    rcon = {
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
        default = !cfg.rcon.expose;
      };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.minecraft-env.file = cfg.env-file;

    systemd.services.arion-minecraft = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.minecraft.settings = {
      project.name = "minecraft";

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
            [ ]) ++ (if (cfg.rcon.enable && cfg.rcon.expose) then
              [ "25575:25575/tcp" ]
            else
              [ ]) ++ (if (cfg.rcon.enable && cfg.rcon.internal) then
                [ "${config.server.tailscale-ip}:25575:25575/tcp" ]
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
