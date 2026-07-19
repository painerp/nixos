{ lib, config, ... }:

let
  cfg = config.server.atvloadly;
in
{
  options.server.atvloadly = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "atv" else "atvloadly";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    # atvloadly discovers and pairs with Apple TVs through the host's avahi daemon
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      denyInterfaces = [ config.services.tailscale.interfaceName ];
      publish = {
        enable = true;
        addresses = true;
        userServices = true;
      };
    };

    systemd.services.arion-atvloadly = {
      wants = [
        "network-online.target"
        "avahi-daemon.service"
      ];
      after = [
        "network-online.target"
        "avahi-daemon.service"
      ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.atvloadly.settings = {
      project.name = "atvloadly";
      networks.proxy.external = true;

      services.atvloadly = {
        # arion has no typed option for security_opt
        out.service.security_opt = [ "seccomp:unconfined" ];
        service = {
          image = "bitxeno/atvloadly:latest";
          container_name = "atvloadly";
          hostname = config.networking.hostName;
          networks = [ "proxy" ];
          environment = {
            TZ = config.time.timeZone;
          };
          ports = lib.mkIf (cfg.internal) [ "${config.server.tailscale-ip}:5533:80" ];
          volumes = [
            "${config.lib.server.mkConfigDir "atvloadly"}:/data"
            "/run/dbus:/var/run/dbus"
            "/run/avahi-daemon:/var/run/avahi-daemon"
          ];
          labels = config.lib.server.mkTraefikLabels {
            name = "atvloadly";
            port = "80";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
