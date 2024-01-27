{ config, secrets, ... }:

let
  hostname = "nixbpi";
  tailscale-ip = "100.116.126.150";
in
{
  imports = [ ./secrets ./secrets/bpi.nix ];
  # secrets
  age.secrets.user-pw.file = secrets.bpi-user-pw;
  age.secrets.wifi.file = secrets.bpi-wifi;

  # wlan
  networking = {
    hostName = "${hostname}";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  server = {
    base-domain = "redacted";
    subdomain = "bi";
    inherit tailscale-ip;
    pihole = {
      enable = true;
      expose = true;
    };
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];

  # docker
  virtualisation.arion.projects = {
    watchtower.settings.services.watchtower.service.environment.WATCHTOWER_SCHEDULE = "0 0 3 * * *";
  };
}