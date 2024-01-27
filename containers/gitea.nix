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
    env-file = lib.mkOption {
      type = lib.types.str;
    };
    internal-ip = lib.mkOption {
      type = lib.types.str;
      default = "${config.server.tailscape-ip}";
    };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.gitea-env.file = cfg.env-file;

    systemd.services.arion-gitea = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias {
      subdomain = cfg.subdomain;
    };

    virtualisation.arion.projects.gitea.settings = {
      project.name = "gitea";
      networks.proxy.external = true;

      services.gitea.service = {
        image = "gitea/gitea:latest";
        container_name = "gitea";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          USER_UID = 1050;
          USER_GID = 1050;
        };
        env-file = [ age.secrets.gitea-env.path ];
        volumes = [
          "${config.lib.server.mkConfigDir "gitea"}:/data"
          "/home/git/.ssh/:/data/git/.ssh"
          "/etc/timezone:/etc/timezone:ro"
          "/etc/localtime:/etc/localtime:ro"
        ];
        ports = [
          "127.0.0.1:2222:22/tcp"
        ] ++ lib.mkIf (cfg.internal) [
          "${cfg.internal-ip}:3000:3000/tcp"
        ];
        labels = config.lib.server.mkTraefikLabels {
          name = "gitea";
          port = "3000";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}