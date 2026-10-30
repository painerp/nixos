{ lib, config, ... }:

let
  cfg = config.server.monitoring;
  nixlog = (import ../tailnet.nix).hosts.nixlog;
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

    ${lib.optionalString (config.modules.arion.backend == "docker") ''
      // Metrics: cAdvisor (container metrics)
      // Note: Only enabled on Docker systems. Podman support coming in future Alloy versions.
      prometheus.exporter.cadvisor "containers" {
        docker_only = true
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
    ''}

    ${lib.optionalString (config.server.traefik.enable && config.server.traefik.monitoring) ''
      // Metrics: Traefik
      prometheus.scrape "traefik" {
        targets = [{
          __address__ = "127.0.0.1:20003",
          instance    = "${config.networking.hostName}",
        }]
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "30s"
        job_name = "traefik"
      }
    ''}

    ${lib.optionalString (cfg.pve-exporter.enable) ''
      // Metrics: PVE exporter
      discovery.relabel "pve" {
        targets = [{
          __address__ = "proxmox.${config.server.domain}:443",
        }]

        // Set the target parameter for the exporter
        rule {
          source_labels = ["__address__"]
          target_label  = "__param_target"
        }

        // Set the instance label to the Proxmox host
        rule {
          source_labels = ["__param_target"]
          target_label  = "instance"
        }

        // Replace __address__ with the exporter's address
        rule {
          replacement  = "127.0.0.1:20002"
          target_label = "__address__"
        }
      }

      prometheus.scrape "pve_exporter" {
        targets = discovery.relabel.pve.output
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "15s"
        job_name = "pve"
        metrics_path = "/pve"
        params = {
          module  = ["default"],
          cluster = ["1"],
          node    = ["1"],
        }
      }
    ''}

    ${lib.optionalString (config.server.jellyfin.enable && config.server.jellyfin.exporter.enable) ''
      // Metrics: Jellyfin
      prometheus.scrape "jellyfin" {
        targets = [{
          __address__ = "127.0.0.1:20010",
          instance    = "${config.networking.hostName}",
        }]
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "30s"
        job_name = "jellyfin"
      }
    ''}

    ${lib.optionalString
      (config.server.nuxt-pages.app.enable && config.server.nuxt-pages.app.metrics.enable)
      ''
        // Metrics: nuxt-pages app, fixed instance so moving hosts doesn't split the series
        prometheus.scrape "nuxt_pages" {
          targets = [{
            __address__ = "127.0.0.1:20005",
            instance    = "nuxt-pages",
          }]
          forward_to = [prometheus.remote_write.default.receiver]
          scrape_interval = "60s"
          scrape_timeout = "10s"
          job_name = "nuxt-pages"
          bearer_token = sys.env("NUXT_METRICS_TOKEN")
        }
      ''
    }

    ${lib.optionalString (config.server.peanut.enable) ''
      // Metrics: Peanut (local port, traefik puts it behind authentik)
      prometheus.scrape "peanut" {
        targets = [{
          __address__ = "127.0.0.1:20004",
          instance    = "${config.networking.hostName}",
        }]
        metrics_path = "/api/v1/metrics"
        forward_to = [prometheus.remote_write.default.receiver]
        scrape_interval = "30s"
        job_name = "peanut"
        basic_auth {
          username = env("WEB_USERNAME")
          password = env("WEB_PASSWORD")
        }
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
  prometheusConfigFile = builtins.toFile "prometheus.yml" (
    builtins.toJSON {
      global = {
        scrape_interval = "15s";
        external_labels.prometheus = config.networking.hostName;
      };
      rule_files = [
        "rules/*.yml"
        "rules-nix/*.yml"
      ];
      alerting.alertmanagers = [ { static_configs = [ { targets = [ "alertmanager:9093" ]; } ]; } ];
      scrape_configs = [
        {
          job_name = "prometheus";
          static_configs = [ { targets = [ "localhost:9090" ]; } ];
        }
        {
          job_name = "thanos";
          static_configs = [
            {
              targets = map (n: "thanos-${n}:10902") [
                "sidecar"
                "store"
                "compact"
                "query"
              ];
            }
          ];
        }
      ]
      ++ lib.optional cfg.loki.enable {
        job_name = "loki";
        static_configs = [ { targets = [ "loki:3100" ]; } ];
      };
    }
  );
  monitoringRulesFile = builtins.toFile "monitoring.yml" (
    builtins.toJSON {
      groups = [
        {
          name = "monitoring";
          rules = [
            {
              alert = "ThanosDown";
              expr = ''up{job="thanos"} == 0'';
              for = "5m";
              labels.severity = "critical";
              annotations.summary = "{{ $labels.instance }} is down";
            }
            {
              alert = "ThanosCompactHalted";
              expr = "thanos_compact_halted == 1";
              for = "5m";
              labels.severity = "critical";
              annotations.summary = "Thanos compactor halted, archive is no longer compacted or pruned";
            }
            {
              alert = "ThanosUploadFailing";
              expr = "increase(thanos_shipper_dir_sync_failures_total[1h]) > 0";
              for = "5m";
              labels.severity = "warning";
              annotations.summary = "Thanos sidecar fails to upload blocks to the NAS";
            }
            {
              alert = "LokiDown";
              expr = ''up{job="loki"} == 0'';
              for = "5m";
              labels.severity = "critical";
              annotations.summary = "Loki is down";
            }
            {
              alert = "LokiFlushFailing";
              expr = "increase(loki_ingester_chunks_flush_failures_total[1h]) > 0";
              for = "5m";
              labels.severity = "warning";
              annotations.summary = "Loki fails to flush chunks to the NAS";
            }
          ];
        }
        {
          name = "nuxt-pages";
          rules = [
            {
              alert = "NuxtPagesMetricsDown";
              expr = ''up{job="nuxt-pages"} == 0'';
              for = "10m";
              labels.severity = "warning";
              annotations.summary = "nuxt-pages /metrics can't be scraped";
            }
            {
              alert = "TeamspeakCountStale";
              expr = ''time() - teamspeak_last_count_timestamp_seconds{job="nuxt-pages"} > 600'';
              labels.severity = "critical";
              annotations.summary = "TeamSpeak time wasn't counted for {{ $value | humanizeDuration }}";
            }
            {
              alert = "StreamCheckStale";
              expr = ''time() - stream_last_check_timestamp_seconds{job="nuxt-pages"} > 600'';
              labels.severity = "critical";
              annotations.summary = "{{ $labels.platform }} live check didn't succeed for {{ $value | humanizeDuration }}";
            }
            # the stale rules return nothing for a job that never counted since a start
            {
              alert = "TeamspeakCountMissing";
              expr = ''absent(teamspeak_last_count_timestamp_seconds{job="nuxt-pages"})'';
              for = "15m";
              labels.severity = "critical";
              annotations.summary = "TeamSpeak time isn't counted";
            }
            {
              alert = "StreamCheckMissing";
              expr =
                lib.concatMapStringsSep " or "
                  (p: ''absent(stream_last_check_timestamp_seconds{job="nuxt-pages",platform="${p}"})'')
                  [
                    "twitch"
                    "youtube"
                  ];
              for = "15m";
              labels.severity = "critical";
              annotations.summary = "{{ $labels.platform }} live check doesn't run";
            }
          ];
        }
      ];
    }
  );
  lokiConfigFile = builtins.toFile "loki.yml" (
    builtins.toJSON {
      auth_enabled = false;
      server.http_listen_port = 3100;
      analytics.reporting_enabled = false;
      common = {
        path_prefix = "/loki";
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        storage.s3 = {
          inherit (cfg.s3) endpoint region;
          bucketnames = "loki";
          access_key_id = "\${AWS_ACCESS_KEY_ID}";
          secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
          insecure = true;
          s3forcepathstyle = true;
        };
      };
      schema_config.configs = [
        {
          from = "2020-10-24";
          store = "tsdb";
          object_store = "s3";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      ingester.chunk_encoding = "zstd";
      limits_config.retention_period = "26280h";
      compactor = {
        working_directory = "/loki/compactor";
        retention_enabled = true;
        delete_request_store = "s3";
      };
      chunk_store_config.chunk_cache_config.embedded_cache = {
        enabled = true;
        max_size_mb = 128;
      };
      query_range = {
        cache_results = true;
        results_cache.cache.embedded_cache = {
          enabled = true;
          max_size_mb = 64;
        };
      };
      ruler.alertmanager_url = "http://alertmanager:9093";
    }
  );
  # a variable upstream makes nginx re-resolve thanos-query after it's recreated.
  # without max_source_resolution instant queries only see raw data (90d)
  prometheusPublicConfigFile = builtins.toFile "prometheus-public.conf" ''
    server {
      listen 80;
      resolver ''${NGINX_LOCAL_RESOLVERS} valid=10s;
      set $upstream thanos-query:10902;
      if ($arg_time !~ "^([0-9]{9,10}(\.[0-9]{1,3})?)?$") { return 400; }
      ${lib.concatStrings (
        lib.mapAttrsToList (name: query: ''
          location = /${name} {
            limit_except GET { deny all; }
            rewrite ^ /api/v1/query?query=${lib.escapeURL query}&time=$arg_time&max_source_resolution=1h&partial_response=false? break;
            proxy_pass http://$upstream;
          }
        '') cfg.prometheus.public.queries
      )}
      location / { return 404; }
    }
  '';
  # tailnet entry for alloy, so monitoring hosts can't query or reach the admin api
  prometheusWriteConfigFile = builtins.toFile "prometheus-write.conf" ''
    server {
      listen 80;
      resolver ''${NGINX_LOCAL_RESOLVERS} valid=10s;
      set $upstream prometheus:9090;
      client_max_body_size 16m;
      location = /api/v1/write {
        limit_except POST { deny all; }
        proxy_pass http://$upstream;
      }
      location / { return 404; }
    }
  '';
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
      public = {
        subdomain = lib.mkOption {
          type = lib.types.str;
          default = "metrics";
        };
        queries = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          description = "Fixed PromQL queries served without auth as GET /<name>[?time=<unix seconds>]";
        };
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
          default = nixlog;
        };
        port = lib.mkOption {
          type = lib.types.str;
          default = "20100";
        };
      };
      prometheus = {
        address = lib.mkOption {
          type = lib.types.str;
          default = nixlog;
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
    s3 = {
      endpoint = lib.mkOption { type = lib.types.str; };
      region = lib.mkOption {
        type = lib.types.str;
        default = "garage";
      };
      env-file = lib.mkOption { type = lib.types.path; };
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
          // (if cfg.pve-exporter.enable then { pve-exporter-env.file = cfg.pve-exporter.env-file; } else { })
          // (
            if cfg.prometheus.enable || cfg.loki.enable then
              { monitoring-s3-env.file = cfg.s3.env-file; }
            else
              { }
          );

        systemd.services.arion-monitoring = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
        };

        server.traefik.aliases =
          with config.lib.server;
          (if cfg.grafana.enable then mkTraefikAlias { subdomain = cfg.grafana.subdomain; } else [ ])
          ++ (if cfg.prometheus.enable then mkTraefikAlias { subdomain = cfg.prometheus.subdomain; } else [ ])
          ++ (
            if cfg.prometheus.enable && cfg.prometheus.public.queries != { } then
              mkTraefikAlias { subdomain = cfg.prometheus.public.subdomain; }
            else
              [ ]
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
                  "--storage.tsdb.retention.size=20GB"
                  "--storage.tsdb.min-block-duration=2h"
                  "--storage.tsdb.max-block-duration=2h"
                  "--web.console.libraries=/usr/share/prometheus/console_libraries"
                  "--web.console.templates=/usr/share/prometheus/consoles"
                  "--web.enable-remote-write-receiver"
                ];
                networks = [ "proxy" ] ++ lib.optional cfg.loki.enable "exporter";
                volumes = [
                  "${prometheusConfigFile}:/etc/prometheus/prometheus.yml:ro"
                  "${config.lib.server.mkConfigDir "prometheus/rules"}:/etc/prometheus/rules:ro"
                  "${monitoringRulesFile}:/etc/prometheus/rules-nix/monitoring.yml:ro"
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
              };

              prometheus.out.service.oom_score_adj = -500;

              prometheus-write.service = {
                image = "docker.io/nginx:alpine";
                container_name = "prometheus-write";
                networks = [ "proxy" ];
                ports = [ "${config.server.tailscale-ip}:20101:80/tcp" ];
                environment.NGINX_ENTRYPOINT_LOCAL_RESOLVERS = "1";
                volumes = [ "${prometheusWriteConfigFile}:/etc/nginx/templates/default.conf.template:ro" ];
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
              };
            }
            // lib.attrsets.optionalAttrs (cfg.prometheus.enable && cfg.prometheus.public.queries != { }) {
              prometheus-public.service = {
                image = "docker.io/nginx:alpine";
                container_name = "prometheus-public";
                networks = [ "proxy" ];
                environment.NGINX_ENTRYPOINT_LOCAL_RESOLVERS = "1";
                volumes = [ "${prometheusPublicConfigFile}:/etc/nginx/templates/default.conf.template:ro" ];
                labels =
                  config.lib.server.mkTraefikLabels {
                    name = "prometheus-public";
                    subdomain = cfg.prometheus.public.subdomain;
                    port = "80";
                  }
                  // {
                    "com.centurylinklabs.watchtower.enable" = "true";
                  };
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
                  "-config.expand-env=true"
                ];
                env_file = [ config.age.secrets.monitoring-s3-env.path ];
                volumes = [
                  "${lokiConfigFile}:/etc/loki/config.yml:ro"
                  "${config.lib.server.mkConfigDir "loki/data"}:/loki"
                ];
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
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
                ports = [ "127.0.0.1:20002:9221/tcp" ];
                env_file = [ config.age.secrets.pve-exporter-env.path ];
              };

            }
            // lib.attrsets.optionalAttrs (cfg.alloy.enable) {
              alloy.service = {
                image = "docker.io/grafana/alloy:latest";
                container_name = "alloy";
                network_mode = "host";
                env_file =
                  lib.optional config.server.peanut.enable config.age.secrets.peanut-env.path
                  ++ lib.optional (
                    config.server.nuxt-pages.app.enable && config.server.nuxt-pages.app.metrics.enable
                  ) config.age.secrets.nuxt-pages-metrics-env.path;
                command = [
                  "run"
                  "--server.http.listen-addr=127.0.0.1:12345"
                  "--storage.path=/var/lib/alloy/data"
                  "--disable-reporting"
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
                  # cAdvisor mounts only needed on Docker systems
                  if config.modules.arion.backend == "docker" then
                    [
                      "/var/run/docker.sock:/var/run/docker.sock:ro"
                      "/sys/fs/cgroup:/sys/fs/cgroup:ro"
                      "/dev/disk:/dev/disk:ro"
                      "/var/lib/docker:/var/lib/docker:ro"
                    ]
                  else
                    [ ]
                );
                depends_on =
                  (if cfg.loki.enable then { loki.condition = "service_started"; } else { })
                  // (if cfg.prometheus.enable then { prometheus.condition = "service_healthy"; } else { });
                labels = {
                  "com.centurylinklabs.watchtower.enable" = "true";
                };
                devices = [ "/dev/kmsg" ];
                privileged = true;
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
              };
            };
        };
      };
}
