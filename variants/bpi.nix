{
  lib,
  config,
  secrets,
  ...
}:

let
  flake = "bpi";
  tailscale-ip = "100.116.126.150";
in
{
  imports = [
    ./secrets
    ./secrets/bpi.nix
  ];
  # secrets
  age.secrets.wifi.file = secrets.bpi-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless.environmentFile = config.age.secrets.wifi.path;
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
  };

  server = {
    base-domain = "redacted";
    subdomain = "bi";
    inherit tailscale-ip;
    adguardhome = {
      enable = true;
      expose = true;
    };
    protonbridge.enable = true;
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    watchtower = {
      enable = true;
      internal-services = true;
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];

  # docker
  virtualisation.arion.projects = {
    watchtower.settings.services.watchtower.service.environment.WATCHTOWER_SCHEDULE = lib.mkForce "0 0 3 * * *";
  };
}
