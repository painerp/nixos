{ lib, config, ... }:

let
  cfg = config.server.gitea;
in
{
  options.server.gitea = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "gt" else "gitea";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    internal-ip = lib.mkOption {
      type = lib.types.str;
      default = "${config.server.tailscale-ip}";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-gitea = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gitea.settings = {
      project.name = "gitea";
      networks.proxy.external = true;

      services.gitea.service = {
        image = "docker.io/gitea/gitea:latest";
        container_name = "gitea";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          USER_UID = 1050;
          USER_GID = 1050;
        };
        volumes = [
          "${config.lib.server.mkConfigDir "gitea"}:/data"
          "/home/git/.ssh/:/data/git/.ssh"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "127.0.0.1:2222:22/tcp"
        ]
        ++ (if (cfg.internal) then [ "${cfg.internal-ip}:3000:3000/tcp" ] else [ ]);
        labels =
          config.lib.server.mkTraefikLabels {
            name = "gitea";
            port = "3000";
            subdomain = "${cfg.subdomain}";
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
