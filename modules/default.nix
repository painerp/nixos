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
  };

  imports = [
    ./amd.nix
    ./arion.nix
    ./auto-upgrade.nix
    ./firewall.nix
    ./hyprland.nix
    ./kodi.nix
    ./micro.nix
    ./nvidia.nix
    ./optimize.nix
    ./packages.nix
    ./shell.nix
    ./ssh-server.nix
    ./system.nix
    ./tailscale.nix
  ];
}
