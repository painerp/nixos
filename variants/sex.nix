{
  config,
  secrets,
  ...
}:

let
  flake = "sex";
  tailscale-ip = "100.82.15.66";
in
{
  imports = [
    ./secrets
    ./secrets/sex.nix
  ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/27f84bd7-9372-4254-ac51-ad7b0f2acffb";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DCCB-DD8F";
    fsType = "vfat";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/4922412f-2a31-4239-8c30-ad2b0f0c94ca"; } ];

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
  };

  # services
  server = {
    base-domain = "redacted";
    inherit tailscale-ip;
    short-subdomain = true;
    adguardhome.enable = true;
    authentik = {
      enable = true;
      subdomain = "auth";
      version = "2025.12.3";
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
    };
    minecraft-router = {
      enable = true;
      expose = true;
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
      extra-entrypoints = {
        satisfactory-tcp1.address = ":7777/tcp";
        satisfactory-udp.address = ":7777/udp";
        satisfactory-tcp2.address = ":8888/tcp";
      };
      extra-ports = [
        "7777:7777/tcp"
        "7777:7777/udp"
        "8888:8888/tcp"
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
    watchtower = {
      enable = true;
      internal-services = true;
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
