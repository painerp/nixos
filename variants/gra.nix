{ config, modulesPath, secrets, lib, ... }:

let
  flake = "gra";
  tailscale-ip = "100.118.176.61";
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
    [{ device = "/dev/disk/by-uuid/4a6b0055-10ec-45b7-b07e-3cfcb2a57915"; }];

  fileSystems."/mnt/nextcloud" = {
    device = "10.0.10.1:/mnt/main/nextcloud";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/motion" = {
    device = "10.0.10.1:/mnt/main/motion";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/main/backup/nextcloud";
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
      path = "/mnt/motion";
      auth = false;
    };
    ollama.enable = true;
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
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
