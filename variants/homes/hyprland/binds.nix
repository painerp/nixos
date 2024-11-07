{
  wayland.windowManager.hyprland.settings = {
    bind =
      [
        # Programs
        "SUPER, B, exec, brave"
        "SUPER, X, exec, kitty"
        "SUPER, E, exec, thunar"
        # Rofi
        "SUPER, R, exec, killall rofi || rofi -show drun -theme ~/.config/rofi/themes/rofi.rasi"
        "SUPER, V, exec, killall rofi || cliphist list | rofi -dmenu -display-columns 2 -theme .config/rofi/themes/rofi-dmenu.rasi | cliphist decode | wl-copy"
        # Lock
        "SUPER, escape, exec, killall wlogout || wlogout --protocol layer-shell -b 5 -T 400 -B 400"
        # Screenshot
        "SUPER SHIFT, S, exec, hyprctl keyword animation \"fadeOut,0,0,default\"; grimblast --notify copysave area; hyprctl keyword animation \"fadeOut,1,4,default\""
        # Window management
        "SUPER, Q, killactive,"
        "SUPER, F, fullscreen,"
        "SUPER, P, pseudo,"
        "SUPER, S, togglesplit,"
        "SUPER, Space, togglefloating,"
        # Focus
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
        # Move
        "SUPER SHIFT, left, movewindow, l"
        "SUPER SHIFT, right, movewindow, r"
        "SUPER SHIFT, up, movewindow, u"
        "SUPER SHIFT, down, movewindow, d"
        # Groups
        "SUPER, g, togglegroup"
        "SUPER, tab, changegroupactive"
      ]
      # Workspaces
      ++ (builtins.concatLists (
        builtins.genList (
          x:
          let
            ws =
              let
                c = (x + 1) / 10;
              in
              builtins.toString (x + 1 - (c * 10));
          in
          [
            "SUPER, ${ws}, workspace, ${toString (x + 1)}"
            "SUPER SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
          ]
        ) 10
      ));
    binde = [
      # Media keys
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86MonBrightnessDown, exec, brightness 5%-"
      ", XF86MonBrightnessUp, exec, brightness 5%+"
      # Resize
      "SUPER CTRL, left, resizeactive, -20 0"
      "SUPER CTRL, right, resizeactive, 20 0"
      "SUPER CTRL, up, resizeactive, 0 -20"
      "SUPER CTRL, down, resizeactive, 0 20"
    ];
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
      "SUPER CTRL, mouse:272, resizewindow"
    ];
  };
}
