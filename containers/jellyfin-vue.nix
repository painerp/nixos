{ lib, config, ... }:

let cfg = config.server.jellyfin-vue;
in {
  options.server.jellyfin-vue = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "jv" else "jellyfin-vue";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    server = lib.mkOption {
      type = lib.types.str;
      description = "The default server list of jellyfin backends";
      default = "localhost";
    };
  };

  config = lib.mkIf (cfg.enable) {
    systemd.services.arion-jellyfin-vue = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.jellyfin-vue.settings = {
      project.name = "jellyfin-vue";

      networks.proxy.external = true;

      services.jellyfin-vue.service = {
        image = "ghcr.io/jellyfin/jellyfin-vue:unstable";
        container_name = "jellyfin-vue";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          HISTORY_ROUTER_MODE = 0;
          DEFAULT_SERVERS = "${cfg.server}";
        };
        labels = config.lib.server.mkTraefikLabels {
          name = "jellyfin-vue";
          port = "80";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}
