{ config, modulesPath, secrets, lib, ... }:

let
  hostname = "nixgam";
  tailscale-ip = "100.114.234.126";
in {
  imports = [ ./secrets ];

  networking.hostName = "${hostname}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51277ab7-6113-497f-b1c2-a4cc6ea5a663";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/c0811b51-5a31-42cd-a982-c7bc5fbb2b7e"; }];

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    palworld = {
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
