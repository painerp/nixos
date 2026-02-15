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
  networking = {
    hostName = "nix${flake}";
    interfaces.ens19.ipv4.addresses = [
      {
        address = "10.0.10.50";
        prefixLength = 24;
      }
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/51277ab7-6113-497f-b1c2-a4cc6ea5a663";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/c0811b51-5a31-42cd-a982-c7bc5fbb2b7e"; } ];

  fileSystems."/mnt/backup" = {
    device = "10.0.10.1:/mnt/hdd/backup/servers/nix${flake}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  # system
  system = {
    inherit flake;
  };
  modules = {
    arion.enable = true;
    borg.enable = true;
  };

  # services
  server = {
    subdomain = "local";
    inherit tailscale-ip;
    palworld = {
      enable = false;
      env-file = secrets.gam-palworld-env;
    };
    satisfactory.enable = true;
    minecraft = {
      enable = true;
      env-file = secrets.gam-minecraft-env;
      rcon.enable = true;
      backup.enable = true;
      extras = {
        plugins.modrinth = "axgraves,invsee++,keepchunks:v7LjD3AV,worldedit";
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
      alloy = {
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
