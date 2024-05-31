{ lib, config, ... }:

let cfg = config.server.stash;
in {
  options.server.stash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "xx" else "stash";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-stash = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.stash.settings = {
      project.name = "stash";
      networks.proxy.external = true;

      services.stash.service = {
        image = "stashapp/stash:latest";
        container_name = "stash";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          STASH_STASH = "/data/";
          STASH_GENERATED = "/generated/";
          STASH_METADATA = "/metadata/";
          STASH_CACHE = "/cache/";
          STASH_PORT = 9999;
        };
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${config.lib.server.mkConfigDir "stash"}/config:/root/.stash"
          "${config.lib.server.mkConfigDir "stash"}/metadata:/metadata"
          "${config.lib.server.mkConfigDir "stash"}/cache:/cache"
          "${config.lib.server.mkConfigDir "stash"}/blobs:/blobs"
          "${config.lib.server.mkConfigDir "stash"}/generated:/generated"
        ] ++ cfg.volumes;
        labels = config.lib.server.mkTraefikLabels {
          name = "stash";
          port = "9999";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}
