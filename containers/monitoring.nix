{ lib, config, ... }:

let cfg = config.server.monitoring;
in {
  options.server.monitoring = {
    grafana = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "gr" else "grafana";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
    prometheus = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "pr" else "prometheus";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
    };
    node-exporter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      expose = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      internal = lib.mkOption {
        type = lib.types.bool;
        default = !cfg.node-exporter.expose;
      };
    };
    cadvisor = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      expose = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      internal = lib.mkOption {
        type = lib.types.bool;
        default = !cfg.cadvisor.expose;
      };
    };
    pve-exporter = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      expose = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      internal = lib.mkOption {
        type = lib.types.bool;
        default = !cfg.pve-exporter.expose;
      };
      env-file = lib.mkOption { type = lib.types.path; };
    };
    alertmanager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default =
          if config.server.short-subdomain then "am" else "alertmanager";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
    };
  };

  config = lib.mkIf (cfg.grafana.enable || cfg.prometheus.enable
    || cfg.node-exporter.enable || cfg.cadvisor.enable
    || cfg.pve-exporter.enable || cfg.alertmanager.enable) {
      age.secrets = (if cfg.grafana.enable then {
        grafana-env.file = cfg.grafana.env-file;
      } else
        { }) // (if cfg.pve-exporter.enable then {
          pve-exporter-env.file = cfg.pve-exporter.env-file;
        } else
          { });

      systemd.services.arion-monitoring = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      server.traefik.aliases = with config.lib.server;
        (if cfg.grafana.enable then
          mkTraefikAlias { subdomain = cfg.grafana.subdomain; }
        else
          [ ]) ++ (if cfg.prometheus.enable then
            mkTraefikAlias { subdomain = cfg.prometheus.subdomain; }
          else
            [ ]);

      virtualisation.arion.projects.monitoring.settings = {
        project.name = "monitoring";
        networks.proxy.external =
          lib.mkIf (cfg.grafana.enable || cfg.prometheus.enable) true;
        networks.exporter.internal = lib.mkIf (cfg.prometheus.enable
          && (cfg.cadvisor.enable || cfg.pve-exporter.enable
            || cfg.node-exporter.enable)) true;
        networks.external.name = lib.mkIf (cfg.pve-exporter.enable) "external";

        services = lib.attrsets.optionalAttrs (cfg.grafana.enable) {
          grafana.service = {
            image = "grafana/grafana-oss:latest";
            container_name = "grafana";
            networks = [ "proxy" ];
            user = "0:0";
            volumes =
              [ "${config.lib.server.mkConfigDir "grafana"}:/var/lib/grafana" ];
            environment = {
              GF_SERVER_DOMAIN = config.server.domain;
              GF_SERVER_ROOT_URL =
                "https://${cfg.grafana.subdomain}.${config.server.domain}";
            };
            env_file = [ config.age.secrets.grafana-env.path ];
            labels = config.lib.server.mkTraefikLabels {
              name = "grafana";
              subdomain = "${cfg.grafana.subdomain}";
              port = "3000";
              forwardAuth = cfg.grafana.auth;
            };
            restart = "unless-stopped";
          };

        } // lib.attrsets.optionalAttrs (cfg.prometheus.enable) {
          prometheus.service = {
            image = "prom/prometheus:latest";
            container_name = "prometheus";
            networks = [ "proxy" ]
              ++ (if (cfg.cadvisor.enable || cfg.node-exporter.enable) then
                [ "exporter" ]
              else
                [ ]);
            user = "0:0";
            command = [
              "--web.enable-admin-api"
              "--config.file=/etc/prometheus/prometheus.yml"
              "--storage.tsdb.path=/prometheus"
              "--web.console.libraries=/usr/share/prometheus/console_libraries"
              "--web.console.templates=/usr/share/prometheus/consoles"
            ];
            volumes = [
              "${
                config.lib.server.mkConfigDir "prometheus"
              }/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
              "${config.lib.server.mkConfigDir "prometheus/data"}:/prometheus"
            ];
            labels = config.lib.server.mkTraefikLabels {
              name = "prometheus";
              subdomain = "${cfg.prometheus.subdomain}";
              port = "9090";
              forwardAuth = cfg.prometheus.auth;
            };
            restart = "unless-stopped";
          };

        } // lib.attrsets.optionalAttrs (cfg.node-exporter.enable) {
          node-exporter.service = {
            image = "quay.io/prometheus/node-exporter:latest";
            container_name = "node-exporter";
            networks = lib.mkIf (cfg.prometheus.enable) [ "exporter" ];
            ports =
              (if (cfg.node-exporter.expose) then [ "9100:9100/tcp" ] else [ ])
              ++ (if (cfg.node-exporter.internal) then
                [ "${config.server.tailscale-ip}:20001:9100/tcp" ]
              else
                [ ]);
            command = [ "--path.rootfs=/host" ];
            volumes = [ "/:/host:ro,rslave" ];
            restart = "unless-stopped";
          };

        } // lib.attrsets.optionalAttrs (cfg.cadvisor.enable) {
          cadvisor.service = {
            image = "gcr.io/cadvisor/cadvisor:latest";
            container_name = "cadvisor";
            command = [
              "--housekeeping_interval=10s"
              "--docker_only"
              "--store_container_labels=false"
            ];
            networks = lib.mkIf (cfg.prometheus.enable) [ "exporter" ];
            ports = (if (cfg.cadvisor.expose) then [ "8080:8080/tcp" ] else [ ])
              ++ (if (cfg.cadvisor.internal) then
                [ "${config.server.tailscale-ip}:20000:8080/tcp" ]
              else
                [ ]);
            volumes = [
              "/:/rootfs:ro"
              "/var/run:/var/run:ro"
              "/sys:/sys:ro"
              "/var/lib/docker/:/var/lib/docker:ro"
              "/dev/disk/:/dev/disk:ro"
            ];
            devices = [ "/dev/kmsg" ];
            privileged = true;
            restart = "unless-stopped";
          };

        } // lib.attrsets.optionalAttrs (cfg.pve-exporter.enable) {
          pve-exporter.service = {
            image = "prompve/prometheus-pve-exporter:latest";
            container_name = "pve-exporter";
            networks = [ "external" ]
              ++ (if (cfg.prometheus.enable) then [ "exporter" ] else [ ]);
            ports =
              (if (cfg.pve-exporter.expose) then [ "9221:9221/tcp" ] else [ ])
              ++ (if (cfg.node-exporter.internal) then
                [ "${config.server.tailscale-ip}:20002:9221/tcp" ]
              else
                [ ]);
            env_file = [ config.age.secrets.pve-exporter-env.path ];
            restart = "unless-stopped";
          };

        } // lib.attrsets.optionalAttrs (cfg.alertmanager.enable) {
          alertmanager.service = {
            image = "prom/alertmanager:latest";
            container_name = "alertmanager";
            networks = lib.mkIf (cfg.prometheus.enable) [ "exporter" ];
            volumes = [
              "${
                config.lib.server.mkConfigDir "alertmanager"
              }:/etc/alertmanager"
            ];
            labels = config.lib.server.mkTraefikLabels {
              name = "alertmanager";
              subdomain = "${cfg.alertmanager.subdomain}";
              port = "9093";
              forwardAuth = cfg.alertmanager.auth;
            };
            restart = "unless-stopped";
          };
        };
      };
    };
}
