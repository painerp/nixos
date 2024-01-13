{ config, secrets, ... }:

{
  imports = [ ./secrets ./secrets/bpi.nix ];
  # secrets
  age.secrets.user-pw.file = secrets.bpi-user-pw;
  age.secrets.wifi.file = secrets.bpi-wifi;

  # wlan
  networking = {
    hostName = "nixbpi";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  server = {
    base-domain = "redacted";
    subdomain = "bi";
    pihole = {
      enabled = true;
      expose = true;
    };
    traefik = {
      enabled = true;
      wildcard = true;
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
  };
  nix.settings.trusted-users = [ "@wheel" ];

  # docker
  virtualisation.arion.projects = {
    watchtower.settings.services.watchtower.service.environment.WATCHTOWER_SCHEDULE = "0 0 3 * * *";
  };
}