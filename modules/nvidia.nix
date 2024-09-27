{ config, lib, ... }:

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
  };

  config = {
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
        package = cfg.package;
      };

      nvidia-container-toolkit.enable = config.modules.arion.enable;
    };
  };
}
