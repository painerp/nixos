{ secrets, ... }:

let
  minecraft-path = "/root/config/minecraft";
in
{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      tailscale-dependent = true;
    };
    borg = {
      enable = true;
      exclude = [
        "config/minecraft-bluemap/web"
        "config/minecraft-backups"
        "config/satisfactory/gamefiles"
        "config/palworld/Pal/Content"
        "config/palworld/Pal/Binaries"
      ];
    };
  };

  server = {
    subdomain = "local";
    minecraft = {
      enable = true;
      version = "2026.10.0-java25";
      mc-version = "26.3";
      env-file = secrets.gam-minecraft-env;
      rcon.enable = true;
      backup.enable = true;
      extras = {
        plugins.modrinth = "axgraves,invsee-plus-plus,keepchunks:v7LjD3AV,worldedit:beta+,viaversion,datapack:kath-beacon-extended,datapack:dynamic-lights?";
        plugins.redownload = "InvSee++.jar";
        vanillatweaks = "/data/config/vt-datapacks.json,/data/config/vt-craftingtweaks.json";
      };
    };
    minecraft-bluemap = {
      enable = true;
      volumes = [ "${minecraft-path}/world:/app/world" ];
    };
    monitoring.alloy.enable = true;
    watchtower.enable = true;
  };
}
