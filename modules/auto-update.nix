{ inputs, lib, config, ... }:

{
  options.system.flake = lib.mkOption {
    description = "The flake to use for system configuration";
    type = lib.types.str;
  };

  config = {
    system.autoUpgrade = {
      enable = true;
      flake = "${inputs.self.outPath}#${config.system.flake}";
      flags = [
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "04:00";
      randomizedDelaySec = "45min";
    };
  };
}
