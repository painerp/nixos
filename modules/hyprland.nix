{ lib, config, ... }:

let cfg = config.modules.hyprland;
in {
  options.modules.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment = with pkgs; {
      systemPackages = [
        udiskie
        rofi-wayland
        ags
        hyprpanel
        networkmanagerapplet
        blueman
        swww
        matugen
        grimblast
      ];
    };
    programs = {
      hyprland.enable = true;
      hyprlock.enable = true;
    };
    services.hypridle.enable = true;
  };
}
