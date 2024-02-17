{ config, modulesPath, secrets, lib, ... }:

let
  flake = "inf";
  tailscale-ip = "100.115.5.117";
in {
  imports = [ ./secrets ./secrets/inf.nix ];

  system.flake = flake;
  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/84ccc144-81ac-471e-82e3-ca4ce6a5100e";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/bb391dc3-1cc6-40ff-8463-6b378d285f11"; }];

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      proxy = true;
      env-file = secrets.inf-authentik-proxy-env;
    };
    dashboard.enable = true;
    jellystat = {
      enable = true;
      env-file = secrets.inf-jellystat-env;
      postgres.env-file = secrets.inf-jellystat-pg-env;
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-inf";
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
