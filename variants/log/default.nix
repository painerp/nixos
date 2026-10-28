{
  secrets,
  ...
}:

let
  flake = "log";
  tailscale-ip = (import ./tailnet.nix).ip;
in
{
  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [
      {
        address = "10.0.10.100";
        prefixLength = 24;
      }
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/264b716c-0b9a-4e6c-b5e0-b72df598628e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/590f1702-4605-4746-b6c4-95e07d6f8748"; } ];

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/servers/nix${flake}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion = {
      enable = true;
      backend = "podman";
      tailscale-dependent = true;
    };
    borg.enable = true;
  };

  # services
  server = {
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      version = "2026.8.5";
      env-file = secrets.log-authentik-proxy-env;
    };
    monitoring = {
      grafana = {
        enable = true;
        auth = false;
        env-file = secrets.log-grafana-env;
      };
      prometheus = {
        enable = true;
        public = {
          queries = rec {
            play_time = ''jellyfin_activity_play_time_seconds{job="jellyfin"}'';
            play_time_30d = "${play_time} - min_over_time(${play_time}[30d])";
            play_time_total = "sum(${play_time})";
            play_time_30d_total = "sum(${play_time_30d})";
          };
        };
      };
      loki = {
        enable = true;
        internal = true;
      };
      pve-exporter = {
        enable = false;
        env-file = secrets.log-pve-exporter-env;
      };
      alloy = {
        enable = true;
        loki.address = tailscale-ip;
        prometheus.address = tailscale-ip;
      };
      alertmanager.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-log";
      restrict-servers = true;
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
