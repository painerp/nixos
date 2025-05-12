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
    systemd.services.arion-monerod = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.monerod.settings = {
      project.name = "monerod";
      networks.proxy.external = true;

      services.monerod.service = {
        image = "sethsimmons/simple-monerod:latest";
        container_name = "monerod";
        user = "1026:100";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        command = [
          "--rpc-restricted-bind-ip=0.0.0.0"
          "--rpc-restricted-bind-port=18089"
          "--no-igd"
          "--enable-dns-blocklist"
          "--prune-blockchain"
        ];
        ports = lib.mkIf (cfg.internal) [ "${config.server.tailscale-ip}:18089:18089" ];
        volumes = cfg.volumes;
        restart = "unless-stopped";
      };
    };
  };
}
