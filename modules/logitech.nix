{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.logitech;
in
{
  options.modules.logitech = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ solaar ];
    hardware.logitech.wireless.enable = true;
  };
}
