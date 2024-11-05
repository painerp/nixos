{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float, file_progress"
      "float, confirm"
      "float, dialog"
      "float, download"
      "float, notification"
      "float, error"
      "float, splash"
      "float, confirmreset"
      "float, title:Open File"
      "float, title:branchdialog"
      "float, Rofi"
      "move 10 48, Rofi"
      "dimaround, Rofi"
      "float, title:wlogout"
      "fullscreen, title:wlogout"
      "float, org.kde.ark"
      "float, blueman-manager"
      "move 100%-550 48, blueman-manager"
      "float, title:^(Media viewer)$"
      "float, title:^(Volume Control)$"
      "float, title:^([Pp]icture.*in.*[Pp]icture)$"
      "float, title:^(Save File)$"
      "float, title:^(KeePassXC - Browser Access Request)$"
      "float, title:^(Nextcloud)$"
      "float, title:^(File Operation Progress)$"
      "float, title:^(.*shufti)$"
      "move 100%-580 40, title:^(Nextcloud)$"
      "size 800 600, title:^(Volume Control)$"
      "move 100%-820 48, title:^(Volume Control)$"
      "dimaround, title:^(Volume Control)$"
      "workspace 6 silent, title:^(.*KeePassXC)$"
    ];
    windowrulev2 = [ "float, class:^(Tk)$, title:^(Wallpaper.*)$" ];
  };
}
