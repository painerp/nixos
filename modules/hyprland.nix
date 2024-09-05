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
        libnotify
        wl-clipboard
        cliphist
        wlogout
        egl-wayland
        kitty
        udiskie
        rofi-wayland
        pavucontrol
        brightnessctl
        ags
        libdbusmenu-gtk3
        bun
        sass
        networkmanagerapplet
        libgtop
        glib
        swww
        matugen
        grimblast
      ];
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GI_TYPELIB_PATH =
          "${pkgs.libgtop}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0";
      };
    };

    fonts.packages = with pkgs; [ nerdfonts ];

    programs = {
      hyprland.enable = true;
      hyprlock.enable = true;
      ssh.startAgent = true;
    };

    services = {
      gvfs.enable = true;
      blueman.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      hypridle.enable = true;
      printing.enable = true;
      #      kdeconnect = {
      #        enable = true;
      #        indicator = true;
      #      };
      gnome.gnome-keyring.enable = true;
    };
    services.hypridle.enable = true;
  };
}
