{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.system = {
    flake = lib.mkOption {
      description = "The flake to use for system configuration";
      type = lib.types.str;
    };
    username = lib.mkOption {
      description = "The main username of the system";
      type = lib.types.str;
      default = "root";
    };
    home-manager = lib.mkOption {
      description = "Whether home-manager is enabled";
      type = lib.types.bool;
      default = false;
    };
    language = lib.mkOption {
      description = "The default language of the system";
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
    latest-kernel = lib.mkOption {
      description = "Whether the latest kernel should be used";
      type = lib.types.bool;
      default = false;
    };
  };

  imports = [
    ./amd.nix
    ./arion.nix
    ./auto-upgrade.nix
    ./borg.nix
    ./firewall.nix
    ./gnome.nix
    ./hyprland.nix
    ./kde.nix
    ./kodi.nix
    ./logitech.nix
    ./micro.nix
    ./nvidia.nix
    ./packages.nix
    ./pipewire.nix
    ./shell.nix
    ./ssh-server.nix
    ./system.nix
    ./tailscale.nix
    ./waydroid.nix
  ];

  config = {
    boot.kernelPackages = lib.mkIf (config.system.latest-kernel) (
      lib.mkDefault pkgs.linuxPackages_latest
    );
  };
}
