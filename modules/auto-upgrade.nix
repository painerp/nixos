{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.autoUpgrade;
in
{
  options.modules.autoUpgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    reboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If necessary reboot the system after upgrade";
    };
    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
      description = "Time to run the upgrade";
    };
    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "60min";
      description = "Randomized delay before running the upgrade";
    };
    persistent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If true, the timer will be persistent. It will start immediately if it would have been missed otherwise.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    systemd.services.nixos-upgrade = {
      description = "NixOS Upgrade";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";

      environment =
        config.nix.envVars
        // {
          inherit (config.environment.sessionVariables) NIX_PATH;
          HOME = "/root";
        }
        // config.networking.proxy.envVars;

      path = with pkgs; [
        coreutils
        gnutar
        xz.bin
        gzip
        git
        config.nix.package.out
        config.programs.ssh.package
      ];

      script =
        let
          nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
          git = "${pkgs.git}/bin/git";
        in
        ''
          cd /etc/nixos
          if ! ${git} pull | grep -q 'Already up to date.'; then
            ${nixos-rebuild} switch --flake "/etc/nixos#${config.system.flake}" --no-write-lock-file -L
          fi
        '';

      startAt = cfg.dates;

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.timers.nixos-upgrade = {
      timerConfig = {
        RandomizedDelaySec = cfg.randomizedDelaySec;
        FixedRandomDelay = true;
        Persistent = cfg.persistent;
      };
    };
  };
}
