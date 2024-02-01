{ lib, config, secrets, ... }:

let cfg = config.server.teamspeak;
in {
  options.server.teamspeak = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.teamspeak-env.file = cfg.env-file;

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
        environment = { TS3SERVER_LICENSE = "accept"; };
        ports = lib.mkIf (cfg.expose) [ "9987:9987/udp" "30033:30033/tcp" ];
        env_file = [ config.age.secrets.teamspeak-env.path ];
        volumes =
          [ "${config.lib.server.mkConfigDir "teamspeak"}:/var/ts3server" ];
        restart = "unless-stopped";
      };
    };

    networking.firewall = {
      allowedUDPPorts = lib.mkIf (cfg.expose) [ 9987 ];
      allowedTCPPorts = lib.mkIf (cfg.expose) [ 30033 ];
    };
  };
}
