{ config, inputs, pkgs, ... }:

let
  theme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
  cursorTheme = {
    name = "phinger-cursors-dark";
    size = 24;
    package = pkgs.phinger-cursors;
  };
  iconTheme = {
    name = "Papirus";
    package = pkgs.papirus-icon-theme;
  };
in {
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    extraPackages = with pkgs; [ gtksourceview webkitgtk ];
  };

  programs.zoxide.enable = true;

  programs.git = {
    enable = true;
    userName = "painerp";
    userEmail = "8081128+painerp@users.noreply.github.com";
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [ ms-python.python ];
  };

  home.packages = with pkgs; [
    cantarell-fonts
    font-awesome
    theme.package
    cursorTheme.package
    iconTheme.package
  ];

  home.pointerCursor = cursorTheme // { gtk.enable = true; };

  gtk = {
    inherit cursorTheme iconTheme;
    theme.name = theme.name;
    enable = true;
  };

  home.stateVersion = "24.05";
}
