{
  config,
  secrets,
  lib,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets = {
    dionysus-pw.file = secrets.dionysus-dionysus-pw;
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
    arion.enable = true;
    auto-upgrade.enable = false;
    failure-monitor.enable = false;
    packages.full = true;
    logitech.enable = true;
    waydroid.enable = true;
    hyprland = {
      enable = true;
      monitors = [
        "HDMI-A-1,1920x1080@144,0x0,1"
        "DP-2,1920x1080@120,1920x0,1"
        ",preferred,auto,1,mirror,HDMI-A-1"
      ];
      workspaces.custom = [
        "6, on-created-empty:keepassxc"
      ];
      wayle = {
        enable = true;
        main-monitor = "HDMI-A-1";
        battery = false;
      };
    };
    pipewire.audiosink = {
      enable = true;
      output = "alsa_output.pci-0000_0f_00.4.iec958-stereo";
    };
    nfs.mounts = {
      "/mnt/backup" = "backup/dionysus";
      "/mnt/media" = "media";
      "/mnt/unknown" = "unknown";
    };
  };
  cpkgs = {
    tsmusicbot-cookies.enable = true;
    brightness.enable = true;
    screenshot-upload.enable = true;
    upload-file = {
      enable = true;
      key-file = secrets.pkgs-upload-file;
    };
  };

  users.users.dionysus = {
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
}
