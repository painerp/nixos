{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.crowdsec;
  cscli = lib.getExe' config.services.crowdsec.package "cscli";
  docker = config.virtualisation.docker.enable;
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
      autoUpdateService = true;
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

    services.crowdsec-firewall-bouncer = {
      enable = true;
      settings = {
        # docker-published ports bypass INPUT
        iptables_chains = [ "INPUT" ] ++ lib.optional docker "DOCKER-USER";
        prometheus = {
          enabled = true;
          listen_addr = "127.0.0.1";
          listen_port = "60601";
        };
      };
    };

    # cscli defaults to this path, nixpkgs only passes it to its own units via -c
    environment.etc."crowdsec/config.yaml".source =
      (pkgs.formats.yaml { }).generate "crowdsec.yaml"
        config.services.crowdsec.settings.general;

    systemd.services = {
      crowdsec = {
        # nixpkgs clears the unit path, the journalctl datasource needs journalctl
        path = lib.mkForce [ config.systemd.package ];
        serviceConfig.BindReadOnlyPaths = lib.mkIf traefik [
          "-${config.lib.server.mkConfigDir "traefik/logs"}:/var/log/traefik"
        ];
      };

      crowdsec-update-hub.serviceConfig = {
        ExecStart = lib.mkForce [
          "${cscli} --error hub update"
          "${cscli} --error hub upgrade"
        ];
        # upstream reloads, but the crowdsec unit has no ExecReload and this unit is unprivileged
        ExecStartPost = lib.mkForce "+${config.systemd.package}/bin/systemctl try-restart crowdsec.service";
      };

      # upstream's setup runs `machines add` before `capi register`, which fails while these credentials don't exist yet
      crowdsec-capi-register = {
        description = "Register crowdsec with the central API";
        wantedBy = [ "crowdsec.service" ];
        before = [ "crowdsec.service" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        unitConfig.ConditionPathExists = "!${config.services.crowdsec.settings.capi.credentialsFile}";
        serviceConfig = {
          Type = "oneshot";
          User = config.services.crowdsec.user;
          Group = config.services.crowdsec.group;
          ExecStart = "${cscli} capi register";
        };
      };

      crowdsec-firewall-bouncer-register.serviceConfig = {
        # upstream also lists crowdsec, which DynamicUser would move to /var/lib/private
        StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
        ReadWritePaths = [ "/var/lib/crowdsec" ];
      };

      crowdsec-firewall-bouncer = {
        after = [ "crowdsec-firewall-bouncer-register.service" ] ++ lib.optional docker "docker.service";
        partOf = lib.optional docker "docker.service";
        wantedBy = lib.optional docker "docker.service";
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 30;
        };
      };

      crowdsec-tailnet-allowlist = {
        description = "Allowlist the public endpoints of tailnet devices in crowdsec";
        after = [
          "crowdsec.service"
          "tailscaled.service"
        ];
        requires = [ "crowdsec.service" ];
        path = [
          config.services.tailscale.package
          pkgs.jq
          pkgs.util-linux
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          want=$(tailscale debug netmap | jq -r '[.Peers[].Endpoints[]? | sub(":[0-9]+$"; "") | ltrimstr("[") | rtrimstr("]")] | unique | .[]')
          if [ -z "$want" ]; then
            echo "no endpoints in the tailscale netmap, leaving the allowlist untouched" >&2
            exit 1
          fi
          if grep -qvE '^[0-9a-fA-F.:]+$' <<<"$want"; then
            echo "unexpected endpoint format in the tailscale netmap, leaving the allowlist untouched" >&2
            exit 1
          fi
          cs() { runuser -u crowdsec -- ${cscli} "$@"; }
          cs allowlists inspect tailnet >/dev/null 2>&1 || cs allowlists create tailnet -d "public endpoints of tailnet devices"
          have=$(cs allowlists inspect tailnet -o json | jq -r '.items[]?.value')
          add=$(comm -13 <(sort -u <<<"$have") <(sort -u <<<"$want"))
          del=$(comm -23 <(sort -u <<<"$have") <(sort -u <<<"$want"))
          [ -z "$add" ] || cs allowlists add tailnet $add -d "tailnet endpoint"
          [ -z "$del" ] || cs allowlists remove tailnet $del
        '';
      };
    };

    systemd.timers.crowdsec-tailnet-allowlist = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
      };
    };
  };
}
