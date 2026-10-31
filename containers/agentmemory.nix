{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.server.agentmemory;
  config-dir = config.lib.server.mkConfigDir "agentmemory";
  viewer-host = "${cfg.subdomain}.${config.server.domain}";
  api-host = "${cfg.api-subdomain}.${config.server.domain}";
  iii-version = "0.25.0";
  dockerfile =
    lib.replaceStrings [ "@agentmemory-version@" "@iii-version@" ] [ cfg.version iii-version ]
      (builtins.readFile ./agentmemory/Dockerfile);
  build-context = pkgs.writeTextDir "Dockerfile" dockerfile;
  image-tag = "${cfg.version}-${builtins.substring 0 12 (builtins.hashString "sha256" dockerfile)}";
  worker-compose = builtins.toFile "agentmemory-worker-compose.yaml" (
    builtins.toJSON {
      namespace = "agentmemory";
      startup_timeout = "300s";
      stop_timeout = "20s";
      required_default = true;
      engine = {
        url = "ws://127.0.0.1:49134";
        workers = {
          configuration.adapter = {
            name = "fs";
            config.directory = "/app/config";
          };
          iii-worker-manager = {
            port = 49134;
            host = "127.0.0.1";
          };
        };
      };
      containers = {
        state = {
          worker = "package://api.workers.iii.dev/state";
          version = "0.22.20";
          config_name = "state";
          restart = "on-failure";
          config_override.adapter = {
            name = "kv";
            config = {
              store_method = "file_based";
              save_interval_ms = 2000;
              file_path = "/data/state_store.db";
            };
          };
        };
        http = {
          worker = "package://api.workers.iii.dev/http";
          version = "0.22.7";
          config_name = "http";
          restart = "on-failure";
          config_override = {
            port = 3111;
            host = "0.0.0.0";
            default_timeout = 180000;
            cors = {
              allowed_origins = [
                "https://${viewer-host}"
                "https://${api-host}"
              ];
              allowed_methods = [
                "GET"
                "POST"
                "PUT"
                "DELETE"
                "OPTIONS"
              ];
            };
          };
        };
        agentmemory = {
          worker = "path://.";
          working_dir = "/opt/agentmemory";
          start_after = [
            "state"
            "http"
          ];
          restart = "on-failure";
          scripts.run = "node node_modules/@agentmemory/agentmemory/dist/index.mjs";
        };
      };
    }
  );
  observability-config = builtins.toFile "iii-observability.yaml" (
    builtins.toJSON {
      id = "iii-observability";
      name = "Observability";
      description = "";
      schema = { };
      # Replaces the engine's defaults instead of merging with them.
      value = {
        enabled = true;
        service_name = "agentmemory";
        exporter = "memory";
        sampling_ratio = 0.1;
        metrics_enabled = true;
        logs_enabled = true;
        logs_console_output = false;
        trace_storage.enabled = false;
      };
    }
  );
in
{
  options.server.agentmemory = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "0.9.31";
      description = "AgentMemory version; must remain compatible with iii-engine and iii-sdk ${iii-version}.";
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "am" else "agentmemory";
    };
    api-subdomain = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.subdomain}-api";
    };
    env-file = lib.mkOption { type = lib.types.path; };
    provider.env-file = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Server-only encrypted environment file for LLM provider credentials and settings.";
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.agentmemory-env.file = cfg.env-file;
    age.secrets.agentmemory-provider-env = lib.mkIf (cfg.provider.env-file != null) {
      file = cfg.provider.env-file;
    };

    systemd.services.arion-agentmemory = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.tmpfiles.rules = [
      "d ${config-dir} 0750 root root -"
      "d ${config-dir}/data 0750 65532 65532 -"
      "d ${config-dir}/home 0750 65532 65532 -"
      "d ${config-dir}/model-cache 0750 65532 65532 -"
    ];

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; }
      ++ config.lib.server.mkTraefikAlias { subdomain = cfg.api-subdomain; };

    virtualisation.arion.projects.agentmemory.settings = {
      project.name = "agentmemory";
      networks.proxy.external = true;

      services.worker.service = {
        image = "localhost/agentmemory:${image-tag}";
        build.context = "${build-context}";
        container_name = "agentmemory";
        networks = [ "proxy" ];
        stop_grace_period = "30s";
        environment = {
          III_COMPOSE_STATE_DIR = "/data/compose-state";
          III_TELEMETRY_ENABLED = "false";
          III_ENGINE_URL = "ws://127.0.0.1:49134";
          III_REST_PORT = "3111";
          III_VIEWER_PORT = "3113";
          AGENTMEMORY_DATA_DIR = "/data";
          AGENTMEMORY_VIEWER_HOST = "0.0.0.0";
          VIEWER_ALLOWED_HOSTS = viewer-host;
          VIEWER_ALLOWED_ORIGINS = "https://${viewer-host}";
          EMBEDDING_PROVIDER = "local";
          AGENTMEMORY_AUTO_COMPRESS = "true";
          AGENTMEMORY_ALLOW_AGENT_SDK = "false";
          AGENTMEMORY_INJECT_CONTEXT = "true";
        };
        env_file = [
          config.age.secrets.agentmemory-env.path
        ]
        ++ lib.optional (cfg.provider.env-file != null) config.age.secrets.agentmemory-provider-env.path;
        volumes = [
          "${config-dir}/data:/data"
          "${config-dir}/home:/home/agentmemory"
          "${config-dir}/model-cache:/opt/agentmemory/node_modules/@huggingface/transformers/.cache"
          "${worker-compose}:/app/worker-compose.yaml:ro"
          "${observability-config}:/app/iii-observability.yaml:ro"
        ];
        # Re-seed builtin worker settings from the Nix-generated config on every start.
        tmpfs = [ "/app/config:mode=1777" ];
        labels =
          config.lib.server.mkTraefikLabels {
            name = "agentmemory";
            port = "3113";
            subdomain = cfg.subdomain;
          }
          // config.lib.server.mkTraefikLabels {
            name = "agentmemory-api";
            port = "3111";
            subdomain = cfg.api-subdomain;
            rule = "Host(`${api-host}`) && PathPrefix(`/agentmemory/`)";
          }
          // {
            "com.centurylinklabs.watchtower.enable" = "false";
          };
      };
    };
  };
}
