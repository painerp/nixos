{ lib, ... }:
let
  floatClass = class: {
    match.class = class;
    float = true;
  };

  floatTitle = title: {
    match.title = title;
    float = true;
  };
in
{
  wayland.windowManager.hyprland.settings.window_rule = [
    (floatClass "^(file_progress)$")
    (floatClass "^(confirm)$")
    (floatClass "^(dialog)$")
    (floatClass "^(download)$")
    (floatClass "^(notification)$")
    (floatClass "^(error)$")
    (floatClass "^(splash)$")
    (floatClass "^(confirmreset)$")
    (floatClass "^(org.kde.ark)$")
    (
      floatClass "^(blueman-manager)$"
      // {
        move = [
          "100%-550"
          48
        ];
      }
    )
    (
      floatClass "^(Rofi)$"
      // {
        move = [
          10
          48
        ];
        dim_around = true;
      }
    )
    (floatClass "^(net-runelite-client-RuneLite)$")
    {
      match = {
        class = "^(Tk)$";
        title = "^(Wallpaper.*)$";
      };
      float = true;
    }
    (floatTitle "^(Open File)$")
    (floatTitle "^(branchdialog)$")
    (floatTitle "^(wlogout)$" // { fullscreen = true; })
    (floatTitle "^(Media viewer)$")
    (floatTitle "^([Pp]icture.*in.*[Pp]icture)$")
    (floatTitle "^(Save File)$")
    (floatTitle "^(KeePassXC - Browser Access Request)$")
    (
      floatTitle "^(Nextcloud)$"
      // {
        move = [
          "100%-580"
          40
        ];
      }
    )
    (floatTitle "^(File Operation Progress)$")
    (floatTitle "^(.*shufti)$")
    (floatTitle "^(APOD Wallpaper Switcher)$" // { dim_around = true; })
    (
      floatTitle "^(Volume Control)$"
      // {
        size = [
          800
          600
        ];
        move = [
          "100%-820"
          48
        ];
        dim_around = true;
      }
    )
  ];
}
