{
  lib,
  config,
  secrets,
  ...
}:

{
  imports = [ ./hardware.nix ];

  age.secrets.git-pw.file = secrets.cit-git-pw;

  modules = {
    arion = {
      enable = true;
      tailscale-dependent = true;
    };
    borg.enable = true;
    nfs.mounts = {
      "/mnt/pve-backup" = "backup/pve";
      "/mnt/syncthing" = "syncthing";
    };
  };

  server = {
    subdomain = "local";
    adguardhome = {
      enable = true;
      version = "v0.107.79";
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
      version = "2026.8.5";
      env-file = secrets.cit-authentik-env;
      postgres.env-file = secrets.cit-authentik-pg-env;
    };
    peanut = {
      enable = true;
      env-file = secrets.cit-peanut-env;
    };
    paperless = {
      enable = true;
      auth = false;
      env-file = secrets.cit-paperless-env;
      postgres.env-file = secrets.cit-paperless-pg-env;
    };
    proxmox-backup = {
      enable = true;
      internal = true;
      volumes = [ "/mnt/pve-backup:/backups" ];
    };
    forgejo = {
      enable = true;
      subdomain = "git";
      version = "17.0.0";
      auth = false;
    };
    home-assistant = {
      enable = true;
      auth = false;
    };
    syncthing = {
      enable = true;
      subdomain = "sync";
      path = "/mnt/syncthing";
    };
    gluetun = {
      enable = true;
      env-file = secrets.cit-gluetun-env;
    };
    monitoring.alloy.enable = true;
    traefik = {
      enable = true;
      subdomain = "t-cit";
      restrict-servers = true;
      dynamic = lib.mkMerge [
        (config.lib.server.mkTraefikRoute {
          name = "proxmox";
          url = "https://192.168.178.100:8006";
          transport = "skip-verify";
        })
        (config.lib.server.mkTraefikRoute {
          name = "truenas";
          url = "https://10.0.10.1";
          transport = "skip-verify";
        })
      ];
    };
    watchtower.enable = true;
  };

  users.users.git = {
    isNormalUser = true;
    home = "/home/git";
    uid = 1050;
    hashedPasswordFile = config.age.secrets.git-pw.path;
    extraGroups = [ "docker" ];
  };
}
