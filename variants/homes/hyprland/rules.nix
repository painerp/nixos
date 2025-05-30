{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float, class:file_progress"
      "float, class:confirm"
      "float, class:dialog"
      "float, class:download"
      "float, class:notification"
      "float, class:error"
      "float, class:splash"
      "float, class:confirmreset"
      "float, title:Open File"
      "float, title:branchdialog"
      "float, class:Rofi"
      "move 10 48, class:Rofi"
      "dimaround, class:Rofi"
      "float, title:wlogout"
      "fullscreen, title:wlogout"
      "float, class:org.kde.ark"
      "float, class:blueman-manager"
      "move 100%-550 48, class:blueman-manager"
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
