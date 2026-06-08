{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;

  # hl.bind("<key>", <dispatcher>[, <opts>])
  mkBind =
    key: dispatcher:
    {
      _args = [
        key
        (mkLuaInline dispatcher)
      ];
    };

  mkBindOpts =
    key: dispatcher: opts:
    {
      _args = [
        key
        (mkLuaInline dispatcher)
        opts
      ];
    };

  # exec dispatcher with a shell command, wrapped in [[...]] to dodge quoting hell
  exec = cmd: ''hl.dsp.exec_cmd([[${cmd}]])'';

  workspaceBinds = builtins.concatLists (
    builtins.genList (
      x:
      let
        n = x + 1;
        key = builtins.toString (n - (n / 10) * 10);
        ws = toString n;
      in
      [
        (mkBind "SUPER + ${key}" "hl.dsp.focus({ workspace = ${ws} })")
        (mkBind "SUPER + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${ws} })")
      ]
    ) 10
  );
in
{
  wayland.windowManager.hyprland.settings.bind =
    [
      # Programs
      (mkBind "SUPER + B" (exec "brave"))
      (mkBind "SUPER + X" (exec "kitty"))
      (mkBind "SUPER + E" (exec "thunar"))
      # Rofi
      (mkBind "SUPER + R" (exec "killall rofi || rofi -show drun -theme ~/.config/rofi/themes/rofi.rasi"))
      (mkBind "SUPER + V" (exec "killall rofi || cliphist list | rofi -dmenu -display-columns 2 -theme .config/rofi/themes/rofi-dmenu.rasi | cliphist decode | wl-copy"))
      # Lock
      (mkBind "SUPER + escape" (exec "killall wlogout || wlogout --protocol layer-shell -b 5 -T 400 -B 400"))
      # Screenshot
      (mkBind "SUPER + SHIFT + S" (exec ''hyprctl keyword "animation,fadeOut,0,0,default"; grimblast --notify copysave area; hyprctl keyword "animation,fadeOut,1,4,default"''))
      # Window management
      (mkBind "SUPER + Q" "hl.dsp.window.close()")
      (mkBind "SUPER + F" "hl.dsp.window.fullscreen()")
      (mkBind "SUPER + P" "hl.dsp.window.pseudo()")
      (mkBind "SUPER + S" ''hl.dsp.layout("togglesplit")'')
      (mkBind "SUPER + Space" ''hl.dsp.window.float({ action = "toggle" })'')
      # Focus
      (mkBind "SUPER + left" ''hl.dsp.focus({ direction = "left" })'')
      (mkBind "SUPER + right" ''hl.dsp.focus({ direction = "right" })'')
      (mkBind "SUPER + up" ''hl.dsp.focus({ direction = "up" })'')
      (mkBind "SUPER + down" ''hl.dsp.focus({ direction = "down" })'')
      # Move
      (mkBind "SUPER + SHIFT + left" ''hl.dsp.window.move({ direction = "left" })'')
      (mkBind "SUPER + SHIFT + right" ''hl.dsp.window.move({ direction = "right" })'')
      (mkBind "SUPER + SHIFT + up" ''hl.dsp.window.move({ direction = "up" })'')
      (mkBind "SUPER + SHIFT + down" ''hl.dsp.window.move({ direction = "down" })'')
      # Groups
      (mkBind "SUPER + G" "hl.dsp.group.toggle()")
      (mkBind "SUPER + Tab" "hl.dsp.group.next()")
    ]
    ++ workspaceBinds
    ++ [
      # Media keys (repeating)
      (mkBindOpts "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { repeating = true; })
      (mkBindOpts "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { repeating = true; })
      (mkBindOpts "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { repeating = true; })
      (mkBindOpts "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { repeating = true; })
      (mkBindOpts "XF86MonBrightnessDown" (exec "brightness 5%-") { repeating = true; })
      (mkBindOpts "XF86MonBrightnessUp" (exec "brightness 5%+") { repeating = true; })
      # Resize (repeating)
      (mkBindOpts "SUPER + CTRL + left" "hl.dsp.window.resize({ x = -20, y = 0, relative = true })" { repeating = true; })
      (mkBindOpts "SUPER + CTRL + right" "hl.dsp.window.resize({ x = 20, y = 0, relative = true })" { repeating = true; })
      (mkBindOpts "SUPER + CTRL + up" "hl.dsp.window.resize({ x = 0, y = -20, relative = true })" { repeating = true; })
      (mkBindOpts "SUPER + CTRL + down" "hl.dsp.window.resize({ x = 0, y = 20, relative = true })" { repeating = true; })
      # Mouse drag binds
      (mkBindOpts "SUPER + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
      (mkBindOpts "SUPER + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
      (mkBindOpts "SUPER + CTRL + mouse:272" "hl.dsp.window.resize()" { mouse = true; })
    ];
}
