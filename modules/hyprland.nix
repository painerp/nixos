{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.modules.hyprland;
  hm = config.system.home-manager;
in
{
  options.modules.hyprland = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    monitor = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
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
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd Hyprland";
        user = "greeter";
      };
    };

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal"; # Without this errors will spam on screen
      # Without these bootlogs will spam on screen
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
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
        GI_TYPELIB_PATH = "${libgtop}/lib/girepository-1.0:${glib}/lib/girepository-1.0";
      };
    };

    fonts.packages = with pkgs; [ nerdfonts ];

    programs = {
      hyprland.enable = true;
      hyprlock.enable = if hm then false else true;
      ssh.startAgent = true;
    };

    services = {
      gvfs.enable = true;
      blueman.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      hypridle.enable = if hm then false else true;
      printing.enable = true;
      gnome.gnome-keyring.enable = true;
    };

    security.polkit.enable = true;

    systemd.user.services.polkit-kde-authentication-agent-1 = {
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
