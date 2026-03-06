{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(file_progress)$, float true"
      "match:class ^(confirm)$, float true"
      "match:class ^(dialog)$, float true"
      "match:class ^(download)$, float true"
      "match:class ^(notification)$, float true"
      "match:class ^(error)$, float true"
      "match:class ^(splash)$, float true"
      "match:class ^(confirmreset)$, float true"
      "match:class ^(org.kde.ark)$, float true"
      "match:class ^(blueman-manager)$, float true, move 100%-550 48"
      "match:class ^(Rofi)$, float true, move 10 48, dim_around true"
      "match:class ^(net-runelite-client-RuneLite)$, float true"
      "match:class ^(Tk)$, match:title ^(Wallpaper.*)$, float true"
      "match:title ^(Open File)$, float true"
      "match:title ^(branchdialog)$, float true"
      "match:title ^(wlogout)$, float true, fullscreen true"
      "match:title ^(Media viewer)$, float true"
      "match:title ^([Pp]icture.*in.*[Pp]icture)$, float true"
      "match:title ^(Save File)$, float true"
      "match:title ^(KeePassXC - Browser Access Request)$, float true"
      "match:title ^(Nextcloud)$, float true, move 100%-580 40"
      "match:title ^(File Operation Progress)$, float true"
      "match:title ^(.*shufti)$, float true"
      "match:title ^(APOD Wallpaper Switcher)$, float true, dim_around true"
      "match:title ^(Volume Control)$, float true, size 800 600, move 100%-820 48, dim_around true"
    ];
  };
}
