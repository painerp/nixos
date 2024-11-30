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
    hardware.amdgpu = {
      amdvlk.enable = true;
      initrd.enable = true;
    };
    services.xserver.videoDrivers = [ "amdgpu" ];
  };
}
