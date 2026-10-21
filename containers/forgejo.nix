{ lib, config, ... }:

let
  cfg = config.server.forgejo;
  host = "${cfg.subdomain}.${config.server.domain}";
in
{
  options.server.forgejo = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "fj" else "forgejo";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    version = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-forgejo = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.forgejo.settings = {
      project.name = "forgejo";
      networks.proxy.external = true;

      services.forgejo.service = {
        image = "codeberg.org/forgejo/forgejo:${cfg.version}";
        container_name = "forgejo";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          USER_UID = 1050;
          USER_GID = 1050;
          FORGEJO__server__DOMAIN = host;
          FORGEJO__server__SSH_DOMAIN = host;
          FORGEJO__server__ROOT_URL = "https://${host}/";
          FORGEJO__actions__DEFAULT_ACTIONS_URL = "https://github.com";
        };
        volumes = [
          "${config.lib.server.mkConfigDir "forgejo"}:/data"
          "/home/git/.ssh/:/data/git/.ssh"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [ "127.0.0.1:2222:22/tcp" ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "forgejo";
            port = "3000";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "false";
          };
        restart = "unless-stopped";
      };
    };
  };
}
