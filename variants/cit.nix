{ config, secrets, ... }:

let
  flake = "cit";
  tailscale-ip = "100.77.215.64";
in
{
  age.secrets.git-pw.file = secrets.cit-git-pw;

  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [
      {
        address = "10.0.10.10";
        prefixLength = 24;
      }
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ca563af-ad9e-4629-8f43-4e8436dd6c6c";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/ab983818-1f80-49a0-9beb-0e5329843b83"; } ];

  fileSystems."/mnt/attic" = {
    device = "/dev/disk/by-uuid/ce10438b-ca74-46b3-8c88-2f20199eb3f0";
    fsType = "ext4";
    options = [
      "defaults"
      "noatime"
    ];

  };

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/servers/nix${flake}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/pve-backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/pve";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/syncthing" = {
    device = "10.0.10.1:/mnt/hdd/syncthing";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  fileSystems."/mnt/monero" = {
    device = "10.0.10.1:/mnt/hdd/monero";
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
    arion = {
      enable = true;
      tailscale-dependent = true;
    };
    borg.enable = true;
  };

  # services
  server = {
    subdomain = "local";
    inherit tailscale-ip;
    adguardhome = {
      enable = true;
      traefik-network-ip = "172.19.0.0";
    };
    adguardhome-sync = {
      enable = true;
      env-file = secrets.cit-adguardhome-sync-env;
    };
    attic = {
      enable = true;
      auth = false;
      storage-path = "/mnt/attic";
      env-file = secrets.cit-attic-env;
    };
    authentik = {
      enable = true;
      subdomain = "auth";
      version = "2026.2.0";
      env-file = secrets.cit-authentik-env;
      postgres.env-file = secrets.cit-authentik-pg-env;
    };
    proxmox-backup = {
      enable = true;
      internal = true;
      volumes = [ "/mnt/pve-backup:/backups" ];
    };
    gitea = {
      enable = true;
      subdomain = "git";
      auth = false;
      internal = false;
    };
    home-assistant.enable = true;
    syncthing = {
      enable = true;
      subdomain = "sync";
      path = "/mnt/syncthing";
    };
    gluetun = {
      enable = true;
      env-file = secrets.cit-gluetun-env;
    };
    monerod = {
      enable = true;
      volumes = [ "/mnt/monero:/home/monero/.bitmonero" ];
    };
    monitoring.alloy = {
      enable = true;
      loki.address = "100.73.203.96";
      prometheus.address = "100.73.203.96";
    };
    traefik = {
      enable = true;
      subdomain = "t-cit";
    };
    watchtower.enable = true;
  };

  # users
  users = {
    mutableUsers = false;
    users.git = {
      isNormalUser = true;
      home = "/home/git";
      uid = 1050;
      hashedPasswordFile = config.age.secrets.git-pw.path;
      extraGroups = [ "docker" ];
    };
  };
  nix.settings.trusted-users = [ "@wheel" ];
}
