{ config, modulesPath, secrets, lib, ... }:

let
  flake = "gam";
  tailscale-ip = "100.114.234.126";
in {
  imports = [ ./secrets ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51277ab7-6113-497f-b1c2-a4cc6ea5a663";
    fsType = "ext4";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/c0811b51-5a31-42cd-a982-c7bc5fbb2b7e"; }];

  # system
  system = { inherit flake; };
  modules = { arion.enable = true; };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    palworld = {
      enable = false;
      env-file = secrets.gam-palworld-env;
    };
    minecraft.enable = true;
    monitoring = {
      node-exporter.enable = true;
      cadvisor.enable = true;
      promtail = {
        enable = true;
        loki.address = "100.73.203.96";
      };
    };
    watchtower.enable = true;
  };

  # users
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "@wheel" ];
}
