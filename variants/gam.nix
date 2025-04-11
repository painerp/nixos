{
  secrets,
  ...
}:

let
  flake = "gam";
  tailscale-ip = "100.114.234.126";
  minecraft-path = "/root/config/minecraft";
in
{
  imports = [ ./secrets ];

  networking.hostName = "nix${flake}";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51277ab7-6113-497f-b1c2-a4cc6ea5a663";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/c0811b51-5a31-42cd-a982-c7bc5fbb2b7e"; } ];

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
  };

  # services
  server = {
    base-domain = "redacted";
    subdomain = "local";
    inherit tailscale-ip;
    palworld = {
      enable = false;
      env-file = secrets.gam-palworld-env;
    };
    minecraft = {
      enable = true;
      env-file = secrets.gam-minecraft-env;
      rcon.enable = true;
      backup = {
        enable = true;
        interval = "2h";
      };
      extras = {
        plugins.modrinth = "axgraves,invsee++,keepchunks:v7LjD3AV,luckperms,worldedit";
        vanillatweaks = "/data/config/vt-datapacks.json,/data/config/vt-craftingtweaks.json";
      };
    };
    minecraft-bluemap = {
      enable = true;
      volumes = [
        "${minecraft-path}/world:/app/world"
        "${minecraft-path}/world_nether:/app/world_nether"
        "${minecraft-path}/world_the_end:/app/world_the_end"
      ];
    };
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
