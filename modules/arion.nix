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
        backend = cfg.backend;
      };
    };

    users.users."${config.system.username}".extraGroups = [ "${cfg.backend}" ];
  };
}
