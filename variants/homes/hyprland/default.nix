{
  imports = [
    ./binds.nix
    ./execs.nix
    ./general.nix
    ./rules.nix
  ];

  wayland.windowManager.hyprland.enable = true;
  services.swww.enable = true;
}
