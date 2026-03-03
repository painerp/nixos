{
  imports = [
    ./binds.nix
    ./execs.nix
    ./general.nix
    ./rules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
  };
  services.swww.enable = true;
}
