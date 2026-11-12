{
  lib,
  config,
  secrets,
  inputs,
  ...
}:

let
  hosts = (import ../../tailnet.nix).hosts;
  private = inputs.nixos-private.hosts.sex;
in
{
  imports = [ ./hardware.nix ];

  networking = {
    interfaces.ens3.ipv6.addresses = private.ens3.ipv6.addresses;
    # a static address makes dhcpcd ignore router advertisements on this interface
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
  };

  modules = {
    arion = {
      enable = true;
      registry-login = true;
      tailscale-dependent = true;
    };
    borg.enable = true;
    crowdsec.enable = true;
  };

  server = {
    short-subdomain = true;
    adguardhome = {
      enable = true;
      version = "v0.107.80";
    };
    authentik = {
      enable = true;
      subdomain = "auth";
      version = "2026.8.5";
      env-file = secrets.ext-authentik-env;
      postgres.env-file = secrets.ext-authentik-pg-env;
    };
    gotify = {
      enable = true;
      subdomain = "got";
    };
    monitoring.alloy.enable = true;
    nuxt-pages = {
      mysql.env-file = secrets.ext-nuxt-pages-mysql-env;
      pma = {
        enable = true;
        env-file = secrets.ext-nuxt-pages-pma-env;
      };
      app = {
        enable = true;
        root = true;
        auth = false;
        compress = true;
        image = private.nuxt-pages.app.image;
        env-file = secrets.ext-nuxt-pages-env;
        metrics = {
          enable = true;
          env-file = secrets.ext-nuxt-pages-metrics-env;
        };
      };
    };
    minecraft-router = {
      enable = true;
      expose = true;
      mapping = private.minecraft-router.mapping;
    };
    teamspeak = {
      enable = true;
      expose = true;
      env-file = secrets.ext-teamspeak-env;
    };
    tsmusicbot.enable = true;
    traefik = {
      enable = true;
      subdomain = "t";
      expose = true;
      aliases = private.traefik.aliases;
      dynamic = lib.mkMerge [
        (config.lib.server.mkTraefikRoute {
          name = "jellyfin";
          subdomain = "jf";
          url = "http://${hosts.nixgra}:8096";
        })
        (config.lib.server.mkTraefikRoute {
          name = "nextcloud";
          subdomain = "nc";
          url = "http://${hosts.nixgra}:11000";
        })
        (config.lib.server.mkTraefikRoute {
          name = "bluemap";
          subdomain = "mc";
          url = "http://${hosts.nixgam}:25569";
        })
      ];
    };
    goaccess.enable = true;
    uptime-kuma = {
      enable = true;
      subdomain = "st";
    };
    watchtower.enable = true;
  };
}
