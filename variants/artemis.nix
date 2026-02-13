{
  config,
  secrets,
  lib,
  ...
}:

let
  flake = "artemis";
  truenas-ip = "100.111.75.128";
in
{
  age.secrets.artemis-pw.file = secrets.artemis-artemis-pw;

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5070-501D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f17744c3-6eea-4e50-b1e6-3e2cea40633d";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/73350b87-60ae-4b36-aff7-898f1077bc36"; } ];

  boot.initrd.luks.devices = {
    "luks-1c8482e1-c564-4a5d-9945-b849b8ea7725".device =
      "/dev/disk/by-uuid/1c8482e1-c564-4a5d-9945-b849b8ea7725";
    "luks-d6eeba2f-1c7e-45f2-bad8-ccafdbd03559".device =
      "/dev/disk/by-uuid/d6eeba2f-1c7e-45f2-bad8-ccafdbd03559";
  };

  fileSystems."/mnt/backup" = {
    device = "${truenas-ip}:/mnt/hdd/backup/artemis";
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

  # system
  system = {
    inherit flake;
    username = flake;
    home-manager = true;
    latest-kernel = true;
  };
  modules = {
    amd.enable = true;
    arion = {
      enable = true;
      rewrite-bip = true;
    };
    auto-upgrade.enable = false;
    hyprland = {
      enable = true;
      monitor = [
        "eDP-1,highrr,0x0,1.5"
        ",preferred,auto,1,mirror,eDP-1"
      ];
    };
    packages.full = true;
  };
  cpkgs = {
    ice-connect.enable = true;
    toggle-refresh = {
      enable = true;
      scale = "1.5";
    };
    brightness.enable = true;
    screenshot-upload.enable = true;
    upload-file = {
      enable = true;
      key-file = secrets.pkgs-upload-file;
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
      hashedPasswordFile = config.age.secrets.artemis-pw.path;
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
