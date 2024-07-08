{ config, modulesPath, secrets, lib, ... }:

let
  flake = "ext";
  tailscale-ip = "100.86.37.30";
in {
  imports = [ ./secrets ./secrets/ext.nix ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ea881f84-b512-47e8-af97-4260a2fb4e51";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E900-FD3F";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/55f7d97a-a438-4ac9-8909-2e08a78e3ef5"; }];

  # system
  system = { inherit flake; };
  modules = { arion.enable = true; };

  # services
  server = {
    base-domain = "redacted";
    inherit tailscale-ip;
    short-subdomain = true;
    authentik = {
      enable = true;
      subdomain = "auth";
      env-file = secrets.ext-authentik-env;
      postgres.env-file = secrets.ext-authentik-pg-env;
    };
    gotify = {
      enable = true;
      subdomain = "got";
      auth = false;
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
      promtail = {
        enable = true;
        loki.address = "100.73.203.96";
      };
    };
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
        image = "redacted";
        env-file = secrets.ext-nuxt-pages-env;
      };
      g2g = {
        enable = true;
        auth = false;
        image = "redacted";
        env-file = secrets.ext-nuxt-pages-g2g-env;
      };
    };
    open-webui = {
      enable = true;
      subdomain = "chat";
      auth = false;
      env-file = secrets.ext-open-webui-env;
    };
    pihole.enable = true;
    teamspeak = {
      enable = true;
      expose = true;
      env-file = secrets.ext-teamspeak-env;
    };
    traefik = {
      enable = true;
      subdomain = "t";
      expose = true;
      extra-entrypoints = {
        talk-tcp.address = ":3478";
        talk-udp.address = ":3478/udp";
        # palworld-udp.address = ":8211/udp";
      };
      extra-ports = [
        "3478:3478/tcp"
        "3478:3478/udp"
        # "8211:8211/udp"
      ];
    };
    uptime-kuma = {
      enable = true;
      subdomain = "st";
    };
    watchtower = {
      enable = true;
      internal-services = true;
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
