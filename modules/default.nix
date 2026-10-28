{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.system = {
    flake = lib.mkOption {
      description = "The flake to use for system configuration";
      type = lib.types.str;
    };
    username = lib.mkOption {
      description = "The main username of the system";
      type = lib.types.str;
      default = "root";
    };
    home-manager = lib.mkOption {
      description = "Whether home-manager is enabled";
      type = lib.types.bool;
      default = false;
    };
    language = lib.mkOption {
      description = "The default language of the system";
      type = lib.types.str;
      default = "en_US.UTF-8";
    };
    latest-kernel = lib.mkOption {
      description = "Whether the latest kernel should be used";
      type = lib.types.bool;
      default = false;
    };
    github-trusted = lib.mkOption {
      description = "Whether to rewrite ssh config to trust github.com";
      type = lib.types.bool;
      default = true;
    };
  };

  imports = map (n: ./${n}) (
    lib.attrNames (
      lib.filterAttrs (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n) (
        builtins.readDir ./.
      )
    )
  );

  config = {
    boot.kernelPackages = lib.mkIf (config.system.latest-kernel) (
      lib.mkDefault pkgs.linuxPackages_latest
    );
  };
}
