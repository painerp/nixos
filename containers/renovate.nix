{ lib, config, secrets, ... }:

let cfg = config.server.renovate;
in {
  options.server.renovate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-renovate = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.renovate.settings = {
      project.name = "renovate";

      services.renovate.service = {
        image = "renovate/renovate:latest";
        container_name = "renovate";
        hostname = config.networking.hostName;
        volumes = [
          "${
            config.lib.server.mkConfigDir "renovate"
          }/config.js:/usr/src/app/config.js"
        ];
        restart = "unless-stopped";
      };
    };
  };
}
