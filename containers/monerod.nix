{ lib, config, ... }:

let
  cfg = config.server.monerod;
in
{
  options.server.monerod = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.ports = lib.mkIf (cfg.internal) [
        "${config.server.tailscale-ip}:18089:18089"
      ];

      services.monerod.service = {
        image = "docker.io/sethsimmons/simple-monerod:latest";
        container_name = "monerod";
        network_mode = "service:gluetun";
        user = "1026:100";
        command = [
          "--rpc-restricted-bind-ip=0.0.0.0"
          "--rpc-restricted-bind-port=18089"
          "--no-igd"
          "--enable-dns-blocklist"
          "--prune-blockchain"
        ];
        volumes = cfg.volumes;
        restart = "unless-stopped";
      };
    };
  };
}
