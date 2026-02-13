{ lib, config, ... }:

let
  cfg = config.server.attic;
  config-dir = "${config.lib.server.mkConfigDir "attic"}";
in
{
  options.server.attic = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "at" else "attic";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    storage-path = lib.mkOption {
      type = lib.types.str;
      default = config-dir;
      description = "Path to store binary cache data";
    };
    env-file = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.attic-env.file = cfg.env-file;

    systemd.services.arion-attic = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.attic.settings = {
      project.name = "attic";
      networks.proxy.external = true;

      services.attic.service = {
        image = "ghcr.io/zhaofengli/attic:latest";
        container_name = "attic";
        hostname = config.networking.hostName;
        command = [
          "-f"
          "/config/server.toml"
        ];
        networks = [ "proxy" ];
        env_file = [ config.age.secrets.attic-env.path ];
        volumes = [
          "${config-dir}/config:/config"
          "${config-dir}/data:/var/lib/atticd"
          "${cfg.storage-path}:/var/lib/atticd/storage"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "attic";
            port = "8080";
            subdomain = cfg.subdomain;
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
        restart = "unless-stopped";
      };
    };
  };
}
