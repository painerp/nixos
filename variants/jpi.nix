{ config, secrets, ... }:

{
  imports = [ ./secrets ./secrets/jpi.nix ];
  # secrets
  age.secrets.user-pw.file = secrets.jpi-user-pw;
  age.secrets.wifi.file = secrets.jpi-wifi.age;

  # wlan
  networking = {
    hostName = "nixjpi";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  server = {
    base-domain = "redacted";
    subdomain = "ju";
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