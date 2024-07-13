{ lib, config, secrets, ... }:

let cfg = config.server.renovate;
in {
  options.server.renovate = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    timer = lib.mkOption {
      type = lib.types.str;
      default = "5m";
    };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.renovate-env.file = cfg.env-file;
    systemd.services.arion-renovate = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.timers."renovate" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.timer;
        OnUnitInactiveSec = cfg.timer;
        Unit = "arion-renovate.service";
      };
    };

    virtualisation.arion.projects.renovate.settings = {
      project.name = "renovate";

      services.renovate.service = {
        image = "renovate/renovate:latest";
        container_name = "renovate";
        hostname = config.networking.hostName;
        environment = {
          RENOVATE_PLATFORM = "gitea";
          RENOVATE_AUTODISCOVER = "true";
          RENOVATE_OPTIMIZE_FOR_DISABLED = "true";
          RENOVATE_PERSIST_REPO_DATA = "true";
        };
        env_file = [ config.age.secrets.renovate-env.path ];
      };
    };
  };
}
