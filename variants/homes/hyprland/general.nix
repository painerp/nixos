{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;

  # Convert "x1, y1, x2, y2" floats into the new hl.curve points table form.
  mkBezier = name: x1: y1: x2: y2: {
    _args = [
      name
      {
        type = "bezier";
        points = [
          [
            x1
            y1
          ]
          [
            x2
            y2
          ]
        ];
      }
    ];
  };
in
{
  wayland.windowManager.hyprland.settings = {
    config = {
      xwayland.force_zero_scaling = true;

      input = {
        kb_layout = "de";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap_to_click = true;
        };
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 0;
        layout = "dwindle";
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        key_press_enables_dpms = true;
        animate_manual_resizes = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };

      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        dim_inactive = false;

        shadow = {
          enabled = true;
          offset = [
            2
            2
          ];
          range = 4;
          render_power = 2;
          color = mkLuaInline "0x66000000";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 3;
        };
      };

      animations.enabled = true;
    };

    curve = [
      (mkBezier "overshot" 0.05 0.9 0.1 1.05)
      (mkBezier "smoothOut" 0.36 0 0.66 (-0.56))
      (mkBezier "smoothIn" 0.25 1 0.5 1)
    ];

    animation = [
      {
        leaf = "windows";
        enabled = true;
        speed = 5;
        bezier = "overshot";
        style = "slide";
      }
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 4;
        bezier = "smoothOut";
        style = "slide";
      }
      {
        leaf = "windowsMove";
        enabled = true;
        speed = 4;
        bezier = "default";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 10;
        bezier = "default";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 10;
        bezier = "smoothIn";
      }
      {
        leaf = "fadeDim";
        enabled = true;
        speed = 10;
        bezier = "smoothIn";
      }
      {
        leaf = "workspaces";
        enabled = true;
        speed = 6;
        bezier = "default";
      }
    ];

    gesture = [
      {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      }
    ];
  };
}
