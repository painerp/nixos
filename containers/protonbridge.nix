{ lib, config, ... }:

let
  cfg = config.server.protonbridge;
in
{
  options.server.protonbridge = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enabled) {
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
        ports = lib.mkIf (cfg.expose) [ "25:25/tcp" ];
        volumes = [
          "${config.lib.server.mkConfigDir "protonbridge"}:/root"
        ];
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 25 ];
  };
}