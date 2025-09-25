{
  lib,
  config,
  ...
}:

let
  cfg = config.modules.borg;
  common-excludes = [
    ".cache"
    ".local/share/Trash"
    "manual"
  ];
in
{
  options.modules.borg = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of paths to exclude from backup";
    };
  };

  config = lib.mkIf cfg.enable {
    services.borgbackup.jobs.root = rec {
      paths = "/root";
      repo = "/mnt/backup";
      exclude = map (x: paths + "/" + x) cfg.exclude ++ map (x: paths + "/" + x) common-excludes;
      encryption.mode = "none";
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 12;
        yearly = 3;
      };
    };
  };
}
