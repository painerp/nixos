{ lib, config, ... }:

let cfg = config.server.palworld;
in {
  options.server.palworld = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.palworld-env.file = cfg.env-file;

    systemd.services.arion-palworld = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.palworld.settings = {
      project.name = "palworld";

      services.palworld.service = {
        image = "thijsvanloef/palworld-server-docker:latest";
        container_name = "palworld";
        stop_grace_period = "30s";
        hostname = config.networking.hostName;
        environment = {
          PUID = 1050;
          GUID = 1050;
          PORT = "8211";
          PLAYERS = "16";
          MULTITHREADING = "true";
          RCON_ENABLED = "true";
          RCON_PORT = "25575";
          TZ = "UTC";
          COMMUNITY = "false";
        };
        env_file = [ config.age.secrets.palworld-env.path ];
        ports = (if cfg.expose then [ "8211:8211/udp" ] else [ ])
          ++ (if cfg.internal then
            [ "${config.server.tailscale-ip}:8211:8211/udp" ]
          else
            [ ]);
        volumes = [ "${config.lib.server.mkConfigDir "palworld"}:/palworld" ];
        labels = { "com.centurylinklabs.watchtower.enable" = "true"; };
        restart = "unless-stopped";
      };
    };
  };
}
