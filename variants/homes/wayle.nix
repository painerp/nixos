{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

{
  services.wayle = lib.mkIf (osConfig.modules.hyprland.wayle.enable) {
    enable = true;
    #    package = inputs.wayle.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      bar = {
        layout = [
          {
            monitor = osConfig.modules.hyprland.wayle.main-monitor;
            show = true;
            left = [
              "dashboard"
              "clock"
              "hyprland-workspaces"
            ];
            center = [
              "window-title"
            ];
            right = [
              "systray"
              {
                name = "speakmic";
                modules = [
                  "volume"
                  "microphone"
                ];
              }
              "bluetooth"
              "network"
              "idle-inhibit"
            ]
            ++ (if osConfig.modules.hyprland.wayle.battery then [ "battery" ] else [ ])
            ++ [
              "notifications"
            ];
          }
        ]
        ++ (
          if osConfig.modules.hyprland.wayle.main-monitor != "*" then
            [
              {
                monitor = "*";
                show = true;
                left = [
                  "dashboard"
                  "hyprland-workspaces"
                ];
                center = [
                  "window-title"
                ];
                right = [
                  {
                    name = "speakmic";
                    modules = [
                      "volume"
                      "microphone"
                    ];
                  }
                  "clock"
                  "notifications"
                ];
              }
            ]
          else
            [ ]
        );
        scale = 0.85;
        inset-ends = 0.2;
        background-opacity = 0;
        dropdown-freeze-label = false;
        module-gap = 0.4;
        button-variant = "basic";
        button-icon-size = 0.9;
        button-label-padding = 1.15;
      };
      modules = {
        dashboard = {
          icon-color = "yellow";
          icon-bg-color = "bg-surface-elevated";
        };
        clock = {
          icon-show = false;
          format = "%H:%M %a, %d %b";
          dropdown-show-seconds = false;
          label-color = "accent";
        };
        hyprland-workspaces = {
          label-color = "accent";
          active-color = "accent";
          occupied-color = "accent";
        };
        window-title = {
          icon-show = false;
          label-color = "accent";
        };
        volume = {
          # hide muted label
          icon-color = "accent";
          icon-bg-color = "bg-surface-elevated";
        };
        microphone = {
          # hide muted label
          icon-color = "accent";
          icon-bg-color = "bg-surface-elevated";
        };
        network = {
          label-show = false;
          icon-color = "#cba6f7";
          icon-bg-color = "bg-surface-elevated";
        };
        bluetooth = {
          label-show = false;
          icon-color = "blue";
          icon-bg-color = "bg-surface-elevated";
        };
        notification = {
          # hide if 0
          label-show = false;
          icon-color = "accent";
          icon-bg-color = "bg-surface-elevated";
        };
        idle-inhibit = {
          label-show = false;
          startup-duration = 0;
          icon-color = "accent";
          icon-bg-color = "bg-surface-elevated";
        };
      };
      osd = {
        monitor = osConfig.modules.hyprland.hyprpanel.main-monitor;
      };
      styling = {
        scale = 0.9;
        palette = {
          bg = "#11111b";
          surface = "#181825";
          elevated = "#1e1e2e";
          fg = "#cdd6f4";
          fg-muted = "#bac2de";
          primary = "#eba0ac";
          red = "#f38ba8";
          yellow = "#f9e2af";
          green = "#a6e3a1";
          blue = "#74c7ec";
        };
      };
    };
  };
}
