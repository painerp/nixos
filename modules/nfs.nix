{ lib, config, ... }:

let
  cfg = config.modules.nfs;
in
{
  options.modules.nfs = {
    server = lib.mkOption {
      type = lib.types.str;
      default = (import ../tailnet.nix).devices.truenas.ip;
    };
    mounts = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "mount point -> dataset path under /mnt/hdd on truenas";
    };
  };

  config.fileSystems = lib.mapAttrs (_: path: {
    device = "${cfg.server}:/mnt/hdd/${path}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  }) cfg.mounts;
}
