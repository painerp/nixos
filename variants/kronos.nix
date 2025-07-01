{
  config,
  secrets,
  lib,
  ...
}:

let
  flake = "kronos";
  truenas-ip = "100.111.75.128";
in
{
  imports = [ ./secrets ];

  age.secrets.kronos-pw.file = secrets.kronos-kronos-pw;

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/70C9-AC4A";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ce9ee924-0948-4ac1-83d4-8b10731b21ba";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/040cc9dd-71cf-4c88-8cfa-cf52e21bc9e5"; } ];

  boot.initrd.luks.devices = {
    "luks-1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6".device =
      "/dev/disk/by-uuid/1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6";
    "luks-97fed62b-bdc0-43b3-b670-ed83775644aa".device =
      "/dev/disk/by-uuid/97fed62b-bdc0-43b3-b670-ed83775644aa";
  };

  fileSystems."/mnt/backup" = {
    device = "${truenas-ip}:/mnt/hdd/backup/kronos";
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
  };
  modules = {
    arion = {
      enable = true;
      rewrite-bip = true;
    };
    auto-upgrade.enable = false;
    hyprland = {
      enable = true;
      monitor = [
        "eDP-1,highrr,0x0,1"
        ",preferred,auto,1,mirror,eDP-1"
      ];
    };
    packages.full = true;
    nvidia = {
      enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "570.133.07";
        sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY=";
        sha256_aarch64 = "sha256-yTovUno/1TkakemRlNpNB91U+V04ACTMwPEhDok7jI0=";
        openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
        settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";
        persistencedSha256 = "sha256-G1V7JtHQbfnSRfVjz/LE2fYTlh9okpCbE4dfX9oYSg8=";
      };
    };
  };
  cpkgs = {
    ice-connect.enable = true;
    legion-keyboard.enable = true;
    toggle-refresh.enable = true;
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
      hashedPasswordFile = config.age.secrets.kronos-pw.path;
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
