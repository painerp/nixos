{ lib, config, ... }:

let
  cfg = config.server.rndlm;
  config-dir = "${config.lib.server.mkConfigDir "rndlm"}";
in
{
  options.server.rndlm = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "rd" else "rndlm";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    image = lib.mkOption { type = lib.types.str; };
    env-file = lib.mkOption { type = lib.types.path; };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.rndlm-env.file = cfg.env-file;

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "rndlm";
        port = "9612";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.rndlm.service = {
        image = "${cfg.image}";
        container_name = "rndlm";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        sysctls = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
        };
        environment = {
          RATING_THRESHOLD = 7;
          RATELIMIT = 8;
          TZ = config.time.timeZone;
        };
        env_file = [ config.age.secrets.rndlm-env.path ];
        volumes = [ "${config.lib.server.mkConfigDir "rndlm"}/data:/app/data" ] ++ cfg.volumes;
        labels = {
          "com.centurylinklabs.watchtower.enable" = "true";
        };
        restart = "unless-stopped";
      };
    };
  };
}
