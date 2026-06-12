{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;

  startupCommands = [
    "wl-paste --watch cliphist store"
    "udiskie &"
    "vorta -d"
  ];

  startupBody = lib.concatMapStringsSep "\n" (cmd: "hl.exec_cmd([[${cmd}]])") startupCommands;
in
{
  wayland.windowManager.hyprland.settings.on = {
    _args = [
      "hyprland.start"
      (mkLuaInline ''
        function()
        ${startupBody}
        end'')
    ];
  };
}
