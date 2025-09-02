{
  lib,
  config,
  secrets,
  pkgs,
  ...
}:

let
  cfg = config.modules.auto-upgrade;
in
{
  options.modules.auto-upgrade = {
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
    env-file = lib.mkOption {
      type = lib.types.path;
      default = secrets.extras-smtp;
    };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.smtp.file = cfg.env-file;
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
        mailutils
        msmtp
        config.nix.package.out
        config.programs.ssh.package
      ];

      script =
        let
          nixos-rebuild = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
          git = "${pkgs.git}/bin/git";
        in
        ''
          # Function to send email on failure
          send_failure_email() {
            if [ -f ${config.age.secrets.smtp.path} ]; then
              source ${config.age.secrets.smtp.path}
            else
              echo "Error: SMTP configuration file not found at ${config.age.secrets.smtp.path}"
              return 1
            fi

            if [ -z "$EMAIL_TO" ] || [ -z "$EMAIL_FROM" ] || [ -z "$SMTP_SERVER" ] || \
               [ -z "$SMTP_PORT" ] || [ -z "$SMTP_USERNAME" ] || [ -z "$SMTP_PASSWORD" ]; then
              echo "Error: Missing required SMTP configuration variables"
              return 1
            fi

            echo "Subject: [NixOS] Auto-upgrade failed on $(hostname)" | cat - "$1" | msmtp \
              -t "$EMAIL_TO" \
              --from="$EMAIL_FROM" \
              --host="$SMTP_SERVER" \
              --port="$SMTP_PORT" \
              --auth=on \
              --user="$SMTP_USERNAME" \
              --password="$SMTP_PASSWORD" \
              --tls=on \
              --tls-starttls=on
          }

          cd /etc/nixos
          if ! ${git} pull | grep -q 'Already up to date.'; then
            echo "Updates found, rebuilding system..."
            mkdir -p $HOME/auto-update

            TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
            LOG_FILE="$HOME/auto-update/$TIMESTAMP.log"

            {
              echo "=== NixOS auto-upgrade started at $(date) ==="
              echo "Working directory: $(pwd)"

              if ! ${nixos-rebuild} switch --flake "/etc/nixos#${config.system.flake}" --no-write-lock-file -L; then
                echo "=== NixOS auto-upgrade FAILED at $(date) ==="
                send_failure_email "$LOG_FILE"
                exit 1
              fi

              echo "=== NixOS auto-upgrade completed at $(date) ==="

              ${lib.optionalString cfg.reboot ''
                if [ -f /run/reboot-required ]; then
                  echo "Rebooting..."
                  systemctl reboot
                fi
              ''}
            } 2>&1 | tee "$LOG_FILE"

            if [ $? -ne 0 ]; then
              send_failure_email "$LOG_FILE"
              exit 1
            fi
          else
            echo "No updates found. Nothing to do."
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
