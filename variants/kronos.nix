{ config, modulesPath, secrets, lib, ... }:

let flake = "kronos";
in {
  imports = [ ./secrets ];

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C34B-E9C0";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ce9ee924-0948-4ac1-83d4-8b10731b21ba";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/040cc9dd-71cf-4c88-8cfa-cf52e21bc9e5"; }];

  boot.initrd.luks.devices = {
    "luks-1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6".device =
      "/dev/disk/by-uuid/1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6";
    "luks-97fed62b-bdc0-43b3-b670-ed83775644aa".device =
      "/dev/disk/by-uuid/97fed62b-bdc0-43b3-b670-ed83775644aa";
  };

  fileSystems."/mnt/backup" = {
    device = "100.85.220.82:/mnt/hdd/backup/kronos";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/media" = {
    device = "100.85.220.82:/mnt/hdd/media";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/unknown" = {
    device = "100.85.220.82:/mnt/hdd/unknown";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
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
  };

  # users
  users.mutableUsers = false;
  users.users."${flake}" = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "input" "docker" ];
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
