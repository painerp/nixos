{ config, secrets, ... }:

let
  flake = "jpi";
  tailscale-ip = "100.81.246.82";
in {
  imports = [ ./secrets ./secrets/jpi.nix ];
  # secrets
  age.secrets.user-pw.file = secrets.jpi-user-pw;
  age.secrets.wifi.file = secrets.jpi-wifi;

  system.flake = flake;
  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  server = {
    base-domain = "redacted";
    subdomain = "ju";
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
    watchtower.settings.services.watchtower.service.environment.WATCHTOWER_SCHEDULE =
      "0 0 3 * * *";
  };

}
