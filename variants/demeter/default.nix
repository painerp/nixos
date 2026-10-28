{
  config,
  secrets,
  lib,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets.demeter-pw.file = secrets.demeter-demeter-pw;

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  system = {
    home-manager = true;
    language = "de_DE.UTF-8";
  };
  modules = {
    auto-upgrade.enable = true;
    failure-monitor.enable = false;
    gnome.enable = true;
    packages = {
      desktop = true;
      office = true;
    };
    nfs.mounts."/mnt/backup" = "backup/demeter";
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

  users.users.demeter = {
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
}
