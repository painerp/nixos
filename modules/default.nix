{ lib, ... }:

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
  };

  imports = [
    ./amd.nix
    ./arion.nix
    ./auto-upgrade.nix
    ./firewall.nix
    ./hyprland.nix
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
}
