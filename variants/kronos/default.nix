{
  config,
  secrets,
  lib,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets.kronos-pw.file = secrets.kronos-kronos-pw;

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  system = {
    home-manager = true;
    github-trusted = false;
  };
  modules = {
    agentmemory-client.enable = true;
    arion = {
      enable = true;
      rewrite-bip = true;
    };
    auto-upgrade.enable = false;
    failure-monitor.enable = false;
    hyprland = {
      enable = true;
      monitors = [
        "eDP-1,highrr,0x0,1"
        ",preferred,auto,1,mirror,eDP-1"
      ];
      workspaces.custom = [
        "6, on-created-empty:keepassxc"
      ];
      wayle = {
        enable = true;
        main-monitor = "eDP-1";
      };
    };
    packages.full = true;
    nfs.mounts = {
      "/mnt/backup" = "backup/kronos";
      "/mnt/media" = "media";
      "/mnt/unknown" = "unknown";
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

  users.users.kronos = {
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
}
