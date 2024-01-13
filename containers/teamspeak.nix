{ lib, config, secrets, ... }:

let
  cfg = config.server.teamspeak;
in
{
  options.server.teamspeak = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    query = lib.mkOption {
			type = lib.types.bool;
			description = "Enable the query port";
			default = false;
		};
  };

  config = lib.mkIf (cfg.enabled) {
    age.secrets.teamspeak-env.file = secrets.teamspeak-env;

    systemd.services.arion-teamspeak = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.teamspeak.settings = {
      project.name = "teamspeak";
      networks.teamspeak.name = "teamspeak";

      services.teamspeak.service = {
        image = "teamspeak:latest";
        container_name = "teamspeak";
        hostname = config.networking.hostName;
        networks = [ "teamspeak" ];
        environment = {
          TS3SERVER_LICENSE = "accept";
        };
        env_file = [ config.age.secrets.teamspeak-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "teamspeak"}:/var/ts3server"
        ];
        restart = "unless-stopped";
      };
    };
  };
}