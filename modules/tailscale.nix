{ lib, pkgs, config, secrets, ... }:

{
  config = {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
