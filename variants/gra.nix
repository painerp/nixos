{
  secrets,
  ...
}:

let
  flake = "gra";
  tailscale-ip = "100.118.176.61";
  media = "/mnt/media";
in
{
  imports = [
    ./secrets
    ./secrets/gra.nix
  ];

  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [
      {
        address = "10.0.10.15";
        prefixLength = 24;
      }
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ae496939-fea4-4d31-a15e-08ca064478aa";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/0c680e6b-a520-4d4a-87e7-15d21b709e5b"; } ];

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/servers/nix${flake}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/nextcloud" = {
    device = "10.0.10.1:/mnt/hdd/nextcloud";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/immich" = {
    device = "10.0.10.1:/mnt/hdd/immich";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."${media}" = {
    device = "10.0.10.1:/mnt/hdd/media";
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
    arion.enable = true;
    borg.enable = true;
    nvidia = {
      enable = true;
      patch = true;
    };
  };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      version = "2025.10.3";
      env-file = secrets.gra-authentik-proxy-env;
    };
    nextcloud = {
      enable = true;
      path = "/mnt/nextcloud";
    };
    jellyfin = {
      enable = true;
      internal = true;
      auth = false;
      version = "10.11.5";
      volumes = [
        "${media}/shows:/shows"
        "${media}/movies:/movies"
        "${media}/music:/music"
      ];
      exporter.enable = true;
    };
    tdarr = {
      enable = true;
      internal = true;
      volumes = [
        "${media}/temp/unprocessed:/unprocessed"
        "${media}/movies:/movies"
        "${media}/shows:/shows"
        "${media}/xtra:/xtra"
      ];
    };
    immich = {
      enable = true;
      auth = false;
      version = "v2.3.1";
      volumes = [
        "/mnt/immich:/data"
        "/mnt/nextcloud/data/painerp/files/Bilder:/library"
      ];
      env-file = secrets.gra-immich-env;
      redis.image = "docker.io/valkey/valkey:8-bookworm@sha256:facc1d2c3462975c34e10fccb167bfa92b0e0dbd992fc282c29a61c3243afb11";
      postgres = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:32324a2f41df5de9efe1af166b7008c3f55646f8d0e00d9550c16c9822366b4a";
        env-file = secrets.gra-immich-pg-env;
      };
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
      promtail = {
        enable = true;
        loki.address = "100.73.203.96";
      };
    };
    traefik = {
      enable = true;
      subdomain = "t-gra";
    };
    watchtower = {
      enable = true;
      schedule = "0 0 6 * * *";
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
