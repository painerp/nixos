{
  config,
  secrets,
  lib,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets = {
    artemis-pw.file = secrets.artemis-artemis-pw;
    deepseek-api-key = {
      file = secrets.dev-deepseek-api-key;
      owner = config.system.username;
      mode = "0400";
    };
  };

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  system = {
    home-manager = true;
    latest-kernel = true;
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
        "eDP-1,highrr,0x0,1.5"
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
      "/mnt/backup" = "backup/artemis";
      "/mnt/media" = "media";
      "/mnt/unknown" = "unknown";
    };
  };
  cpkgs = {
    tsmusicbot-cookies.enable = true;
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

  users.users.artemis = {
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
}
