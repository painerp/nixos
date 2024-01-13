{ lib, config, secrets, ... }:

let
  cfg = config.server.watchtower;
in
{
  options.server.watchtower = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enabled) {
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
        environment = {
          WATCHTOWER_CLEANUP = "true";
          WATCHTOWER_SCHEDULE = "0 0 */6 * * *";
        };
        env_file = [ config.age.secrets.watchtower-env.path ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/root/.docker/config.json:/config.json"
          "/etc/localtime:/etc/localtime:ro"
        ];
        restart = "unless-stopped";
      };
    };
  };
}