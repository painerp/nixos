{ lib, config, ... }:

let
  cfg = config.server.forgejo-runner;
in
{
  options.server.forgejo-runner = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    version = lib.mkOption { type = lib.types.str; };
    config-file = lib.mkOption {
      type = lib.types.path;
      description = "Runner config.yml incl. labels and server.connections (url, uuid, token)";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.forgejo-runner-config.file = cfg.config-file;

    systemd.services.arion-forgejo-runner = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.forgejo-runner.settings = {
      project.name = "forgejo-runner";

      services.forgejo-runner.service = {
        image = "data.forgejo.org/forgejo/runner:${cfg.version}";
        container_name = "forgejo-runner";
        hostname = config.networking.hostName;
        user = "0:0";
        command = [
          "/bin/forgejo-runner"
          "daemon"
          "--config"
          "/config.yml"
        ];
        volumes = [
          "${config.lib.server.mkConfigDir "forgejo-runner"}:/data"
          "${config.age.secrets.forgejo-runner-config.path}:/config.yml:ro"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        labels = {
          "com.centurylinklabs.watchtower.enable" = "false";
        };
        restart = "unless-stopped";
      };
    };
  };
}
