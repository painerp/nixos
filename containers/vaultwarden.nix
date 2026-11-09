{ lib, config, ... }:

let
  cfg = config.server.vaultwarden;
  data = config.lib.server.mkConfigDir "vaultwarden";
in
{
  options.server.vaultwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "vw" else "vaultwarden";
    };
    version = lib.mkOption { type = lib.types.str; };
    env-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.vaultwarden-env.file = cfg.env-file;

    systemd.tmpfiles.rules = [ "d ${data} 0700 1060 1060 -" ];

    systemd.services.arion-vaultwarden = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.services.vaultwarden-backup = config.lib.server.mkDbBackup {
      type = "vaultwarden";
      container = "vaultwarden";
      dir = config.lib.server.mkConfigDir "vaultwarden-backup";
    };
    # the nightly dump is the restorable copy, the live files would be torn
    modules.borg.exclude = map (p: lib.removePrefix "/root/" "${data}/${p}") [
      "db.sqlite3*"
      "icon_cache"
      "tmp"
    ];

    server.traefik.aliases = config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.vaultwarden.settings = {
      project.name = "vaultwarden";
      networks.proxy.external = true;

      services.vaultwarden = {
        service = {
          image = "docker.io/vaultwarden/server:${cfg.version}";
          container_name = "vaultwarden";
          hostname = config.networking.hostName;
          networks = [ "proxy" ];
          user = "1060:1060";
          capabilities.ALL = false;
          # sqlite spills temp files here, the root fs is read-only
          tmpfs = [ "/tmp" ];
          environment = {
            TZ = config.time.timeZone;
            DOMAIN = "https://${cfg.subdomain}.${config.server.domain}";
            SIGNUPS_ALLOWED = "false";
            INVITATIONS_ALLOWED = "false";
            ORG_CREATION_USERS = "none";
            EMERGENCY_ACCESS_ALLOWED = "false";
            PASSWORD_HINTS_ALLOWED = "false";
          };
          env_file = [ config.age.secrets.vaultwarden-env.path ];
          volumes = [ "${data}:/data" ];
          labels =
            config.lib.server.mkTraefikLabels {
              name = "vaultwarden";
              port = "80";
              subdomain = "${cfg.subdomain}";
            }
            // {
              "com.centurylinklabs.watchtower.enable" = "false";
            };
        };
        # arion has no typed options for these
        out.service = {
          security_opt = [ "no-new-privileges:true" ];
          read_only = true;
        };
      };
    };
  };
}
