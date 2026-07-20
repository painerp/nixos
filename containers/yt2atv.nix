{ lib, config, ... }:

let
  cfg = config.server.yt2atv;
in
{
  options.server.yt2atv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "yt" else "yt2atv";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    image = lib.mkOption { type = lib.types.str; };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.yt2atv-env.file = cfg.env-file;

    # yt2atv runs as uid 65534 and needs to own the bind-mounted data directory
    systemd.tmpfiles.rules = [ "d ${config.lib.server.mkConfigDir "yt2atv"} 0755 65534 65534 -" ];

    systemd.services.arion-yt2atv = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.yt2atv.settings = {
      project.name = "yt2atv";
      networks.proxy.external = true;

      services.yt2atv.service = {
        image = "${cfg.image}";
        container_name = "yt2atv";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment = {
          TZ = config.time.timeZone;
        };
        env_file = [ config.age.secrets.yt2atv-env.path ];
        ports = lib.mkIf (cfg.internal) [ "${config.server.tailscale-ip}:8080:8080" ];
        volumes = [ "${config.lib.server.mkConfigDir "yt2atv"}:/data" ];
        labels = config.lib.server.mkTraefikLabels {
          name = "yt2atv";
          port = "8080";
          subdomain = "${cfg.subdomain}";
          forwardAuth = cfg.auth;
        };
        restart = "unless-stopped";
      };
    };
  };
}
