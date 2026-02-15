{ lib, config, ... }:

let
  cfg = config.server.monitoring;
  alloyConfig = ''
    // Logs: systemd journal collection
    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h0m0s"
      path          = "/var/log/journal"
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.default.receiver]
      labels        = {
        host = "${config.networking.hostName}",
        job  = "systemd-journal",
      }
    }

    loki.write "default" {
      endpoint {
        url = "http://${cfg.alloy.loki.address}:${cfg.alloy.loki.port}/loki/api/v1/push"
      }
      external_labels = {}
    }

    // Metrics: Node exporter (host metrics)
    prometheus.exporter.unix "node" {
      rootfs_path    = "/rootfs"
      procfs_path    = "/host/proc"
      sysfs_path     = "/host/sys"

      disable_collectors = [
        "arp",
        "bcache",
        "bonding",
        "btrfs",
        "conntrack",
        "edac",
        "entropy",
        "fibrechannel",
        "hwmon",
        "infiniband",
        "ipvs",
        "mdadm",
        "nfs",
        "nfsd",
        "powersupplyclass",
        "rapl",
        "schedstat",
        "softnet",
        "tapestats",
        "textfile",
        "thermal_zone",
        "timex",
        "udp_queues",
        "xfs",
        "zfs",
      ]

      filesystem {
        mount_points_exclude = "^/(sys|proc|dev|host|etc|var/lib/docker/containers|var/lib/docker/overlay2|run/docker/netns|var/lib/docker/aufs|var/lib/containers/storage/overlay-containers/.*/userdata/shm)($|/)"
      }
    }

    prometheus.scrape "node" {
      targets    = prometheus.exporter.unix.node.targets
      forward_to = [prometheus.remote_write.default.receiver]
      scrape_interval = "15s"
      job_name = "node-exporter"
    }

    // Metrics: cAdvisor (container metrics)
    prometheus.exporter.cadvisor "containers" {
      docker_only = ${if config.modules.arion.backend == "docker" then "true" else "false"}
      store_container_labels = true

      disabled_metrics = [
        "advtcp",
        "cpu_topology",
        "cpuset",
        "disk",
        "diskIO",
        "hugetlb",
        "memory_numa",
        "percpu",
        "perf_event",
        "process",
        "referenced_memory",
        "resctrl",
        "sched",
        "tcp",
        "udp",
      ]
    }

    prometheus.scrape "cadvisor" {
      targets    = prometheus.exporter.cadvisor.containers.targets
      forward_to = [prometheus.remote_write.default.receiver]
      scrape_interval = "30s"
      job_name = "cadvisor"
    }

    ${lib.optionalString (config.server.traefik.enable && config.server.traefik.monitoring) ''
      // Metrics: Traefik
      prometheus.scrape "traefik" {
        targets = [{
          __address__ = "127.0.0.1:20003",
        }]
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "15s"
        job_name = "traefik"
      }
    ''}

    ${lib.optionalString (config.server.jellyfin.enable && config.server.jellyfin.exporter.enable) ''
      // Metrics: Jellyfin
      prometheus.scrape "jellyfin" {
        targets = [{
          __address__ = "127.0.0.1:20010",
        }]
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "30s"
        job_name = "jellyfin"
      }
    ''}

    // Metrics: Remote write to Prometheus
    prometheus.remote_write "default" {
      endpoint {
        url = "http://${cfg.alloy.prometheus.address}:${cfg.alloy.prometheus.port}/api/v1/write"
      }
    }
  '';
  alloyConfigFile = builtins.toFile "config.alloy" alloyConfig;
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
    alloy = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      loki = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };
        port = lib.mkOption {
          type = lib.types.str;
          default = "20100";
        };
      };
      prometheus = {
        address = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };
        port = lib.mkOption {
          type = lib.types.str;
          default = "20101";
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
          || cfg.pve-exporter.enable
          || cfg.alertmanager.enable
          || cfg.alloy.enable
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
            cfg.prometheus.enable && (cfg.pve-exporter.enable || cfg.loki.enable)
          ) true;
          networks.external.name = lib.mkIf (
            cfg.pve-exporter.enable || (cfg.loki.enable && cfg.loki.internal)
          ) "external";

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
                user = "0:0";
                command = [
                  "--web.enable-admin-api"
                  "--config.file=/etc/prometheus/prometheus.yml"
                  "--storage.tsdb.path=/prometheus"
                  "--storage.tsdb.retention.time=90d"
                  "--web.console.libraries=/usr/share/prometheus/console_libraries"
                  "--web.console.templates=/usr/share/prometheus/consoles"
                  "--web.enable-remote-write-receiver"
                ];
                networks = [
                  "proxy"
                ];
                ports = [ "${config.server.tailscale-ip}:20101:9090/tcp" ];
                volumes = [
                  "${config.lib.server.mkConfigDir "prometheus"}/prometheus.yml:/etc/prometheus/prometheus.yml:ro"
                  "${config.lib.server.mkConfigDir "prometheus/rules"}:/etc/prometheus/rules:ro"
                  "${config.lib.server.mkConfigDir "prometheus/data"}:/prometheus"
                ];
                healthcheck = {
                  test = [
                    "CMD-SHELL"
                    "wget --no-verbose --tries=1 --spider http://127.0.0.1:9090/-/ready || exit 1"
                  ];
                  interval = "30s";
                  timeout = "5s";
                  retries = 5;
                  start_period = "30s";
                };
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
                healthcheck = {
                  test = [
                    "CMD-SHELL"
                    "wget --no-verbose --tries=1 --spider http://127.0.0.1:3100/ready || exit 1"
                  ];
                  interval = "30s";
                  timeout = "5s";
                  retries = 5;
                  start_period = "10s";
                };
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
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
                    if (cfg.pve-exporter.internal) then [ "${config.server.tailscale-ip}:20002:9221/tcp" ] else [ ]
                  );
                env_file = [ config.age.secrets.pve-exporter-env.path ];
                restart = "unless-stopped";
              };

            }
            // lib.attrsets.optionalAttrs (cfg.alloy.enable) {
              alloy.service = {
                image = "docker.io/grafana/alloy:latest";
                container_name = "alloy";
                network_mode = "host";
                command = [
                  "run"
                  "--server.http.listen-addr=127.0.0.1:12345"
                  "--storage.path=/var/lib/alloy/data"
                  "/etc/alloy/config.alloy"
                ];
                volumes = [
                  "${alloyConfigFile}:/etc/alloy/config.alloy:ro"
                  "/var/log/journal:/var/log/journal:ro"
                  "/run/log/journal:/run/log/journal:ro"
                  "/etc/machine-id:/etc/machine-id:ro"
                  "/proc:/host/proc:ro"
                  "/sys:/host/sys:ro"
                  "/:/rootfs:ro,rslave"
                ]
                ++ (
                  if config.modules.arion.backend == "docker" then
                    [
                      "/var/run/docker.sock:/var/run/docker.sock:ro"
                      "/sys/fs/cgroup:/sys/fs/cgroup:ro"
                      "/dev/disk:/dev/disk:ro"
                    ]
                  else
                    [
                      "/run/podman/podman.sock:/run/podman/podman.sock:ro"
                      "/sys/fs/cgroup:/sys/fs/cgroup:ro"
                      "/dev/disk:/dev/disk:ro"
                    ]
                );
                depends_on =
                  (if cfg.loki.enable then { loki.condition = "service_healthy"; } else { })
                  // (if cfg.prometheus.enable then { prometheus.condition = "service_healthy"; } else { });
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                devices = [ "/dev/kmsg" ];
                privileged = true;
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
