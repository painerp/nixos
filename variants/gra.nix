{ config, modulesPath, secrets, lib, ... }:

let
  flake = "gra";
  tailscale-ip = "100.118.176.61";
  media = "/mnt/media";
in {
  imports = [ ./secrets ];

  networking = {
    hostName = "nix${flake}";
    interfaces.enp6s19.ipv4.addresses = [{
      address = "10.0.10.15";
      prefixLength = 24;
    }];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ae496939-fea4-4d31-a15e-08ca064478aa";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/0c680e6b-a520-4d4a-87e7-15d21b709e5b"; }];

  fileSystems."/mnt/nextcloud" = {
    device = "10.0.10.1:/mnt/hdd/nextcloud";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/immich" = {
    device = "10.0.10.1:/mnt/hdd/immich";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."${media}" = {
    device = "10.0.10.1:/mnt/hdd/media";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  # nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  virtualisation.docker = { enableNvidia = true; };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # system
  system = { inherit flake; };
  modules = { arion.enable = true; };

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
      version = "v1.108.0";
      volumes = [
        "/mnt/immich:/usr/src/app/upload"
        "/mnt/nextcloud/data/painerp/files/Bilder:/library"
      ];
      env-file = secrets.gra-immich-env;
      redis.image =
        "registry.hub.docker.com/library/redis:6.2-alpine@sha256:84882e87b54734154586e5f8abd4dce69fe7311315e2fc6d67c29614c8de2672";
      postgres = {
        image =
          "registry.hub.docker.com/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
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
