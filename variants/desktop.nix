{
  config,
  lib,
  secrets,
  ...
}:

let
  name = config.system.username;
in
{
  age.secrets."${name}-pw".file = secrets."${name}-${name}-pw";

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  modules = {
    auto-upgrade.enable = lib.mkDefault false;
    failure-monitor.enable = false;
    nfs.mounts."/mnt/backup" = "backup/${name}";
  };

  cpkgs = {
    brightness.enable = true;
    screenshot-upload.enable = true;
    upload-file = {
      enable = true;
      key-file = secrets.pkgs-upload-file;
    };
  };

  # docker group comes from arion
  users.users.${name} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
    ];
    hashedPasswordFile = config.age.secrets."${name}-pw".path;
  };
}
