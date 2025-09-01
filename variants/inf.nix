{
  secrets,
  ...
}:

let
  flake = "inf";
  tailscale-ip = "100.115.5.117";
in
{
  imports = [
    ./secrets
    ./secrets/inf.nix
  ];

  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [
      {
        address = "10.0.10.20";
        prefixLength = 24;
      }
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/84ccc144-81ac-471e-82e3-ca4ce6a5100e";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/2c3aafdb-cb5a-41bc-a2e6-99059466a03b"; } ];

  fileSystems."/mnt/unknown" = {
    device = "10.0.10.1:/mnt/hdd/unknown";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

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
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      env-file = secrets.inf-authentik-proxy-env;
    };
    dashboard.enable = true;
    jellystat = {
      enable = true;
      env-file = secrets.inf-jellystat-env;
      postgres.env-file = secrets.inf-jellystat-pg-env;
    };
    unknown = {
      enable = true;
      extras-dir = "/mnt/unknown";
      env-file = secrets.inf-unknown-env;
      mysql.env-file = secrets.inf-unknown-mysql-env;
      pma = {
        enable = true;
        subdomain = "pma";
        env-file = secrets.inf-unknown-pma-env;
      };
    };
    dawarich = {
      enable = true;
      version = "0.30.12";
      env-file = secrets.inf-dawarich-env;
      postgres.env-file = secrets.inf-dawarich-pg-env;
    };
    n8n.enable = true;
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
      promtail = {
        enable = true;
        loki.address = "100.73.203.96";
      };
    };
    traefik = {
      enable = true;
      subdomain = "t-inf";
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
