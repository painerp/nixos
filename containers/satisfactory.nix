{ lib, config, ... }:

let
  cfg = config.server.satisfactory;
in
{
  options.server.satisfactory = {
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

    systemd.services.arion-satisfactory = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.satisfactory.settings = {
      project.name = "satisfactory";

      services.satisfactory.service = {
        image = "docker.io/wolveix/satisfactory-server:latest";
        container_name = "satisfactory";
        stop_grace_period = "30s";
        hostname = config.networking.hostName;
        environment = {
          PUID = 1102;
          GUID = 1102;
          MAXPLAYERS = "4";
          STEAMBETA = "false";
          AUTOPAUSE = "false";
          AUTOSAVENUM = "20";
        };
        ports =
          (
            if cfg.expose then
              [
                "7777:7777"
                "8888:8888/tcp"
              ]
            else
              [ ]
          )
          ++ (
            if cfg.internal then
              [
                "${config.server.tailscale-ip}:7777:7777"
                "${config.server.tailscale-ip}:8888:8888/tcp"
              ]
            else
              [ ]
          );
        volumes = [ "${config.lib.server.mkConfigDir "satisfactory"}:/config" ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
