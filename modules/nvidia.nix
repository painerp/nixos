{ config, pkgs, lib, ... }:

let
  cfg = config.modules.nvidia;
in
{
  options.modules.nvidia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    package = lib.mkOption {
      type = lib.types.attrs;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    patch = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        open = false;
        nvidiaSettings = false;
        package = if cfg.patch then
          pkgs.nvidia-patch.patch-nvenc
          (pkgs.nvidia-patch.patch-fbc cfg.package)
        else
          cfg.package;
      };

      nvidia-container-toolkit.enable = config.modules.arion.enable;
    };
  };
}
