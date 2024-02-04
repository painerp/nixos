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
  };

  config = lib.mkIf (cfg.grafana.enable || cfg.prometheus.enable
    || cfg.node-exporter.enable || cfg.cadvisor.enable) {
      age.secrets = lib.mkIf (cfg.grafana.enable) {
        grafana-env.file = cfg.grafana.env-file;
      };

      systemd.services.arion-monitoring = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
      };

      virtualisation.arion.projects.monitoring.settings = {
        project.name = "monitoring";
        networks.proxy.external =
          lib.mkIf (cfg.grafana.enable || cfg.prometheus.enable) true;
        networks.exporter.internal = lib.mkIf (cfg.prometheus.enable
          && (cfg.cadvisor.enable || cfg.node-exporter.enable)) true;

        services = lib.attrsets.optionalAttrs (cfg.grafana.enable) {
          grafana.service = {
            image = "grafana/grafana-oss:latest";
            container_name = "grafana";
            networks = [ "proxy" ];
            user = "0:0";
            volumes =
              [ "${config.lib.server.mkConfigDir "grafana"}:/var/lib/grafana" ];
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
        };
      };
    };
}
