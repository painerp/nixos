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
      type = lib.types.attr;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  config = {
    services.xserver.videoDrivers = [ "nvidia" ];

    virtualisation.docker.enableNvidia = true;

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = false;
      package = cfg.package;
    };
  };
}
