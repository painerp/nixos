{ lib, config, ... }:

let
  cfg = config.server.adguardhome;
  config-dir = config.lib.server.mkConfigDir "adguardhome";
in
{
  options.server.adguardhome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
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

    virtualisation.arion.projects.adguardhome.settings = {
      project.name = "adguardhome";

      services.adguardhome.service = {
        image = "docker.io/adguard/adguardhome:latest";
        container_name = "adguardhome";
        network_mode = "host";
        volumes = [
          "${config-dir}/work:/opt/adguardhome/work"
          "${config-dir}/conf:/opt/adguardhome/conf"
        ];
        environment = {
          TZ = config.time.timeZone;
        };
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };

    networking.firewall = lib.mkIf (cfg.expose) {
      allowedTCPPorts = [ 53 ] ++ (if (cfg.dot) then [ 853 ] else [ ]);
      allowedUDPPorts = [ 53 ];
    };
  };
}
