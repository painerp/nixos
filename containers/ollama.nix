{ lib, config, ... }:

let cfg = config.server.ollama;
in {
  options.server.ollama = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "ol" else "ollama";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    systemd.services.arion-ollama = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.ollama.settings = {
      project.name = "ollama";
      networks.proxy.external = true;

      services.ollama = {
        out.service = {
          deploy.resources.reservations.devices = [{
            driver = "nvidia";
            count = 1;
            capabilities = [ "gpu" ];
          }];
        };
        service = {
          image = "ollama/ollama:latest";
          container_name = "ollama";
          hostname = config.networking.hostName;
          networks = [ "proxy" ];
          environment = { OLLAMA_ORIGINS = "*"; };
          volumes =
            [ "${config.lib.server.mkConfigDir "ollama"}:/root/.ollama" ];
          labels = config.lib.server.mkTraefikLabels {
            name = "ollama";
            port = "11434";
            subdomain = "${cfg.subdomain}";
            forwardAuth = cfg.auth;
          } // {
            "com.centurylinklabs.watchtower.enable" = "true";
          };
          restart = "unless-stopped";
        };
      };
    };
  };
}
