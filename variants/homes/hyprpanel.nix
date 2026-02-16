{
  inputs,
  osConfig,
  pkgs,
  ...
}:

{
  programs.hyprpanel = {
    enable = true;
    package = inputs.hyprpanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd.enable = true;

    settings = {
      scalingPriority = "hyprland";
      bar = {
        layouts = {
          "${osConfig.modules.hyprland.hyprpanel.main-monitor}" = {
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
            ]
            ++ (if osConfig.modules.hyprland.hyprpanel.battery then [ "battery" ] else [ ])
            ++ [
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
        launcher.icon = "󱄅";
        windowtitle = {
          class_name = false;
          custom_title = false;
          icon = false;
          truncation_size = 100;
        };
        workspaces = {
          monitorSpecific = false;
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
          format = "%H:%M %a, %d %b";
        };
        customModules = {
          hypridle = {
            label = false;
            onIcon = "";
            offIcon = "";
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
        dashboard = {
          powermenu.enabled = false;
          directories = {
            left = {
              directory1 = {
                command = "bash -c \"thunar $HOME/\"";
                label = "󱂵 Home";
              };
              directory2 = {
                command = "bash -c \"thunar $HOME/Videos/\"";
                label = "󰉏 Videos";
              };
              directory3 = {
                command = "bash -c \"thunar $HOME/Projects/\"";
                label = "󰚝 Projects";
              };
            };
            right = {
              directory1 = {
                command = "bash -c \"thunar $HOME/Documents/\"";
                label = "󱧶 Documents";
              };
              directory2 = {
                command = "bash -c \"thunar $HOME/Pictures/\"";
                label = "󰉏 Pictures";
              };
              directory3 = {
                command = "bash -c \"thunar $HOME/Downloads/\"";
                label = "󰉍 Downloads";
              };
            };
          };
        };
        power.lowBatteryNotification = true;
        volume.raiseMaximumVolume = true;
      };

      theme = {
        font.size = "1rem";
        bar = {
          floating = true;
          transparent = true;
          outer_spacing = "0em";
          margin_top = "0.2em";
          margin_sides = "0.2em";
          buttons.y_margins = "0em";

          menus = {
            popover.scaling = 80;
            menu = {
              battery.scaling = 90;
              bluetooth.scaling = 90;
              clock.scaling = 90;
              dashboard.confirmation_scaling = 90;
              dashboard.scaling = 90;
              media.scaling = 90;
              network.scaling = 90;
              notifications.scaling = 90;
              power.scaling = 90;
              volume.scaling = 90;
            };
          };
        };
        osd = {
          muted_zero = true;
          scaling = 90;
        };
        notification.scaling = 90;
        tooltip.scaling = 90;
      };
    };
  };
}
