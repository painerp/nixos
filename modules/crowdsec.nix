{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.crowdsec;
  traefik = config.modules.arion.enable && config.server.traefik.enable;
in
{
  options.modules.crowdsec = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      hub = {
        collections = [
          "crowdsecurity/linux"
          "crowdsecurity/traefik"
        ];
        parsers = [
          "crowdsecurity/nextcloud-whitelist"
          "crowdsecurity/jellyfin-whitelist"
        ];
      };
      localConfig = {
        acquisitions = [
          {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
        ]
        ++ lib.optional traefik {
          filenames = [ "/var/log/traefik/access.log" ];
          labels.type = "traefik";
        };
        parsers.s02Enrich = [
          {
            name = "local/private-whitelist";
            description = "Whitelist private and tailnet ranges";
            whitelist = {
              reason = "private or tailnet range";
              ip = [ "::1" ];
              cidr = [
                "127.0.0.0/8"
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
                "100.64.0.0/10"
                "fd7a:115c:a1e0::/48"
              ];
            };
          }
        ];
      };
      settings = {
        general.api.server = {
          enable = true;
          disable_usage_metrics_export = true;
        };
        lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
        simulation.simulation = true;
      };
    };

    # cscli defaults to this path, nixpkgs only passes it to its own units via -c
    environment.etc."crowdsec/config.yaml".source =
      (pkgs.formats.yaml { }).generate "crowdsec.yaml"
        config.services.crowdsec.settings.general;

    systemd.services.crowdsec = {
      # nixpkgs clears the unit path, the journalctl datasource needs journalctl
      path = lib.mkForce [ config.systemd.package ];
      serviceConfig.BindReadOnlyPaths = lib.mkIf traefik [
        "-${config.lib.server.mkConfigDir "traefik/logs"}:/var/log/traefik"
      ];
    };
  };
}
