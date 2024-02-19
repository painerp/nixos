{ config, modulesPath, secrets, lib, ... }:

let
  flake = "run";
  tailscale-ip = "100.113.149.64";
in {
  imports = [ ./secrets ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6b1b23b8-f684-4e29-8680-78e5214ae4b6";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/e0150fb6-eead-4bb7-a5e6-30c3ed675907"; }];

  # system
  system = { inherit flake; };
  modules = { arion.enable = true; };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    act-runner = {
      enable = true;
      env-file = secrets.run-act-runner-env;
    };
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
