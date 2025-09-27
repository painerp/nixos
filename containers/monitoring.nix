{ lib, config, ... }:

let
  cfg = config.server.monitoring;
  promtailConfig = {
    server = {
      http_listen_port = 9080;
      grpc_listen_port = 0;
    };
    positions.filename = "/tmp/positions.yaml";
    clients = [
      { url = "http://${cfg.promtail.loki.address}:${cfg.promtail.loki.port}/loki/api/v1/push"; }
    ];
    scrape_configs = [
      {
        job_name = "journal";
        journal = {
          json = false;
          max_age = "12h";
          path = "/var/log/journal";
          labels = {
            job = "systemd-journal";
            host = config.networking.hostName;
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }
        ];
      }
    ];
  };
  promtailConfigFile = builtins.toFile "promtail_config.yml" (builtins.toJSON promtailConfig);
in
{
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
    loki = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      internal = lib.mkOption {
        type = lib.types.bool;
        default = false;
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
    promtail = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      loki = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "loki";
        };
        port = lib.mkOption {
          type = lib.types.str;
          default = if cfg.promtail.loki.address == "loki" then "3100" else "20100";
        };
      };
    };
    alertmanager = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      subdomain = lib.mkOption {
        type = lib.types.str;
        default = if config.server.short-subdomain then "am" else "alertmanager";
      };
      auth = lib.mkOption {
        type = lib.types.bool;
        default = config.server.authentik.enable;
      };
    };
  };

  config =
    lib.mkIf
      (
        config.modules.arion.enable
        && (
          cfg.grafana.enable
          || cfg.prometheus.enable
          || cfg.node-exporter.enable
          || cfg.cadvisor.enable
          || cfg.pve-exporter.enable
          || cfg.alertmanager.enable
        )
      )
      {
        age.secrets =
          (if cfg.grafana.enable then { grafana-env.file = cfg.grafana.env-file; } else { })
          // (
            if cfg.pve-exporter.enable then { pve-exporter-env.file = cfg.pve-exporter.env-file; } else { }
          );

        systemd.services.arion-monitoring = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };

        server.traefik.aliases =
          with config.lib.server;
          (if cfg.grafana.enable then mkTraefikAlias { subdomain = cfg.grafana.subdomain; } else [ ])
          ++ (
            if cfg.prometheus.enable then mkTraefikAlias { subdomain = cfg.prometheus.subdomain; } else [ ]
          );

        virtualisation.arion.projects.monitoring.settings = {
          project.name = "monitoring";
          networks.proxy.external = lib.mkIf (cfg.grafana.enable || cfg.prometheus.enable) true;
          networks.exporter.internal = lib.mkIf (
            cfg.prometheus.enable
            && (cfg.cadvisor.enable || cfg.pve-exporter.enable || cfg.node-exporter.enable)
          ) true;
          networks.external.name = lib.mkIf (cfg.pve-exporter.enable) "external";

          services =
            lib.attrsets.optionalAttrs (cfg.grafana.enable) {
              grafana.service = {
                image = "docker.io/grafana/grafana-oss:latest";
                container_name = "grafana";
                networks = [ "proxy" ] ++ (if (cfg.loki.enable) then [ "exporter" ] else [ ]);
                user = "0:0";
                volumes = [ "${config.lib.server.mkConfigDir "grafana"}:/var/lib/grafana" ];
                environment = {
                  GF_SERVER_DOMAIN = config.server.domain;
                  GF_SERVER_ROOT_URL = "https://${cfg.grafana.subdomain}.${config.server.domain}";
                  GF_PATHS_CONFIG = "/var/lib/grafana/grafana.ini";
                };
                env_file = [ config.age.secrets.grafana-env.path ];
                labels =
                  config.lib.server.mkTraefikLabels {
                    name = "grafana";
                    subdomain = "${cfg.grafana.subdomain}";
                    port = "3000";
                    forwardAuth = cfg.grafana.auth;
                  }
                  // {
                    "com.centurylinklabs.watchtower.enable" = "true";
                  };
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.prometheus.enable) {
              prometheus.service = {
                image = "docker.io/prom/prometheus:latest";
                container_name = "prometheus";
                networks = [
                  "proxy"
                ]
                ++ (if (cfg.cadvisor.enable || cfg.node-exporter.enable) then [ "exporter" ] else [ ]);
                user = "0:0";
                command = [
                  "--web.enable-admin-api"
                  "--config.file=/etc/prometheus/prometheus.yml"
                  "--storage.tsdb.path=/prometheus"
                  "--storage.tsdb.retention.time=90d"
                  "--web.console.libraries=/usr/share/prometheus/console_libraries"
                  "--web.console.templates=/usr/share/prometheus/consoles"
                ];
                volumes = [
                  "${config.lib.server.mkConfigDir "prometheus"}/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
                  "${config.lib.server.mkConfigDir "prometheus/rules"}:/etc/prometheus/rules:ro"
                  "${config.lib.server.mkConfigDir "prometheus/data"}:/prometheus"
                ];
                labels =
                  config.lib.server.mkTraefikLabels {
                    name = "prometheus";
                    subdomain = "${cfg.prometheus.subdomain}";
                    port = "9090";
                    forwardAuth = cfg.prometheus.auth;
                  }
                  // {
                    "com.centurylinklabs.watchtower.enable" = "true";
                  };
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.loki.enable) {
              loki.service = {
                image = "docker.io/grafana/loki:latest";
                container_name = "loki";
                networks = [ "exporter" ] ++ (if (cfg.loki.internal) then [ "external" ] else [ ]);
                ports = (if (cfg.loki.internal) then [ "${config.server.tailscale-ip}:20100:3100/tcp" ] else [ ]);
                command = [
                  "-config.file=/etc/loki/config.yml"
                  "-auth.enabled=false"
                  "-server.http-listen-port=3100"
                  "-store.retention=360d"
                  "-compactor.retention-enabled=true"
                  "-compactor.delete-request-store=filesystem"
                  "-common.path-prefix=/loki"
                  "-common.storage.filesystem.chunk-directory=/loki/chunks"
                  "-common.storage.filesystem.rules-directory=/loki/rules"
                  "-common.storage.ring.instance-addr=127.0.0.1"
                  "-common.storage.ring.store=inmemory"
                  "-local.chunk-directory=/loki/storage"
                  "-ruler.alertmanager-url=http://alertmanager:9093"
                  "-reporting.enabled=false"
                ];
                volumes = [
                  "${config.lib.server.mkConfigDir "loki/config"}:/etc/loki"
                  "${config.lib.server.mkConfigDir "loki/data"}:/loki"
                ];
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.node-exporter.enable) {
              node-exporter.service = {
                image = "quay.io/prometheus/node-exporter:latest";
                container_name = "node-exporter";
                networks = lib.mkIf (cfg.prometheus.enable) [ "exporter" ];
                ports =
                  (if (cfg.node-exporter.expose) then [ "9100:9100/tcp" ] else [ ])
                  ++ (
                    if (cfg.node-exporter.internal) then [ "${config.server.tailscale-ip}:20001:9100/tcp" ] else [ ]
                  );
                command = [
                  "--path.rootfs=/rootfs"
                  "--path.procfs=/host/proc"
                  "--path.sysfs=/host/sys"
                  "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|var/lib/docker/containers|var/lib/docker/overlay2|run/docker/netns|var/lib/docker/aufs|var/lib/containers/storage/overlay-containers/.*/userdata/shm)($$|/)"
                ];
                volumes = [
                  "/proc:/host/proc:ro"
                  "/sys:/host/sys:ro"
                  "/:/rootfs:ro,rslave"
                ];
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.cadvisor.enable) {
              cadvisor.service = {
                image = "gcr.io/cadvisor/cadvisor:latest";
                container_name = "cadvisor";
                command = [
                  "--housekeeping_interval=30s"
                  "--raw_cgroup_prefix_whitelist=/machine.slice/libpod"
                  "--store_container_labels=false"
                  "--disable_metrics=disk,diskIO"
                ]
                ++ (if config.modules.arion.backend == "docker" then [ "--docker_only" ] else [ ]);
                networks = lib.mkIf (cfg.prometheus.enable) [ "exporter" ];
                ports =
                  (if (cfg.cadvisor.expose) then [ "8080:8080/tcp" ] else [ ])
                  ++ (if (cfg.cadvisor.internal) then [ "${config.server.tailscale-ip}:20000:8080/tcp" ] else [ ]);
                volumes = [
                  "/:/rootfs:ro"
                  "/sys/fs/cgroup:/sys/fs/cgroup:ro"
                  "/dev/disk/:/dev/disk:ro"
                ]
                ++ (
                  if config.modules.arion.backend == "docker" then
                    [ "/var/run/docker.sock:/var/run/docker.sock:ro" ]
                  else
                    [ "/run/podman/podman.sock:/run/podman/podman.sock:ro" ]
                );
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                devices = [ "/dev/kmsg" ];
                privileged = true;
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.pve-exporter.enable) {
              pve-exporter.service = {
                image = "docker.io/prompve/prometheus-pve-exporter:latest";
                container_name = "pve-exporter";
                networks = [ "external" ] ++ (if (cfg.prometheus.enable) then [ "exporter" ] else [ ]);
                sysctls = {
                  "net.ipv6.conf.all.disable_ipv6" = 1;
                };
                ports =
                  (if (cfg.pve-exporter.expose) then [ "9221:9221/tcp" ] else [ ])
                  ++ (
                    if (cfg.node-exporter.internal) then [ "${config.server.tailscale-ip}:20002:9221/tcp" ] else [ ]
                  );
                env_file = [ config.age.secrets.pve-exporter-env.path ];
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.promtail.enable) {
              promtail.service = {
                image = "docker.io/grafana/promtail:latest";
                container_name = "promtail";
                networks = (if (cfg.loki.enable) then [ "exporter" ] else [ "external" ]);
                command = [ "-config.file=/promtail_config.yml" ];
                volumes = [
                  "${promtailConfigFile}:/promtail_config.yml"
                  "/var/log/journal:/var/log/journal"
                  "/run/log/journal:/run/log/journal"
                  "/etc/machine-id:/etc/machine-id"
                ];
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.alertmanager.enable) {
              alertmanager.service = {
                image = "docker.io/prom/alertmanager:latest";
                container_name = "alertmanager";
                networks = [ "proxy" ] ++ (if (cfg.prometheus.enable) then [ "exporter" ] else [ ]);
                volumes = [ "${config.lib.server.mkConfigDir "alertmanager"}:/etc/alertmanager" ];
                labels =
                  config.lib.server.mkTraefikLabels {
                    name = "alertmanager";
                    subdomain = "${cfg.alertmanager.subdomain}";
                    port = "9093";
                    forwardAuth = cfg.alertmanager.auth;
                  }
                  // {
                    "com.centurylinklabs.watchtower.enable" = "true";
                  };
                restart = "unless-stopped";
              };
            };
        };
      };
}
