{
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
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
  imports =
    [ ]
    ++ (
      if (osConfig.modules.hyprland.enable) then
        [
          ./hyprland
          ./hypridle.nix
          ./hyprlock.nix
          ./hyprpanel.nix
          ./mime.nix
          ./rofi
          ./thunar.nix
          ./wlogout
        ]
      else
        [ ]
    );

  programs = {
    git = lib.mkIf (pkg-config.dev) {
      enable = true;
      userName = "painerp";
      userEmail = "8081128+painerp@users.noreply.github.com";
    };
    vscode = lib.mkIf (pkg-config.dev) {
      enable = true;
      package = pkgs-unstable.vscodium;
      extensions = with pkgs-unstable.vscode-extensions; [
        jnoortheen.nix-ide
        ms-python.python
        github.copilot
        github.copilot-chat
        tailscale.vscode-tailscale
      ];
    };
    mangohud = lib.mkIf (pkg-config.gaming) {
      enable = true;
      settings = {
        cpu_temp = true;
        gpu_temp = true;
        vram = true;
        frame_timing = true;
      };
    };
    fzf.enable = true;
    zoxide.enable = true;
    bash.enable = true;
    fish.enable = true;
  };

  services = {
    kdeconnect = lib.mkIf (pkg-config.desktop) {
      enable = true;
      indicator = true;
    };
    nextcloud-client = lib.mkIf (pkg-config.desktop) {
      enable = true;
      startInBackground = true;
    };
    easyeffects.enable = true;
  };

  gtk = {
    enable = true;
    cursorTheme = cursor-theme;
    iconTheme = icon-theme;
    theme.name = theme.name;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  home = {
    packages = with pkgs; [
      cantarell-fonts
      font-awesome
      theme.package
      cursor-theme.package
      icon-theme.package
      papirus-folders
    ];
    pointerCursor = cursor-theme // {
      gtk.enable = true;
    };
    stateVersion = "25.05";
  };
}
