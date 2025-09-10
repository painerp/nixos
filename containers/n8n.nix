{ lib, config, ... }:

let
  cfg = config.server.n8n;
  default-version = "latest";
in
{
  options.server.n8n = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = "n8n";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = default-version;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-n8n = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.n8n.settings = {
      project.name = "n8n";
      networks.proxy.external = true;

      services.n8n-server.service = {
        image = "docker.n8n.io/n8nio/n8n:${cfg.version}";
        container_name = "n8n";
        hostname = config.networking.hostName;
        networks = [
          "proxy"
        ];
        environment = {
          NODE_ENV = "production";
          TZ = config.time.timeZone;
          GENERIC_TIMEZONE = config.time.timeZone;
          N8N_HOST = "${cfg.subdomain}.${config.server.domain}";
          N8N_PROTOCOL = "https";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
          N8N_RUNNERS_ENABLED = "true";
          WEBHOOK_URL = "https://${cfg.subdomain}.${config.server.domain}";
          N8N_VERSION_NOTIFICATIONS_ENABLED = "false";
          N8N_DIAGNOSTICS_ENABLED = "false";
        };
        volumes = [
          "${config.lib.server.mkConfigDir "n8n"}:/home/node/.n8n"
        ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "n8n";
            port = "5678";
            subdomain = "${cfg.subdomain}";
          }
          // {
            "com.centurylinklabs.watchtower.enable" = lib.server.boolToStr (cfg.version == default-version);
          };
        restart = "unless-stopped";
      };
    };
  };
}
