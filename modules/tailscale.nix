{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    subnet-router = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

    boot.kernel.sysctl = lib.mkIf cfg.subnet-router {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
