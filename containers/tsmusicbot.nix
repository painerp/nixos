{
  lib,
  config,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.server.tsmusicbot;
  ytdlp-conf = pkgs.writeText "yt-dlp.conf" ''
    --proxy socks5h://warp:1080
    --extractor-args "youtubepot-bgutilhttp:base_url=http://bgutil:4416"
  '';
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
      networks.teamspeak.external = lib.mkIf (config.server.teamspeak.enable) true;

      services.tsmusicbot.service = {
        image = "ghcr.io/painerp/tsmusicbot:dev";
        container_name = "tsmusicbot";
        hostname = config.networking.hostName;
        networks = [
          "proxy"
          "default"
        ]
        ++ (if (config.server.teamspeak.enable) then [ "teamspeak" ] else [ ]);
        environment = {
          PRE_RESOLVE_HOST = "true";
        };
        volumes = [
          "${config.lib.server.mkConfigDir "tsmusicbot"}/config.json:/app/config.json"
          "${ytdlp-conf}:/etc/yt-dlp.conf:ro"
        ];
        depends_on = [
          "warp"
          "bgutil"
        ];
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

      services.warp = {
        out.service.device_cgroup_rules = [ "c 10:200 rwm" ];
        service = {
          image = "docker.io/caomingjun/warp:latest";
          container_name = "tsmusicbot_warp";
          capabilities.NET_ADMIN = true;
          sysctls = {
            "net.ipv6.conf.all.disable_ipv6" = 0;
            "net.ipv4.conf.all.src_valid_mark" = 1;
          };
          environment = {
            WARP_SLEEP = 2;
          };
          volumes = [ "${config.lib.server.mkConfigDir "tsmusicbot"}/warp:/var/lib/cloudflare-warp" ];
          labels = {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
          restart = "unless-stopped";
        };
      };

      services.bgutil = {
        out.service.init = true;
        service = {
          image = "docker.io/brainicism/bgutil-ytdlp-pot-provider:latest";
          container_name = "tsmusicbot_bgutil";
          labels = {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
