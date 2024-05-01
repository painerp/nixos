{ config, modulesPath, secrets, lib, ... }:

let
  flake = "arr";
  tailscale-ip = "100.95.215.11";
  motion = "/mnt/motion";
  unprocessed = "${motion}/temp/unprocessed";
  processed = "${motion}/temp/processed";
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
    [{ device = "/dev/disk/by-uuid/b11cb3df-2e66-466c-9910-ef30b104612f"; }];

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
    pledo = {
      enable = true;
      volumes =
        [ "${unprocessed}/movies:/movies" "${unprocessed}/shows:/tvshows" ];
    };
    prdl = {
      enable = true;
      auth = false;
      image = "redacted";
      env-file = secrets.arr-prdl-env;
      volumes =
        [ "${unprocessed}/movies:/movies" "${unprocessed}/shows:/tvshows" ];
    };
    radarr = {
      enable = true;
      volumes = [ "${processed}/movies:/processed" "${motion}/movies:/movies" ];
    };
    sonarr.enable = true;
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
