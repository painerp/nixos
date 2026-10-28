{ secrets, ... }:

{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      backend = "podman";
      tailscale-dependent = true;
    };
    borg.enable = true;
  };

  server = {
    subdomain = "local";
    authentik = {
      enable = true;
      proxy = true;
      version = "2026.8.5";
      env-file = secrets.log-authentik-proxy-env;
    };
    monitoring = {
      grafana = {
        enable = true;
        auth = false;
        env-file = secrets.log-grafana-env;
      };
      prometheus = {
        enable = true;
        public = {
          queries = rec {
            play_time = ''jellyfin_activity_play_time_seconds{job="jellyfin"}'';
            play_time_30d = "${play_time} - min_over_time(${play_time}[30d])";
            play_time_total = "sum(${play_time})";
            play_time_30d_total = "sum(${play_time_30d})";
          };
        };
      };
      loki = {
        enable = true;
        internal = true;
      };
      alloy.enable = true;
      alertmanager.enable = true;
    };
    traefik = {
      enable = true;
      subdomain = "t-log";
      restrict-servers = true;
    };
    watchtower.enable = true;
  };
}
