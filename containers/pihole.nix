{ lib, config, ... }:

let cfg = config.server.pihole;
in {
  options.server.pihole = {
    enable = lib.mkOption {
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
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.cadvisor.expose;
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (cfg.enable) {
    systemd.services.arion-pihole = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.pihole.settings = {
      project.name = "pihole";

      networks.proxy.external = true;
      networks.dnscrypt.internal = true;

      services.pihole.service = {
        image = "pihole/pihole:latest";
        container_name = "pihole";
        hostname = config.networking.hostName;
        networks = [ "proxy" "dnscrypt" ];
        volumes = [
          "${config.lib.server.mkConfigDir "pihole/data"}:/etc/pihole"
          "${config.lib.server.mkConfigDir "pihole/dnsmasq.d"}:/etc/dnsmasq.d"
        ];
        environment = {
          TZ = "Europe/Berlin";
          PIHOLE_DNS_ = "dnscrypt#5053;9.9.9.9";
          SKIPGRAVITYONBOOT = "true";
        };
        ports = (if (cfg.expose) then [ "53:53/tcp" "53:53/udp" ] else [ ])
          ++ (if (cfg.internal) then [
            "${config.server.tailscale-ip}:53:53/tcp"
            "${config.server.tailscale-ip}:53:53/udp"
          ] else
            [ ]);
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
        volumes =
          [ "${config.lib.server.mkConfigDir "pihole/dnscrypt"}:/config" ];
        restart = "unless-stopped";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.expose) [ 53 ];
  };
}
