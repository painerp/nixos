{
  lib,
  config,
  secrets,
  ...
}:

let
  cfg = config.server.tsmusicbot;
in
{
  options.server.tsmusicbot = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "tm" else "tsmusicbot";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-tsmusicbot = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    virtualisation.arion.projects.tsmusicbot.settings = {
      project.name = "tsmusicbot";
      networks.proxy.external = true;

      services.tsmusicbot.service = {
        image = "ghcr.io/painerp/tsmusicbot:dev";
        container_name = "tsmusicbot";
        networks = [ "proxy" ];
        hostname = config.networking.hostName;
        volumes = [ "${config.lib.server.mkConfigDir "tsmusicbot"}/config.json:/app/config.json" ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "tsmusicbot";
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
