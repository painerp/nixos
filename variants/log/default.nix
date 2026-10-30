{ secrets, ... }:

{
  imports = [ ./hardware.nix ];

  modules = {
    arion = {
      enable = true;
      backend = "podman";
      tailscale-dependent = true;
    };
    borg = {
      enable = true;
      exclude = [
        "config/prometheus/data"
        "config/loki/data"
      ];
    };
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
          queries =
            let
              play_time = ''jellyfin_activity_play_time_seconds{job="jellyfin"}'';
              play_time_30d = "${play_time} - min_over_time(${play_time}[30d])";
            in
            {
              # max_over_time, because the archive serves last_over_time as an hourly average
              play_time = "max by (username) (max_over_time(${play_time}[7d]))";
              inherit play_time_30d;
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
      s3 = {
        endpoint = "10.0.10.1:3900";
        env-file = secrets.log-s3-env;
      };
    };
    thanos = {
      version = "v0.42.5";
    };
    traefik = {
      enable = true;
      subdomain = "t-log";
      restrict-servers = true;
    };
    watchtower.enable = true;
  };
}
