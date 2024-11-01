{ inputs, pkgs, ... }:

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
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs = {
    ags = {
      enable = true;
      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
      ];
    };
    git = {
      enable = true;
      userName = "painerp";
      userEmail = "8081128+painerp@users.noreply.github.com";
    };
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [ ms-python.python ];
    };
    zoxide.enable = true;
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
  };

  gtk = {
    inherit cursorTheme iconTheme;
    theme.name = theme.name;
    enable = true;
  };

  home = {
    packages = with pkgs; [
      cantarell-fonts
      font-awesome
      theme.package
      cursorTheme.package
      iconTheme.package
    ];
    pointerCursor = cursorTheme // {
      gtk.enable = true;
    };
    stateVersion = "24.05";
  };
}
