{ config, modulesPath, secrets, lib, ... }:

let
  hostname = "nixarr";
  tailscale-ip = "100.95.215.11";
in {
  imports = [ ./secrets ./secrets/arr.nix ];

  networking = {
    hostName = "${hostname}";
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

  fileSystems."/mnt/motion" = {
    device = "10.0.10.1:/mnt/main/motion";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

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
    bazarr.enable = true;
    pledo.enable = true;
    prdl = {
      enable = true;
      image = "redacted";
      env-file = secrets.arr-prdl-env;
    };
    radarr.enable = true;
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
