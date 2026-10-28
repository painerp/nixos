{
  imports = [ ./hardware.nix ];

  system.github-trusted = false;
  modules = {
    agentmemory-client.enable = true;
    arion = {
      enable = true;
      rewrite-bip = true;
    };
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
      "/mnt/media" = "media";
      "/mnt/unknown" = "unknown";
    };
  };
  cpkgs = {
    ice-connect.enable = true;
    toggle-refresh.enable = true;
  };
}
