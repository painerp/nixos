{ lib, config, ... }:

let
  cfg = config.server.thanos;
  s3 = config.server.monitoring.s3;
  objstoreConfigFile = builtins.toFile "objstore.yml" (
    builtins.toJSON {
      type = "S3";
      config = {
        bucket = "thanos";
        inherit (s3) endpoint region;
        insecure = true;
        bucket_lookup_type = "path";
      };
    }
  );
  mkService = name: memory: command: extra: {
    out.service.mem_limit = memory;
    service = {
      image = "quay.io/thanos/thanos:${cfg.version}";
      container_name = "thanos-${name}";
      user = "0:0";
      networks = [ "proxy" ];
      command = [ name ] ++ command;
    }
    // extra;
  };
in
{
  options.server.thanos.version = lib.mkOption {
    type = lib.types.str;
    default = "latest";
  };

  config = lib.mkIf (config.modules.arion.enable && config.server.monitoring.prometheus.enable) {
    systemd.tmpfiles.rules = [
      "d ${config.lib.server.mkConfigDir "thanos/store"} 0755 root root -"
      "d ${config.lib.server.mkConfigDir "thanos/compact"} 0755 root root -"
    ];

    virtualisation.arion.projects.monitoring.settings.services = {
      thanos-sidecar =
        mkService "sidecar" "256m"
          [
            "--tsdb.path=/prometheus"
            "--prometheus.url=http://prometheus:9090"
            "--objstore.config-file=/etc/thanos/objstore.yml"
          ]
          {
            env_file = [ config.age.secrets.monitoring-s3-env.path ];
            volumes = [
              "${config.lib.server.mkConfigDir "prometheus/data"}:/prometheus"
              "${objstoreConfigFile}:/etc/thanos/objstore.yml:ro"
            ];
            depends_on.prometheus.condition = "service_healthy";
          };

      thanos-store =
        mkService "store" "512m"
          [
            "--data-dir=/data"
            "--objstore.config-file=/etc/thanos/objstore.yml"
            "--index-cache-size=128MB"
            "--max-time=-7d"
          ]
          {
            env_file = [ config.age.secrets.monitoring-s3-env.path ];
            volumes = [
              "${config.lib.server.mkConfigDir "thanos/store"}:/data"
              "${objstoreConfigFile}:/etc/thanos/objstore.yml:ro"
            ];
          };

      thanos-compact =
        mkService "compact" "1g"
          [
            "--wait"
            "--data-dir=/data"
            "--objstore.config-file=/etc/thanos/objstore.yml"
            "--retention.resolution-raw=90d"
            "--retention.resolution-5m=365d"
            "--retention.resolution-1h=1095d"
            "--compact.enable-vertical-compaction"
          ]
          {
            env_file = [ config.age.secrets.monitoring-s3-env.path ];
            volumes = [
              "${config.lib.server.mkConfigDir "thanos/compact"}:/data"
              "${objstoreConfigFile}:/etc/thanos/objstore.yml:ro"
            ];
          };

      thanos-query = mkService "query" "512m" [
        "--query.auto-downsampling"
        "--store.response-timeout=10s"
        "--endpoint.sd-config=${
          builtins.toJSON {
            endpoints = [
              { address = "thanos-sidecar:10901"; }
              { address = "thanos-store:10901"; }
            ];
          }
        }"
      ] { };
    };
  };
}
