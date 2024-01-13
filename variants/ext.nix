{ config, modulesPath, secrets, lib, ... }:

let
  hostname = "nixext";
  tailscale-ip = "100.86.37.30";
in
{
  imports = [ ./secrets ./secrets/ext.nix ];

  # secrets
  age.secrets.user-pw.file = secrets.ext-user-pw;
  age.secrets.root-pw.file = secrets.ext-root-pw;


  networking.hostName = "${hostname}";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ea881f84-b512-47e8-af97-4260a2fb4e51";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E900-FD3F";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/55f7d97a-a438-4ac9-8909-2e08a78e3ef5"; }
    ];

  # services
  server = {
    base-domain = "redacted";
    short-subdomain = true;
    authentik = {
      enabled = true;
      subdomain = "auth";
    };
    bachelor = {
      enabled = true;
      domain = "redacted";
      root = true;
      auth = false;
      image = "redacted";
    };
    gotify = {
      enabled = true;
      subdomain = "got";
      auth = false;
    };
    monitoring.enabled = true;
    nuxt-pages = {
      enabled = true;
      app = {
        root = true;
        auth = false;
        image = "redacted";
      };
      g2g = {
        auth = false;
        image = "redacted";
      };
    };
    pihole.enabled = true;
    protonbridge.enabled = true;
    teamspeak.enabled = true;
    traefik = {
      enabled = true;
      subdomain = "t";
      nextcloud-talk-proxy = true;
    };
    uptime-kuma = {
      enabled = true;
      subdomain = "st";
    };
    watchtower.enabled = true;
  };

  # users
  users = {
    mutableUsers = false;
    users.user = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-pw.path;
      extraGroups = [ "wheel" ];
    };
    users.root = {
      hashedPasswordFile = config.age.secrets.root-pw.path;
    };
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # docker
  virtualisation.arion.projects = {
    pihole.settings.services.pihole.service.ports = [ "${tailscale-ip}:53:53/tcp" "${tailscale-ip}:53:53/udp" ];
    protonbridge.settings.services.protonbridge.service.ports = [ "${tailscale-ip}:25:25/tcp" ];
    monitoring.settings.services.node-exporter.service.ports = [ "${tailscale-ip}:20000:9100/tcp" ];
    monitoring.settings.services.cadvisor.service.ports = [ "${tailscale-ip}:20001:8080/tcp" ];
    traefik.settings.services.traefik.service.ports = [ "3478:3478/tcp" "3478:3478/udp" ];
    bachelor.settings.services.postgres.service.ports = [ "${tailscale-ip}:5432:5432/tcp" ];
  };
}