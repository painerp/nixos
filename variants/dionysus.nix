{
  inputs,
  pkgs,
  config,
  modulesPath,
  secrets,
  lib,
  ...
}:

let
  flake = "dionysus";
  truenas-ip = "100.111.75.128";
in
{
  imports = [ ./secrets ];

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5A27-5DD4";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b277bef3-cb17-4996-95ca-529208ad2738";
    fsType = "ext4";
  };

  boot.initrd.luks.devices = {
    "luks-c7261900-049b-433c-8c8b-d96d9a68a9d6".device = "/dev/disk/by-uuid/c7261900-049b-433c-8c8b-d96d9a68a9d6";
    "luks-8089a368-5043-4915-a251-08688916a613".device = "/dev/disk/by-uuid/8089a368-5043-4915-a251-08688916a613";
  };

  fileSystems."/mnt/backup-arch" = {
    device = "${truenas-ip}:/mnt/hdd/backup/archlinux";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/backup" = {
    device = "${truenas-ip}:/mnt/hdd/backup/dionysus";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/media" = {
    device = "${truenas-ip}:/mnt/hdd/media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/unknown" = {
    device = "${truenas-ip}:/mnt/hdd/unknown";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/rebuild" = {
    device = "${truenas-ip}:/mnt/hdd/rebuild";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  # system
  system = {
    inherit flake;
    username = flake;
  };
  modules = {
    ssh.enable = false;
    arion.enable = true;
    hyprland.enable = true;
    packages.full = true;
    amd.enable = true;
  };

  # users
  users.mutableUsers = false;
  users.users."${flake}" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "docker"
    ];
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
