{ config, modulesPath, secrets, lib, ... }:

let flake = "kronos";
in {
  imports = [ ./secrets ];

  networking = { hostName = "${flake}"; };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ae496939-fea4-4d31-a15e-08ca064478aa";
    fsType = "btrfs";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/4a6b0055-10ec-45b7-b07e-3cfcb2a57915"; }];

  fileSystems."/mnt/backup" = {
    device = "100.115.213.122:/mnt/hdd/backup/kronos";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/media" = {
    device = "100.115.213.122:/mnt/hdd/media";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/unknown" = {
    device = "100.115.213.122:/mnt/hdd/unknown";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  # system
  system = { inherit flake; };
  modules = {
    ssh.enable = false;
    arion.enable = true;
    hyprland.enable = true;
    packages.full = true;
  };

  # users
  users.mutableUsers = false;
  users.users."${flake}" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
