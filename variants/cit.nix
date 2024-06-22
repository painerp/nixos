{ config, modulesPath, secrets, lib, ... }:

let
  flake = "cit";
  tailscale-ip = "100.77.215.64";
in {
  imports = [ ./secrets ];

  # secrets
  age.secrets.git-pw.file = secrets.cit-git-pw;

  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [{
      address = "10.0.10.10";
      prefixLength = 24;
    }];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ca563af-ad9e-4629-8f43-4e8436dd6c6c";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/b59d42ce-4fc3-42e6-8bfb-bf8bf789ab85"; }];

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/pve";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  fileSystems."/mnt/syncthing" = {
    device = "10.0.10.1:/mnt/hdd/syncthing";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" ];
  };

  # system
  system = { inherit flake; };
  modules = { arion.enable = true; };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      subdomain = "auth";
      env-file = secrets.cit-authentik-env;
      postgres.env-file = secrets.cit-authentik-pg-env;
    };
    proxmox-backup = {
      enable = true;
      internal = true;
      volumes = [ "/mnt/backup:/backups" ];
    };
    gitea = {
      enable = true;
      subdomain = "git";
      auth = false;
      internal = false;
    };
    syncthing = {
      enable = true;
      subdomain = "sync";
      path = "/mnt/syncthing";
    };
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
