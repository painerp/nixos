{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.arion;
  autoPrune = {
    enable = true;
    dates = "01:00";
  };
in
{
  options.modules.arion = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    rewrite-bip = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "changes the default bridge network ips";
    };
    backend = lib.mkOption {
      type = lib.types.enum [
        "docker"
        "podman"
      ];
      default = "docker";
      description = "Container backend to use for arion";
    };
    tailscale-dependent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to make arion dependent on tailscale. This will cause arion to start after tailscale and stop when tailscale stops.";
    };
  };

  imports = [
    inputs.arion.nixosModules.arion
    ../containers
  ];

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      pkgs.arion
    ]
    ++ lib.optionals (cfg.backend == "podman") [
      pkgs.docker-client
    ];

    virtualisation = {
      docker = {
        enable = cfg.backend == "docker";
        liveRestore = false;
        inherit autoPrune;
        daemon.settings = lib.mkIf (cfg.rewrite-bip) {
          bip = "172.30.0.1/24";
          default-address-pools = [
            {
              base = "172.31.0.0/16";
              size = 24;
            }
            {
              base = "172.32.0.0/16";
              size = 24;
            }
          ];
        };
      };
      podman = {
        enable = cfg.backend == "podman";
        dockerSocket.enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enable = true;
        inherit autoPrune;
      };
      arion = {
        backend = if cfg.backend == "docker" then "docker" else "podman-socket";
      };
    };

    systemd = lib.mkIf (cfg.tailscale-dependent) {
      services = {
        docker = lib.attrsets.optionalAttrs (cfg.backend == "docker") {
          after = [ "tailscaled.service" ];
          requires = [ "tailscaled.service" ];
        };

        podman = lib.attrsets.optionalAttrs (cfg.backend == "podman") {
          after = [ "tailscaled.service" ];
          requires = [ "tailscaled.service" ];
        };
      };
      sockets.podman = lib.attrsets.optionalAttrs (cfg.backend == "podman") {
        after = [ "tailscaled.service" ];
        requires = [ "tailscaled.service" ];
      };
    };

    users.users."${config.system.username}".extraGroups = [ "${cfg.backend}" ];
  };
}
