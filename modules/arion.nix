{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.arion;
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
  };

  imports = [
    inputs.arion.nixosModules.arion
    ../containers
  ];

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.arion ];

    virtualisation = {
      docker = {
        enable = true;
        liveRestore = false;
        autoPrune = {
          enable = true;
          dates = "01:00";
        };
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
      arion = {
        backend = "docker";
      };
    };
  };
}
