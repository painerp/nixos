{
  config,
  secrets,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets.deepseek-api-key = {
    file = secrets.dev-deepseek-api-key;
    owner = config.system.username;
    mode = "0400";
  };

  system = {
    latest-kernel = true;
    github-trusted = false;
  };
  modules = {
    agentmemory-client.enable = true;
    arion.enable = true;
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
      "/mnt/media" = "media";
      "/mnt/unknown" = "unknown";
    };
  };
  cpkgs.tsmusicbot-cookies.enable = true;
}
