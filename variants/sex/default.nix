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

  modules = {
    arion = {
      enable = true;
      registry-login = true;
      tailscale-dependent = true;
    };
    borg.enable = true;
  };

  server = {
    short-subdomain = true;
    adguardhome = {
      enable = true;
      version = "v0.107.79";
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
      auth = false;
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
    nginx = {
      enable = true;
      rule = "Host(`jf.${config.server.domain}`) && PathPrefix(`/extras`)";
      middleware = "strip-extras-prefix";
      labels = {
        "traefik.http.middlewares.strip-extras-prefix.stripPrefix.prefixes" = "/extras";
      };
      auth = false;
    };
    uptime-kuma = {
      enable = true;
      subdomain = "st";
    };
    watchtower.enable = true;
  };
}
