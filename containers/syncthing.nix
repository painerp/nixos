{ lib, config, ... }:

let
  cfg = config.server.syncthing;
in
{
  options.server.syncthing = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "st" else "syncthing";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    path = lib.mkOption {
      type = lib.types.str;
      description = "Path to the syncthing data directory";
      default = "${config.lib.server.mkConfigDir "syncthing"}";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-syncthing = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.syncthing.settings = {
      project.name = "syncthing";
      networks.proxy.external = true;

      services.syncthing.service = {
        image = "docker.io/syncthing/syncthing:latest";
        container_name = "syncthing";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          PUID = 1000;
          PGID = 1000;
        };
        volumes = [ "${cfg.path}:/var/syncthing" ];
        ports =
          (
            if (cfg.expose) then
              [
                "22000:22000/tcp" # TCP file transfers
                "22000:22000/udp" # QUIC file transfers
                "21027:21027/udp" # Receive local discovery broadcasts
              ]
            else
              [ ]
          )
          ++ (
            if (cfg.internal) then
              [
                "${config.server.tailscale-ip}:22000:22000/tcp"
                "${config.server.tailscale-ip}:22000:22000/udp"
                "${config.server.tailscale-ip}:21027:21027/udp"
              ]
            else
              [ ]
          );
        labels =
          config.lib.server.mkTraefikLabels {
            name = "syncthing";
            port = "8384";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };
    };
  };
}
