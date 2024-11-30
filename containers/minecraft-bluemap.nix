{ lib, config, ... }:

let
  cfg = config.server.minecraft-bluemap;
  config-dir = config.lib.server.mkConfigDir "minecraft-bluemap";
in
{
  options.server.minecraft-bluemap = {
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
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-minecraft-bluemap = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.minecraft-bluemap.settings = {
      project.name = "minecraft-bluemap";

      services.minecraft-bluemap.service = {
        image = "ghcr.io/bluemap-minecraft/bluemap:latest";
        container_name = "minecraft-bluemap";
        hostname = config.networking.hostName;
        command = "-r -u -w";
        ports =
          (if (cfg.expose) then [ "25569:8100/tcp" ] else [ ])
          ++ (if (cfg.internal) then [ "${config.server.tailscale-ip}:25569:8100/tcp" ] else [ ]);
        volumes = [
          "${config-dir}/config:/app/config"
          "${config-dir}/data:/app/data"
          "${config-dir}/web:/app/web"
        ] ++ cfg.volumes;
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
