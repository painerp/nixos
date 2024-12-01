{
  lib,
  config,
  ...
}:

let
  cfg = config.modules.waydroid;
in
{
  options.modules.waydroid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf (cfg.enable) {
    virtualisation.waydroid.enable = true;
  };
}
