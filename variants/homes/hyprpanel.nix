{ inputs, ... }:

{
  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

  programs.hyprpanel = {
    enable = true;
    systemd.enable = true;
    hyprland.enable = true;
    overwrite.enable = true;

    theme = "catppuccin_mocha";

    layout = {
      "bar.layouts" = {
        "0" = {
          left = [
            "dashboard"
            "clock"
            "workspaces"
          ];
          middle = [ "windowtitle" ];
          right = [
            "systray"
            "volume"
            "bluetooth"
            "network"
            "hypridle"
            "battery"
            "notifications"
          ];
        };
        "*" = {
          left = [
            "dashboard"
            "workspaces"
          ];
          middle = [ "windowtitle" ];
          right = [
            "volume"
            "clock"
            "notifications"
          ];
        };
      };
    };

    settings = {
      bar = {
        launcher.icon = "󱄅";
        windowtitle = {
          class_name = false;
          custom_title = false;
          icon = false;
          truncation_size = 100;
        };
        workspaces = {
          numbered_active_indicator = "highlight";
          workspaces = 6;
        };
        volume = {
          input = true;
          hideMutedLabel = true;
        };
        network.label = false;
        bluetooth.label = false;
        clock = {
          showIcon = false;
          format = "%H:%M %a; %d %b";
        };
        customModules = {
          hypridle = {
            label = false;
            onIcon = "";
            offIcon = "";
            pollingInterval = 30000;
          };
          cava = {
            showIcon = false;
            showActiveOnly = true;
            noiseReduction = 0.5;
          };
        };
      };

      menus = {
        clock = {
          time.military = true;
          weather.enabled = false;
        };
        dashboard.powermenu.enabled = false;
        power.lowBatteryNotification = true;
        volume.raiseMaximumVolume = true;
      };

      theme = {
        font.size = "1rem";
        bar = {
          outer_spacing = "0.25em";
          floating = false;
          transparent = true;
        };
        buttons.modules.cava.spacing = "0em";
        osd.muted_zero = true;
      };
    };
  };
}
