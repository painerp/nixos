{ config, modulesPath, secrets, lib, ... }:

let
  hostname = "nixrun";
  tailscale-ip = "100.85.82.52";
in
{
  imports = [ ./secrets ];

  networking.hostName = "${hostname}";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9232ef87-cb22-4b0c-a54b-cfff0767ff64";
      fsType = "ext4";
    };

  swapDevices = [];

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    act-runner = {
      enable = true;
      env-file = secrets.act-runner-env;
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