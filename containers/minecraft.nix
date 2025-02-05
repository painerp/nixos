{ lib, config, ... }:

let
  cfg = config.server.minecraft;
  config-dir = config.lib.server.mkConfigDir "minecraft";
in
{
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
    max-memory = lib.mkOption {
      type = lib.types.str;
      default = "4G";
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
    backup = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      interval = lib.mkOption {
        type = lib.types.str;
        default = "24h";
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
          MAX_MEMORY = cfg.max-memory;
          VANILLATWEAKS_FILE = "/config/vt-datapacks.json,/config/vt-craftingtweaks.json";
        };
        env_file = [ config.age.secrets.minecraft-env.path ];
        ports =
          (if (cfg.expose) then [ "25565:25565/tcp" ] else [ ])
          ++ (if (cfg.internal) then [ "${config.server.tailscale-ip}:25565:25565/tcp" ] else [ ])
          ++ (if (cfg.rcon.enable && cfg.rcon.expose) then [ "25575:25575/tcp" ] else [ ])
          ++ (
            if (cfg.rcon.enable && cfg.rcon.internal) then
              [ "${config.server.tailscale-ip}:25575:25575/tcp" ]
            else
              [ ]
          );
        volumes = [ "${config.lib.server.mkConfigDir "minecraft"}:/data" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "false";
        };
        restart = "unless-stopped";
      };

      services.minecraft-backup.service = lib.mkIf (cfg.backup.enable) {
        image = "itzg/mc-backup:latest";
        container_name = "minecraft-backup";
        hostname = config.networking.hostName;
        environment = {
          RCON_HOST = "minecraft";
          PAUSE_IF_NO_PLAYERS = "TRUE";
          BACKUP_INTERVAL = cfg.backup.interval;
          EXCLUDES = "cache,logs,*.tmp";
        };
        env_file = [ config.age.secrets.minecraft-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "minecraft-backups"}:/backups"
          "${config-dir}:/data"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 25565 ];
  };
}
