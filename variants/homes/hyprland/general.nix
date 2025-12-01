{ osConfig, ... }:
{
  wayland.windowManager.hyprland.settings = {
    monitor = osConfig.modules.hyprland.monitor;

    input = {
      kb_layout = "de";
      follow_mouse = 1;
      sensitivity = 0;
      accel_profile = "flat";
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        tap-to-click = true;
      };
    };

    gestures = [
      "3, horizontal, workspace"
    ];

    general = {
      gaps_in = 3;
      gaps_out = 5;
      border_size = 0;
      no_border_on_floating = true;
      layout = "dwindle";
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      mouse_move_enables_dpms = true;
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
        ignore_window = true;
        offset = "2 2";
        range = 4;
        render_power = 2;
        color = "0x66000000";
      };

      blur = {
        enabled = true;
        size = 3;
        passes = 3;
      };
    };

    animations = {
      enabled = true;
      bezier = [
        "overshot, 0.05, 0.9, 0.1, 1.05"
        "smoothOut, 0.36, 0, 0.66, -0.56"
        "smoothIn, 0.25, 1, 0.5, 1"
      ];
      animation = [
        "windows, 1, 5, overshot, slide"
        "windowsOut, 1, 4, smoothOut, slide"
        "windowsMove, 1, 4, default"
        "border, 1, 10, default"
        "fade, 1, 10, smoothIn"
        "fadeDim, 1, 10, smoothIn"
        "workspaces, 1, 6, default"
      ];

    };
  };
}
