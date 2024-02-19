{ lib }:

{
  options.system = {
    flake = lib.mkOption {
      description = "The flake to use for system configuration";
      type = lib.types.str;
    };
  };

  imports = [
    ./arion.nix
    ./auto-update.nix
    ./firewall.nix
    ./kodi.nix
    ./micro.nix
    ./optimize.nix
    ./packages.nix
    ./shell.nix
    ./ssh-server.nix
    ./system.nix
    ./tailscale.nix
  ];
}
