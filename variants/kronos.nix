{
  pkgs,
  config,
  modulesPath,
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

  networking = {
    hostName = "${flake}";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/70C9-AC5A";
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
    "luks-1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6".device = "/dev/disk/by-uuid/1fea4deb-b91d-46cb-9fc2-abb4e15cb2c6";
    "luks-97fed62b-bdc0-43b3-b670-ed83775644aa".device = "/dev/disk/by-uuid/97fed62b-bdc0-43b3-b670-ed83775644aa";
  };

  fileSystems."/mnt/backup-arch" = {
    device = "${truenas-ip}:/mnt/hdd/backup/archtop";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
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
    home-manager = true;
  };
  modules = {
    arion.enable = true;
    hyprland.enable = true;
    packages.full = true;
    nvidia = {
      enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "550.107.02";
        sha256_64bit = "sha256-+XwcpN8wYCjYjHrtYx+oBhtVxXxMI02FO1ddjM5sAWg=";
        sha256_aarch64 = "sha256-mVEeFWHOFyhl3TGx1xy5EhnIS/nRMooQ3+LdyGe69TQ=";
        openSha256 = "sha256-Po+pASZdBaNDeu5h8sgYgP9YyFAm9ywf/8iyyAaLm+w=";
        settingsSha256 = "sha256-WFZhQZB6zL9d5MUChl2kCKQ1q9SgD0JlP4CMXEwp2jE=";
        persistencedSha256 = "sha256-Vz33gNYapQ4++hMqH3zBB4MyjxLxwasvLzUJsCcyY4k=";
      };
    };
  };
  cpkgs = {
    ice-connect.enable = true;
    toggle-refresh.enable = true;
    brightness.enable = true;
    screenshot-upload.enable = true;
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
