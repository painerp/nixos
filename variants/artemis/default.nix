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
    arion = {
      enable = true;
      rewrite-bip = true;
    };
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
  };
}
