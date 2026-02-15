{ lib, config, ... }:

let
  cfg = config.server.jellyfin;
  default-version = "latest";
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
    version = lib.mkOption {
      type = lib.types.str;
      default = default-version;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    exporter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.jellyfin-exporter-env = lib.mkIf (cfg.exporter.enable) {
      file = cfg.exporter.env-file;
    };

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
          image = "lscr.io/linuxserver/jellyfin:${cfg.version}";
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
              "com.centurylinklabs.watchtower.enable" = config.lib.server.boolToStr (
                cfg.version == default-version
              );
            };
          restart = "unless-stopped";
        };
      };

      services.jellyfin-exporter.service = lib.mkIf (cfg.exporter.enable) {
        image = "docker.io/rebelcore/jellyfin-exporter:latest";
        container_name = "jellyfin-exporter";
        networks = [ "proxy" ];
        command = [
          "--jellyfin.address=http://jellyfin:8096"
          "--collector.activity"
        ];
        ports = [ "127.0.0.1:20010:9594" ];
        env_file = [ config.age.secrets.jellyfin-exporter-env.path ];
        restart = "unless-stopped";
      };
    };
  };
}
