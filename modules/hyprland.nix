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
    #    services = {
    #      displayManager.sddm = {
    #        enable = true;
    #        wayland.enable = true;
    #      };
    #      xserver.enable = true;
    #    };

    services.greetd = {
      enable = true;
      settings.default_session = {
        command =
          "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd Hyprland";
        user = "greeter";
      };
    };

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
