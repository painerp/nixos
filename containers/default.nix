{
  lib,
  config,
  arion,
  agenix,
  ...
}:

let
  cfg = config.server;
in
{
  options.server = {
    base-domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain that all services will be deployed to";
      default = "localhost";
    };

    subdomain = lib.mkOption {
      type = lib.types.str;
      description = "The subdomain that all services will be deployed to";
      default = "";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "The domain that all services will be deployed to";
      default = if cfg.subdomain == "" then cfg.base-domain else "${cfg.subdomain}.${cfg.base-domain}";
      readOnly = true;
    };

    tailscale-ip = lib.mkOption {
      type = lib.types.str;
      description = "The IP address of the Tailscale interface";
    };

    config-dir = lib.mkOption {
      type = lib.types.str;
      description = "The configuration directory";
      default = "/root/config";
    };

    short-subdomain = lib.mkOption {
      type = lib.types.bool;
      description = "Use shorter versions of subdomains for services";
      default = false;
    };
  };

  imports = [
    ./act-runner.nix
    ./adguardhome.nix
    ./authentik.nix
    ./bachelor.nix
    ./bazarr.nix
    ./dashboard.nix
    ./dawarich.nix
    ./gitea.nix
    ./gluetun.nix
    ./gotify.nix
    ./goaccess.nix
    ./home-assistant.nix
    ./immich.nix
    ./jellyfin.nix
    ./jellyfin-vue.nix
    ./jellystat.nix
    ./lidarr.nix
    ./linkwarden.nix
    ./mediathekarr.nix
    ./minecraft.nix
    ./minecraft-bluemap.nix
    ./minecraft-router.nix
    ./monerod.nix
    ./monitoring.nix
    ./n8n.nix
    ./nextcloud.nix
    ./nginx.nix
    ./nuxt-pages.nix
    ./ollama.nix
    ./open-webui.nix
    ./palworld.nix
    ./pihole.nix
    ./pledo.nix
    ./prdl.nix
    ./protonbridge.nix
    ./prowlarr.nix
    ./proxmox-backup.nix
    ./radarr.nix
    ./readarr.nix
    ./renovate.nix
    ./sabnzbd.nix
    ./sonarr.nix
    ./stash.nix
    ./syncthing.nix
    ./teamspeak.nix
    ./traefik.nix
    ./tsmusicbot.nix
    ./tdarr.nix
    ./unknown.nix
    ./uptime-kuma.nix
    ./watchtower.nix
  ];

  config = {
    lib.server.mkServiceSubdomain = subdomain: "${subdomain}.${config.server.domain}";
    lib.server.mkConfigDir = name: "${config.server.config-dir}/${name}";
    lib.server.boolToStr = b: if b then "true" else "false";
  };
}
