{ lib, config, ... }:

let
  cfg = config.server.tdarr;
  config-dir = "${config.lib.server.mkConfigDir "tdarr"}";
in {
  options.server.tdarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "td" else "tdarr";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-tdarr = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.tdarr.settings = {
      project.name = "tdarr";
      networks.proxy.external = true;

      services.tdarr = {
        out.service = {
          deploy.resources.reservations.devices = [{
            driver = "nvidia";
            count = 1;
            capabilities = [ "gpu" ];
          }];
        };
        service = {
          image = "ghcr.io/haveagitgat/tdarr:latest";
          container_name = "tdarr";
          hostname = config.networking.hostName;
          networks = [ "proxy" ];
          environment = {
            PUID = 1000;
            PGID = 1000;
            TZ = config.time.timeZone;
            internalNode = true;
            NVIDIA_DRIVER_CAPABILITIES = "all";
            NVIDIA_VISIBLE_DEVICES = "all";
          };
          volumes = [
            "${config-dir}/server:/app/server"
            "${config-dir}/configs:/app/configs"
            "${config-dir}/logs:/app/logs"
            "/mnt/motion:/media"
            "${config-dir}/temp:/temp"
          ];
          labels = config.lib.server.mkTraefikLabels {
            name = "tdarr";
            port = "8265";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
