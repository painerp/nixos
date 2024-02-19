{ lib, config, ... }:

let cfg = config.server.nextcloud;
in {
  options.server.nextcloud = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "nca" else "nextcloudaio";
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
      default = "${config.lib.server.mkConfigDir "nextcloud"}";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-nextcloud = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.nextcloud.settings = {
      project.name = "nextcloud";
      networks.proxy.external = true;

      docker-compose.volumes.nextcloud_aio_mastercontainer.name =
        "nextcloud_aio_mastercontainer";

      services.nextcloud.service = {
        image = "nextcloud/all-in-one:latest";
        container_name = "nextcloud-aio-mastercontainer";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          APACHE_PORT = 11000;
          APACHE_IP_BINDING = if (cfg.expose) then
            "0.0.0.0"
          else if (cfg.internal) then
            "${config.server.tailscale-ip}"
          else
            "";
          AUTOMATIC_UPDATES = 1;
          NEXTCLOUD_DATADIR = "${cfg.path}/data";
          NEXTCLOUD_MOUNT = "${cfg.path}";
          NEXTCLOUD_ADDITIONAL_APKS =
            "imagemagick bash ffmpeg libva-utils libva-vdpau-driver libva-intel-driver intel-media-driver mesa-va-gallium";
          NEXTCLOUD_ENABLE_DRI_DEVICE = "true";
          SKIP_DOMAIN_VALIDATION = "true";
        };
        volumes = [
          "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        labels = config.lib.server.mkTraefikLabels {
          name = "nextcloudaio";
          port = "8080";
          scheme = "https";
          transport = "skip-verify@file";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}
