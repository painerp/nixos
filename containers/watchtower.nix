{
  lib,
  config,
  secrets,
  ...
}:

let
  cfg = config.server.watchtower;
in
{
  options.server.watchtower = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal-services = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "0 0 */6 * * *";
    };
    only-label = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    rolling-restart = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    delay-notification = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.watchtower-env.file = secrets.watchtower-env;

    systemd.services.arion-watchtower = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.watchtower.settings = {
      project.name = "watchtower";

      services.watchtower.service = {
        image = "containrrr/watchtower:latest";
        container_name = "watchtower";
        hostname = config.networking.hostName;
        environment =
          {
            WATCHTOWER_CLEANUP = "true";
            WATCHTOWER_SCHEDULE = cfg.schedule;
          }
          // lib.attrsets.optionalAttrs (cfg.rolling-restart) { WATCHTOWER_ROLLING_RESTART = "true"; }
          // lib.attrsets.optionalAttrs (cfg.only-label) { WATCHTOWER_LABEL_ENABLE = "true"; }
          // lib.attrsets.optionalAttrs (cfg.delay-notification) { WATCHTOWER_NOTIFICATIONS_DELAY = "120"; };
        env_file = [ config.age.secrets.watchtower-env.path ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/etc/localtime:/etc/localtime:ro"
        ] ++ (if (cfg.internal-services) then [ "/root/.docker/config.json:/config.json" ] else [ ]);
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
