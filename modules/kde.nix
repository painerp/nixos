{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.kde;
in
{
  options.modules.kde = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      udisks2.enable = true;
      upower.enable = true;
      printing.enable = true;
      gnome.gnome-keyring.enable = true;
    };
    environment = {
      systemPackages = with pkgs; [
        # KDE
        kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
        kdePackages.kclock # Clock app
        kdePackages.kcolorchooser # A small utility to select a color
        kdePackages.kolourpaint # Easy-to-use paint program
        kdePackages.ksystemlog # KDE SystemLog Application
        kdePackages.sddm-kcm # Configuration module for SDDM
        wayland-utils # Wayland utilities
        wl-clipboard # Command-line copy/paste utilities for Wayland
      ];
      plasma6.excludePackages = with pkgs; [
        kdePackages.kdepim-runtime # Akonadi agents and resources
        kdePackages.konversation # User-friendly and fully-featured IRC client
        kdePackages.ktorrent # Powerful BitTorrent client
        mpv
      ];
    };
  };
}
