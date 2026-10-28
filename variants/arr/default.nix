{
  secrets,
  inputs,
  ...
}:

let
  media = "/mnt/media";
  unprocessed = "${media}/temp/unprocessed";
  temp = "/tmp/unprocessed";
in
{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      registry-login = true;
      tailscale-dependent = true;
    };
    borg.enable = true;
    nfs.mounts.${media} = "media";
  };

  server = {
    subdomain = "local";
    authentik = {
      enable = true;
      proxy = true;
      version = "2026.8.5";
      extra-headers = "authorization";
      env-file = secrets.arr-authentik-proxy-env;
    };
    gluetun = {
      enable = true;
      env-file = secrets.arr-gluetun-env;
    };
    bazarr = {
      enable = true;
      volumes = [
        "${media}/movies:/movies"
        "${media}/shows:/shows"
      ];
    };
    rndlm = {
      enable = true;
      auth = false;
      image = inputs.nixos-private.hosts.arr.rndlm.image;
      env-file = secrets.arr-rndlm-env;
      volumes = [
        "${unprocessed}/movies:/movies"
        "${unprocessed}/shows:/shows"
        "${media}/movies:/processed/movies"
        "${media}/shows:/processed/shows"
      ];
    };
    prowlarr.enable = true;
    radarr = {
      enable = true;
      volumes = [
        "${temp}/movies:/temp/movies"
        "${media}/movies:/movies"
      ];
    };
    sabnzbd = {
      enable = true;
      volumes = [
        "${unprocessed}/downloads:/downloads"
        "${temp}:/temp"
      ];
    };
    sonarr = {
      enable = true;
      volumes = [
        "${temp}/shows:/temp/shows"
        "${media}/shows:/shows"
      ];
    };
    stash = {
      enable = true;
      volumes = [ "${media}/xtra:/data" ];
    };
    monitoring.alloy.enable = true;
    traefik = {
      enable = true;
      subdomain = "t-arr";
      restrict-servers = true;
    };
    watchtower.enable = true;
  };
}
