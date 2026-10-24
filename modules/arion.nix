{
  lib,
  inputs,
  config,
  secrets,
  pkgs,
  ...
}:

let
  cfg = config.modules.arion;
  autoPrune = {
    enable = true;
    dates = "05:00";
    flags = [
      "--all"
      "--filter"
      "until=24h"
    ];
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
    registry-login = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install /root/.docker/config.json from agenix, the login for images from the own registry (git.local.n0g.cc)";
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

    systemd = lib.mkMerge [
      (lib.mkIf (cfg.tailscale-dependent) {
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
      })
      # podman.service is socket-activated, so on change switch-to-configuration restarts podman.socket,
      # recreating podman.sock and leaving every container's docker.sock bind mount pointing at a dead inode
      (lib.mkIf (cfg.backend == "podman") { services.podman.stopIfChanged = false; })
      # upstream's unit runs plain `arion up`, which leaves containers of services removed from a project running
      {
        services = lib.mapAttrs' (
          _: project:
          lib.nameValuePair project.serviceName {
            script = lib.mkForce ''
              echo 1>&2 "docker compose file: $ARION_PREBUILT"
              arion --prebuilt-file "$ARION_PREBUILT" up --remove-orphans
            '';
          }
        ) config.virtualisation.arion.projects;
      }
    ];

    # tailscaled signals ready before tailscale0 has its IP, so ordering alone can't stop
    # "<tailscale-ip>:port" binds failing at boot (docker 29 then drops the container's networks)
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = lib.mkIf cfg.tailscale-dependent 1;

    age.secrets.docker-config = lib.mkIf cfg.registry-login {
      file = secrets.extras-docker-config;
      path = "/root/.docker/config.json";
    };

    users.users."${config.system.username}".extraGroups = [ "${cfg.backend}" ];
  };
}
