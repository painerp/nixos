{
  config,
  secrets,
  inputs,
  ...
}:

let
  flake = "fpi";
  tailscale-ip = (import ./tailnet.nix).ip;
in
{
  age.secrets.wifi.file = secrets.fpi-wifi;

  # wlan
  networking = {
    hostName = "nix${flake}";
    wireless = {
      enable = false;
      secretsFile = config.age.secrets.wifi.path;
      networks = {
        "${inputs.nixos-private.common.wifi.ssid}".pskRaw = "ext:psk_fu";
      };
    };
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion = {
      enable = true;
      registry-login = true;
    };
    kodi.enable = false;
    tailscale.subnet-router = true;
  };

  # services
  server = {
    subdomain = "f";
    inherit tailscale-ip;
    adguardhome = {
      enable = true;
      version = "v0.107.79";
      expose = true;
    };
    atvloadly.enable = true;
    yt2atv = {
      enable = true;
      image = inputs.nixos-private.hosts."${flake}".yt2atv.image;
      env-file = secrets.fpi-yt2atv-env;
    };
    traefik = {
      enable = true;
      expose = true;
      wildcard = true;
    };
    monitoring.alloy = {
      enable = true;
      loki.address = "100.73.203.96";
      prometheus.address = "100.73.203.96";
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
