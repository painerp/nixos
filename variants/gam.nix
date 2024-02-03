{ config, modulesPath, secrets, lib, ... }:

let
  hostname = "nixgam";
  tailscale-ip = "100.77.215.64";
in {
  imports = [ ./secrets ];

  networking.hostName = "${hostname}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1ca563af-ad9e-4629-8f43-4e8436dd6c6c";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/b59d42ce-4fc3-42e6-8bfb-bf8bf789ab85"; }];

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    authentik = {
      enable = true;
      env-file = secrets.gam-palworld-env;
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
