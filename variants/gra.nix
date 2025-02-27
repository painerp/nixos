{
  config,
  modulesPath,
  secrets,
  lib,
  ...
}:

let
  flake = "gra";
  tailscale-ip = "100.118.176.61";
  media = "/mnt/media";
in
{
  imports = [ ./secrets ];

  networking = {
    hostName = "nix${flake}";
    interfaces.enp6s19.ipv4.addresses = [
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
      volumes = [
        "${media}/shows:/shows"
        "${media}/movies:/movies"
        "${media}/music:/music"
      ];
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
    ollama = {
      enable = true;
      auth = false;
    };
    immich = {
      enable = true;
      auth = false;
      version = "v1.127.0";
      volumes = [
        "/mnt/immich:/usr/src/app/upload"
        "/mnt/nextcloud/data/painerp/files/Bilder:/library"
      ];
      env-file = secrets.gra-immich-env;
      redis.image = "docker.io/redis:6.2-alpine@sha256:2ba50e1ac3a0ea17b736ce9db2b0a9f6f8b85d4c27d5f5accc6a416d8f42c6d5";
      postgres = {
        image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
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
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
