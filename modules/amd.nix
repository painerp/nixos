{ config, lib, ... }:

let
  cfg = config.modules.amd;
in
{
  options.modules.amd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];
  };
}
