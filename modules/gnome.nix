{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.gnome;
in
{
  options.modules.gnome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      udisks2.enable = true;
      upower.enable = true;
      printing.enable = true;
      gnome.gnome-keyring.enable = true;
    };
    environment = {
      systemPackages = with pkgs; [ gnomeExtensions.appindicator ];
      gnome.excludePackages = with pkgs.gnome; [
        gedit # text editor
        geary # email reader
        evince # document viewer
        totem # video player
        flameshot
      ];
    };
  };
}
