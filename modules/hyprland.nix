{
  pkgs,
  pkgs-unstable,
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
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    workspaces = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.anything;
          options.openWhenEmpty = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Command to run whenever this workspace is created empty.";
          };
        }
      );
      default = { };
      description = ''
        Workspace rules keyed by selector, passed to hl.workspace_rule as-is.
        See https://wiki.hypr.land/configuring/core/rules/workspace-rules/
      '';
    };
    hyprpanel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      main-monitor = lib.mkOption {
        type = lib.types.str;
        default = "*";
      };
      battery = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
    wayle = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      main-monitor = lib.mkOption {
        type = lib.types.str;
        default = "*";
      };
      battery = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd start-hyprland";
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
        rofi
        pavucontrol
        brightnessctl
        networkmanagerapplet
        matugen
        pkgs-unstable.grimblast
      ];
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GI_TYPELIB_PATH = "${libgtop}/lib/girepository-1.0:${glib}/lib/girepository-1.0";
      };
    };

    fonts.packages =
      with pkgs.nerd-fonts;
      [
        hack
        ubuntu
        ubuntu-mono
        jetbrains-mono
        noto
      ]
      ++ [ pkgs.material-symbols ];

    programs = {
      hyprland = {
        enable = true;
        package = pkgs-unstable.hyprland;
        portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
      };
      hyprlock.enable = if hm then false else true;
      ssh.startAgent = true;
    };

    services = {
      gvfs.enable = true;
      blueman.enable = true;
      hypridle.enable = if hm then false else true;
      udisks2.enable = true;
      upower.enable = true;
      printing.enable = true;
      gnome.gnome-keyring.enable = true;
      gnome.gcr-ssh-agent.enable = false;
    };

    security = {
      polkit.enable = true;
      pam.services.greetd = {
        enableGnomeKeyring = true;
        kwallet = {
          enable = true;
          forceRun = true;
        };
      };
    };
  };
}
