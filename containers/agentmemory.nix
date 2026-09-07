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
  dockerfile = lib.replaceStrings [ "@agentmemory-version@" ] [ cfg.version ] (
    builtins.readFile ./agentmemory/Dockerfile
  );
  build-context = pkgs.writeTextDir "Dockerfile" dockerfile;
  image-tag = "${cfg.version}-${builtins.substring 0 12 (builtins.hashString "sha256" dockerfile)}";
  engine-config = builtins.toFile "agentmemory-iii-config.yaml" (
    builtins.toJSON {
      workers = [
        {
          name = "iii-http";
          config = {
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
        }
        {
          name = "iii-worker-manager";
          config = {
            port = 49134;
            host = "127.0.0.1";
          };
        }
        {
          name = "iii-state";
          config.adapter = {
            name = "kv";
            config = {
              store_method = "file_based";
              file_path = "/data/state_store.db";
            };
          };
        }
        {
          name = "iii-queue";
          config.adapter.name = "builtin";
        }
        {
          name = "iii-pubsub";
          config.adapter.name = "local";
        }
        {
          name = "iii-cron";
          config.adapter.name = "kv";
        }
        {
          name = "iii-stream";
          config = {
            port = 3112;
            host = "127.0.0.1";
            adapter = {
              name = "kv";
              config = {
                store_method = "file_based";
                file_path = "/data/stream_store";
              };
            };
          };
        }
        {
          name = "iii-observability";
          config = {
            enabled = true;
            service_name = "agentmemory";
            exporter = "memory";
            sampling_ratio = 0.1;
            metrics_enabled = true;
            logs_enabled = true;
            logs_console_output = false;
          };
        }
      ];
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
      default = "0.9.29";
      description = "AgentMemory version; must remain compatible with iii-engine and iii-sdk 0.11.2.";
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
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    age.secrets.agentmemory-env.file = cfg.env-file;

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

      services = {
        engine.service = {
          # Coupled to the worker SDK; do not update independently.
          image = "docker.io/iiidev/iii:0.11.2";
          container_name = "agentmemory-engine";
          user = "65532:65532";
          networks = [ "proxy" ];
          volumes = [
            "${config-dir}/data:/data"
            "${engine-config}:/app/config.yaml:ro"
          ];
          # Both listeners live in this container's network namespace.
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
          restart = "unless-stopped";
        };

        worker.service = {
          image = "localhost/agentmemory:${image-tag}";
          build.context = "${build-context}";
          container_name = "agentmemory";
          network_mode = "service:engine";
          depends_on = [ "engine" ];
          environment = {
            III_ENGINE_URL = "ws://127.0.0.1:49134";
            III_REST_PORT = "3111";
            III_STREAM_PORT = "3112";
            III_VIEWER_PORT = "3113";
            AGENTMEMORY_DATA_DIR = "/data";
            AGENTMEMORY_VIEWER_HOST = "0.0.0.0";
            VIEWER_ALLOWED_HOSTS = viewer-host;
            VIEWER_ALLOWED_ORIGINS = "https://${viewer-host}";
            EMBEDDING_PROVIDER = "local";
            AGENTMEMORY_AUTO_COMPRESS = "false";
            AGENTMEMORY_ALLOW_AGENT_SDK = "false";
            CONSOLIDATION_ENABLED = "false";
          };
          env_file = [ config.age.secrets.agentmemory-env.path ];
          volumes = [
            "${config-dir}/data:/data"
            "${config-dir}/home:/home/agentmemory"
            "${config-dir}/model-cache:/opt/agentmemory/node_modules/@huggingface/transformers/.cache"
          ];
          labels = {
            "com.centurylinklabs.watchtower.enable" = "false";
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
