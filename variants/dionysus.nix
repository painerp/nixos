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

  age.secrets.dionysus-pw.file = secrets.dionysus-dionysus-pw;

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

  fileSystems."/media/10tb" = {
    device = "/dev/disk/by-uuid/7812afa2-3544-4b10-9e54-c06999c8110a";
    fsType = "btrfs";
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
    amd.enable = true;
    arion.enable = true;
    packages.full = true;
    logitech.enable = true;
    hyprland = {
      enable = true;
      monitor = [
        "HDMI-A-1,highrr,0x0,1"
        "DP-2,highrr,1920x0,1"
        ",preferred,auto,1,mirror,HDMI-A-1"
      ];
    };
    pipewire.audiosink = {
      enable = true;
      output = "alsa_output.pci-0000_0f_00.4.iec958-stereo";
    };
  };

  # users
  users = {
    mutableUsers = false;
    users."${flake}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "input"
        "docker"
      ];
      hashedPasswordFile = config.age.secrets.dionysus-pw.path;
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
