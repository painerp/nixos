{ lib, config, secrets, ... }:

let
  flake = "jpi";
  tailscale-ip = "100.81.246.82";
in {
  imports = [ ./secrets ./secrets/jpi.nix ];
  # secrets
  age.secrets.wifi.file = secrets.jpi-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  # system
  system = { inherit flake; };
  modules = {
    arion.enable = true;
    kodi.enable = true;
  };

  # services
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
      lib.mkForce "0 0 3 * * *";
  };
}
