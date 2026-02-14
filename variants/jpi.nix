{
  config,
  secrets,
  inputs,
  ...
}:

let
  flake = "jpi";
  tailscale-ip = "100.81.246.82";
in
{
  age.secrets.wifi.file = secrets.jpi-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless = {
      enable = true;
      secretsFile = config.age.secrets.wifi.path;
      networks = {
        "${inputs.nixos-private.common.wifi.ssid}".pskRaw = "ext:psk_fu";
        "${inputs.nixos-private.hosts."${flake}".wifi.ssid}".pskRaw = "ext:psk_ju";
      };
    };
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
    kodi.enable = true;
  };

  # services
  server = {
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
    watchtower = {
      enable = true;
      schedule = "0 0 3 * * *";
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
