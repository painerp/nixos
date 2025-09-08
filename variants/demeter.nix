{
  config,
  secrets,
  lib,
  ...
}:

let
  flake = "demeter";
  truenas-ip = "100.111.75.128";
in
{
  imports = [ ./secrets ];

  age.secrets.demeter-pw.file = secrets.demeter-demeter-pw;

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8DC6-573B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0ebe90ed-0ab3-498b-92b1-f60bc27fb7b6";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/36361ec2-9a77-4002-9772-947f7054dd4c"; }
  ];

  fileSystems."/mnt/backup" = {
    device = "${truenas-ip}:/mnt/hdd/backup/demeter";
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
    language = "de_DE.UTF-8";
  };
  modules = {
    auto-upgrade.enable = true;
    gnome.enable = true;
    packages = {
      desktop = true;
      office = true;
    };
    nvidia.enable = true;
  };
  cpkgs = {
    ice-connect.enable = true;
    legion-keyboard.enable = true;
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
      ];
      hashedPasswordFile = config.age.secrets.demeter-pw.path;
    };
  };

  nix.settings.trusted-users = [ "@wheel" ];
}
