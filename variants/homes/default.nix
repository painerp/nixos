{
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  theme = {
    name = "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };
  cursor-theme = {
    name = "phinger-cursors-dark";
    size = 24;
    package = pkgs.phinger-cursors;
  };
  icon-theme = {
    name = "Papirus";
    package = pkgs.papirus-icon-theme;
  };
  pkg-config = osConfig.modules.packages;
in
{
  imports = [
    inputs.ags.homeManagerModules.default
  ] ++ (if (osConfig.modules.hyprland.enable) then [ ./hyprland ] else [ ]);

  programs = {
    ags = lib.mkIf (osConfig.modules.hyprland.enable) {
      enable = true;
      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
      ];
    };
    git = lib.mkIf (pkg-config.dev) {
      enable = true;
      userName = "painerp";
      userEmail = "8081128+painerp@users.noreply.github.com";
    };
    vscode = lib.mkIf (pkg-config.dev) {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [ ms-python.python ];
    };
    fzf.enable = true;
    zoxide.enable = true;
  };

  services.kdeconnect = lib.mkIf (pkg-config.desktop) {
    enable = true;
    indicator = true;
  };

  gtk = {
    inherit cursor-theme icon-theme;
    theme.name = theme.name;
    enable = true;
  };

  home = {
    packages = with pkgs; [
      cantarell-fonts
      font-awesome
      theme.package
      cursor-theme.package
      icon-theme.package
    ];
    pointerCursor = cursor-theme // {
      gtk.enable = true;
    };
    stateVersion = "24.05";
  };
}
