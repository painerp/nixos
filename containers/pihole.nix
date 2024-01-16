{ lib, config, ... }:

let
  cfg = config.server.pihole;
in
{
  options.server.pihole = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ph" else "pihole";
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enabled;
    };
  };

  config = lib.mkIf (cfg.enabled) {
    systemd.services.arion-pihole = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.pihole.settings = {
      project.name = "pihole";

      networks.proxy.external = true;
      networks.dnscrypt.internal = true;

      services.pihole.service = {
        image = "pihole/pihole:latest";
        container_name = "pihole";
        hostname = config.networking.hostName;
        networks = [ "proxy" "dnscrypt" ];
        volumes = [ "${config.lib.server.mkConfigDir "pihole/data"}:/etc/pihole" "${config.lib.server.mkConfigDir "pihole/dnsmasq.d"}:/etc/dnsmasq.d" ];
        environment = {
          TZ = "Europe/Berlin";
          PIHOLE_DNS_ = "dnscrypt#5053;9.9.9.9";
          SKIPGRAVITYONBOOT = "true";
        };
        ports = lib.mkIf (cfg.expose) [ "53:53/tcp" "53:53/udp" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "pihole";
          port = "80";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };

      services.dnscrypt.service = {
        image = "klutchell/dnscrypt-proxy:latest";
        container_name = "dnscrypt";
        networks = [ "proxy" "dnscrypt" ];
        volumes = [ "${config.lib.server.mkConfigDir "pihole/dnscrypt"}:/config" ];
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 53 ];
  };
}