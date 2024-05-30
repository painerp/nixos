{ config, modulesPath, secrets, lib, ... }:

let
  flake = "arr";
  tailscale-ip = "100.95.215.11";
  motion = "/mnt/motion";
  unprocessed = "${motion}/temp/unprocessed";
  temp = "/tmp/unprocessed";
in {
  imports = [ ./secrets ./secrets/arr.nix ];

  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [{
      address = "10.0.10.80";
      prefixLength = 24;
    }];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5f9a25d7-4fd8-48ab-a510-3c00bdfd3edf";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/449b2af4-f258-4eb8-9c39-5a35c91fe9f3"; }];

  fileSystems."/tmp/unprocessed" = {
    device = "/dev/disk/by-uuid/e98ab9e9-6add-4298-a78b-6bdb55cde4d5";
    fsType = "ext4";
  };

  fileSystems."${motion}" = {
    device = "10.0.10.1:/mnt/main/motion";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
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
      env-file = secrets.arr-authentik-proxy-env;
    };
    gluetun = {
      enable = true;
      env-file = secrets.arr-gluetun-env;
    };
    bazarr = {
      enable = true;
      volumes = [ "${motion}/movies:/movies" "${motion}/shows:/tv" ];
    };
    prdl = {
      enable = true;
      auth = false;
      image = "redacted";
      env-file = secrets.arr-prdl-env;
      volumes = [
        "${unprocessed}/movies:/movies"
        "${unprocessed}/shows:/shows"
        "${motion}/movies:/processed/movies"
        "${motion}/shows:/processed/shows"
      ];
    };
    prowlarr.enable = true;
    radarr = {
      enable = true;
      volumes = [ "${temp}/movies:/temp/movies" "${motion}/movies:/movies" ];
    };
    sabnzbd = {
      enable = true;
      volumes = [ "${unprocessed}/downloads:/downloads" "${temp}:/temp" ];
    };
    sonarr = {
      enable = true;
      volumes = [ "${temp}/shows:/temp/shows" "${motion}/shows:/tv" ];
    };
    lidarr = {
      enable = true;
      volumes = [ "${temp}/music:/temp/music" "${motion}/music:/music" ];
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-arr";
    };
    watchtower = {
      enable = true;
      internal-services = true;
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
