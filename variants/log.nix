{ config, modulesPath, secrets, lib, ... }:

let
  flake = "log";
  tailscale-ip = "100.73.203.96";
in {
  imports = [ ./secrets ];

  system.flake = flake;
  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/264b716c-0b9a-4e6c-b5e0-b72df598628e";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/ebf55e6d-85b4-4076-94ae-1d84feddf17d"; }];

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      env-file = secrets.log-authentik-proxy-env;
    };
    monitoring = {
      grafana = {
        enable = true;
        auth = false;
        env-file = secrets.log-grafana-env;
      };
      prometheus.enable = true;
      node-exporter = {
        enable = true;
        internal = false;
      };
      alertmanager.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-log";
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
