{ secrets, ... }:

let
  media = "/mnt/media";
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
        "config/jellyfin/data/data/trickplay"
        "config/jellyfin/data/transcodes"
        "config/jellyfin/cache"
      ];
    };
    nfs.mounts = {
      "/mnt/nextcloud" = "nextcloud";
      "/mnt/immich" = "immich";
      ${media} = "media";
    };
  };

  server = {
    subdomain = "local";
    authentik = {
      enable = true;
      proxy = true;
      version = "2026.8.5";
      env-file = secrets.gra-authentik-proxy-env;
    };
    nextcloud = {
      enable = true;
      path = "/mnt/nextcloud";
    };
    jellyfin = {
      enable = true;
      internal = true;
      auth = false;
      version = "12.3";
      volumes = [
        "${media}/shows:/shows"
        "${media}/movies:/movies"
        "${media}/music:/music"
      ];
      exporter = {
        enable = true;
        env-file = secrets.gra-jellyfin-exporter-env;
      };
    };
    tdarr = {
      enable = true;
      internal = true;
      volumes = [
        "${media}/temp/unprocessed:/unprocessed"
        "${media}/movies:/movies"
        "${media}/shows:/shows"
        "${media}/xtra:/xtra"
      ];
    };
    immich = {
      enable = true;
      auth = false;
      version = "v3.3.5";
      volumes = [
        "/mnt/immich:/data"
        "/mnt/nextcloud/data/painerp/files/Bilder:/library"
      ];
      env-file = secrets.gra-immich-env;
      redis.image = "docker.io/valkey/valkey:9@sha256:4963247afc4cd33c7d3b2d2816b9f7f8eeebab148d29056c2ca4d7cbc966f2d9";
      postgres = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
        env-file = secrets.gra-immich-pg-env;
      };
    };
    monitoring.alloy.enable = true;
    traefik = {
      enable = true;
      subdomain = "t-gra";
      restrict-servers = true;
    };
    watchtower = {
      enable = true;
      schedule = "0 0 6 * * *";
    };
  };
}
