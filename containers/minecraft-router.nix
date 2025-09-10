{ lib, config, ... }:

let
  cfg = config.server.minecraft-router;
in
{
  options.server.minecraft-router = {
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
    mapping = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-minecraft-router = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.minecraft-router.settings = {
      project.name = "minecraft-router";

      services.minecraft-router.service = {
        image = "docker.io/itzg/mc-router:latest";
        container_name = "minecraft-router";
        hostname = config.networking.hostName;
        environment.MAPPING = cfg.mapping;
        ports =
          (if (cfg.expose) then [ "25565:25565/tcp" ] else [ ])
          ++ (if (cfg.internal) then [ "${config.server.tailscale-ip}:25565:25565/tcp" ] else [ ]);
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
