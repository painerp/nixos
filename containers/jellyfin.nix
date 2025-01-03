{ lib, config, ... }:

let
  cfg = config.server.jellyfin;
in
{
  options.server.jellyfin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "jf" else "jellyfin";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-jellyfin = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.jellyfin.settings = {
      project.name = "jellyfin";
      networks.proxy.external = true;

      services.jellyfin = {
        out.service = {
          deploy.resources.reservations.devices = [
            {
              driver = "cdi";
              device_ids = [ "nvidia.com/gpu=all" ];
              capabilities = [ "gpu" ];
            }
          ];
        };
        service = {
          image = "lscr.io/linuxserver/jellyfin:latest";
          container_name = "jellyfin";
          hostname = config.networking.hostName;
          networks = [ "proxy" ];
          environment = {
            PUID = 1000;
            PGID = 1000;
            TZ = config.time.timeZone;
            NVIDIA_VISIBLE_DEVICES = "all";
          };
          ports = lib.mkIf (cfg.internal) [ "${config.server.tailscale-ip}:8096:8096" ];
          volumes = [ "${config.lib.server.mkConfigDir "jellyfin"}:/config" ] ++ cfg.volumes;
          labels =
            config.lib.server.mkTraefikLabels {
              name = "jellyfin";
              port = "8096";
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
  };
}
