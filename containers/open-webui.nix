{ lib, config, ... }:

let
  cfg = config.server.open-webui;
in
{
  options.server.open-webui = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ch" else "chat";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.open-webui-env.file = cfg.env-file;

    systemd.services.arion-open-webui = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.open-webui.settings = {
      project.name = "open-webui";
      networks.proxy.external = true;

      services.open-webui.service = {
        image = "ghcr.io/open-webui/open-webui:main";
        container_name = "open-webui";
        hostname = config.networking.hostName;
        networks = [ "proxy" ];
        environment =
          {
            ENABLE_SIGNUP = "false";
          }
          // lib.attrsets.optionalAttrs (cfg.auth) { WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "X-authentik-email"; };
        env_file = [ config.age.secrets.open-webui-env.path ];
        volumes = [ "${config.lib.server.mkConfigDir "open-webui"}:/app/backend/data" ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "open-webui";
            port = "8080";
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
