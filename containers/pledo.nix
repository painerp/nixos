{ lib, config, ... }:

let cfg = config.server.pledo;
in {
  options.server.pledo = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = if config.server.short-subdomain then "pl" else "pledo";
    };
    auth = lib.mkOption {
      type = lib.types.bool;
      default = config.server.authentik.enable;
    };
    volumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf (config.modules.arion.enable && cfg.enable) {
    server.traefik.aliases =
      config.lib.server.mkTraefikAlias { subdomain = cfg.subdomain; };

    virtualisation.arion.projects.gluetun.settings = {
      services.gluetun.service.labels = config.lib.server.mkTraefikLabels {
        name = "pledo";
        port = "80";
        subdomain = "${cfg.subdomain}";
        forwardAuth = cfg.auth;
      };

      services.pledo.service = {
        image = "ghcr.io/fxsth/pledo:latest";
        container_name = "pledo";
        network_mode = "service:gluetun";
        depends_on = [ "gluetun" ];
        volumes = [ "${config.lib.server.mkConfigDir "pledo"}:/config" ]
          ++ cfg.volumes;
        labels = { "com.centurylinklabs.watchtower.enable" = "true"; };
        restart = "unless-stopped";
      };
    };
  };
}
