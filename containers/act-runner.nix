{ lib, config, ... }:

let
  cfg = config.server.act-runner;
in
{
  options.server.act-runner = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    env-file = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.act-runner-env.file = cfg.env-file;

    systemd.services.arion-act-runner = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.act-runner.settings = {
      project.name = "act-runner";

      services.act-runner.service = {
        image = "gitea/act_runner:latest";
        container_name = "act-runner";
        hostname = config.networking.hostName;
        env_file = [ config.age.secrets.act-runner-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "act-runner"}:/data"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        restart = "unless-stopped";
      };
    };
  };
}