{ lib, config, ... }:

let
  cfg = config.server.proxmox-backup;
  config-dir = config.lib.server.mkConfigDir "proxmox-backup";
in {
  options.server.proxmox-backup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default =
        if config.server.short-subdomain then "pb" else "proxmox-backup";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-proxmox-backup = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.proxmox-backup.settings = {
      project.name = "proxmox-backup";
      networks.proxy.external = true;

      services.proxmox-backup.service = {
        image = "ayufan/proxmox-backup-server:latest";
        container_name = "proxmox-backup";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = { TZ = config.time.timeZone; };
        stop_signal = "SIGHUP";
        tmpfs = [ "/run" ];
        volumes = [
          "${config-dir}/etc:/etc/proxmox-backup"
          "${config-dir}/logs:/var/log/proxmox-backup"
          "${config-dir}/lib:/var/lib/proxmox-backup"
        ] ++ cfg.volumes;
        labels = config.lib.server.mkTraefikLabels {
          name = "proxmox-backup";
          port = "8007";
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
