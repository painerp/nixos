{
  config,
  secrets,
  inputs,
  ...
}:

let
  flake = "bpi";
  tailscale-ip = "100.116.126.150";
in
{
  age.secrets.wifi.file = secrets.bpi-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless = {
      enable = true;
      secretsFile = config.age.secrets.wifi.path;
      networks = {
        "${inputs.nixos-private.common.wifi.ssid}".pskRaw = "ext:psk_fu";
        "${inputs.nixos-private.hosts."${flake}".wifi.ssid}".pskRaw = "ext:psk_bi";
      };
    };
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
  };

  server = {
    subdomain = "bi";
    inherit tailscale-ip;
    adguardhome = {
      enable = true;
      expose = true;
      traefik-network-ip = "172.19.0.0";
    };
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    watchtower = {
      enable = true;
      internal-services = true;
      schedule = "0 0 3 * * *";
    };
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
