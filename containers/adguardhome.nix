{ lib, config, ... }:

let
  cfg = config.server.adguardhome;
  config-dir = config.lib.server.mkConfigDir "adguardhome";
in
{
  options.server.adguardhome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ah" else "adguardhome";
    };
    expose = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    internal = lib.mkOption {
      type = lib.types.bool;
      default = !cfg.expose;
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    dot = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    sync = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "ahs" else "adguardhome-sync";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
  };

  config = lib.mkIf (config.modules.arion.enable && (cfg.enable || cfg.sync.enable)) {
    age.secrets = if (cfg.sync.enable) then { adguardhome-sync-env.file = cfg.sync.env-file; } else { };

    systemd.services.arion-adguardhome = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.adguardhome.settings = {
      project.name = "adguardhome";

      networks.proxy.external = true;
      networks.adguardhome.name = "adguardhome";

      services = {
        adguardhome.service = lib.mkIf (cfg.enable) {
          image = "docker.io/adguard/adguardhome:latest";
          container_name = "adguardhome";
          hostname = config.networking.hostName;
          networks = [
            "proxy"
            "adguardhome"
          ];
          volumes = [
            "${config-dir}/work:/opt/adguardhome/work"
            "${config-dir}/conf:/opt/adguardhome/conf"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          ports =
            (
              if (cfg.expose) then
                [
                  "53:53/tcp"
                  "53:53/udp"
                ]
                ++ (if (cfg.dot) then [ "853:853/tcp" ] else [ ])
              else
                [ ]
            )
            ++ (
              if (cfg.internal) then
                [
                  "${config.server.tailscale-ip}:53:53/tcp"
                  "${config.server.tailscale-ip}:53:53/udp"
                ]
                ++ (if (cfg.dot) then [ "${config.server.tailscale-ip}:853:853/tcp" ] else [ ])
              else
                [ ]
            );
          labels =
            config.lib.server.mkTraefikLabels {
              name = "adguardhome";
              port = "3000";
              subdomain = "${cfg.subdomain}";
              forwardAuth = cfg.auth;
            }
            // {
              "com.centurylinklabs.watchtower.enable" = "true";
            };
          restart = "unless-stopped";
        };

        adguardhome-sync.service = lib.mkIf (cfg.sync.enable) {
          image = "ghcr.io/bakito/adguardhome-sync:latest";
          container_name = "adguardhome-sync";
          hostname = config.networking.hostName;
          networks = [
            "proxy"
            "adguardhome"
          ];
          volumes = [
            "${config.lib.server.mkConfigDir "adguardhome-sync"}:/config"
          ];
          environment = {
            TZ = config.time.timeZone;
            CRON = "*/10 * * * *";
            RUN_ON_START = "true";
          };
          env_file = [ config.age.secrets.adguardhome-sync-env.path ];
          labels =
            config.lib.server.mkTraefikLabels {
              name = "adguardhome-sync";
              port = "8080";
              subdomain = "${cfg.sync.subdomain}";
              forwardAuth = cfg.sync.auth;
            }
            // {
              "com.centurylinklabs.watchtower.enable" = "true";
            };
          restart = "unless-stopped";
        };
      };
    };

    networking.firewall = lib.mkIf (cfg.expose) {
      allowedTCPPorts = [ 53 ] ++ (if (cfg.dot) then [ 853 ] else [ ]);
      allowedUDPPorts = [ 53 ];
    };
  };
}
