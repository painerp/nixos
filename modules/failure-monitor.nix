{
  lib,
  config,
  secrets,
  pkgs,
  ...
}:

let
  cfg = config.modules.failure-monitor;
  containersEnabled = config.modules.arion.enable;
in
{
  options.modules.failure-monitor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    interval = lib.mkOption {
      type = lib.types.str;
      default = "*:0/15";
      description = "OnCalendar expression for how often to check for failures";
    };
    excludeUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional units to ignore. The monitor always ignores itself, nixos-upgrade.service and attic-builder.service.";
    };
    excludeContainers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Container names to ignore";
    };
    emailCooldown = lib.mkOption {
      type = lib.types.int;
      default = 1440;
      description = "Minimum minutes between emails mentioning the same item";
    };
    env-file = lib.mkOption {
      type = lib.types.path;
      default = secrets.extras-smtp;
    };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.smtp.file = cfg.env-file;

    systemd.services.failure-monitor = {
      description = "Failed unit and unhealthy container monitor";

      restartIfChanged = false;

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "failure-monitor";
        TimeoutStartSec = "10min";
      };

      path =
        with pkgs;
        [
          coreutils
          findutils
          gawk
          hostname
          msmtp
          systemd
        ]
        ++ lib.optionals containersEnabled [ docker-client ];

      script = ''
        set -uo pipefail

        STATE="$STATE_DIRECTORY"
        mkdir -p "$STATE/seen/units" "$STATE/seen/containers" \
                 "$STATE/mailed/units" "$STATE/mailed/containers" "$STATE/stopped"

        # prune mail markers older than the cooldown so items can alert again
        find "$STATE/mailed" -type f -mmin +${toString cfg.emailCooldown} -delete

        NEVER_TOUCH="failure-monitor.service nixos-upgrade.service attic-builder.service ${lib.concatStringsSep " " cfg.excludeUnits}"
        EXCLUDED_CONTAINERS="${lib.concatStringsSep " " cfg.excludeContainers}"

        contains() {
          local needle="$1" x
          shift
          for x in "$@"; do
            [ "$x" = "$needle" ] && return 0
          done
          return 1
        }

        confirmed=()

        # queue a confirmed-broken item for the email batch unless in cooldown
        confirm() {
          if [ ! -e "$STATE/mailed/$1" ]; then
            confirmed+=("$1")
          fi
        }

        send_failure_email() {
          if [ -f ${config.age.secrets.smtp.path} ]; then
            source ${config.age.secrets.smtp.path}
          else
            echo "Error: SMTP configuration file not found at ${config.age.secrets.smtp.path}"
            return 1
          fi

          if [ -z "''${EMAIL_TO:-}" ] || [ -z "''${EMAIL_FROM:-}" ] || [ -z "''${SMTP_SERVER:-}" ] || \
             [ -z "''${SMTP_PORT:-}" ] || [ -z "''${SMTP_USERNAME:-}" ] || [ -z "''${SMTP_PASSWORD:-}" ]; then
            echo "Error: Missing required SMTP configuration variables"
            return 1
          fi

          echo -e "To: $EMAIL_TO\nSubject: [NixOS] $2 failing service(s) on $(hostname)\n" | cat - "$1" | msmtp -t \
            --from="$EMAIL_FROM" \
            --host="$SMTP_SERVER" \
            --port="$SMTP_PORT" \
            --auth=on \
            --user="$SMTP_USERNAME" \
            --passwordeval="echo $SMTP_PASSWORD" \
            --tls=on \
            --tls-starttls=on
        }

        ### failed systemd units ###

        failed_units=$(systemctl --failed --plain --no-legend | awk '{print $1}')
        activating_units=$(systemctl list-units --state=activating --plain --no-legend | awk '{print $1}')

        # recovery: drop markers for units that are no longer failed
        # (a unit we restarted may still be mid-run/activating - that is not recovery)
        for marker in "$STATE/seen/units"/*; do
          [ -e "$marker" ] || continue
          contains "$(basename "$marker")" $failed_units $activating_units || rm -f "$marker"
        done

        for unit in $failed_units; do
          contains "$unit" $NEVER_TOUCH && continue
          if [ -e "$STATE/seen/units/$unit" ]; then
            confirm "units/$unit"
          else
            touch "$STATE/seen/units/$unit"
          fi
          # clears start-limit-hit and purges not-found ghost units
          systemctl reset-failed "$unit" 2>/dev/null || true
          if [ "$(systemctl show -p LoadState --value "$unit")" = "loaded" ]; then
            systemctl restart --no-block "$unit" || echo "WARNING: could not restart $unit"
          fi
        done

        ${lib.optionalString containersEnabled ''
          ### unhealthy containers ###

          docker_ok=true
          if ! unhealthy=$(docker ps --filter health=unhealthy --format "{{.Names}}" 2>/dev/null); then
            echo "WARNING: container runtime unreachable, skipping container checks"
            docker_ok=false
            unhealthy=""
          fi

          if $docker_ok; then
            starting=$(docker ps --filter health=starting --format "{{.Names}}" 2>/dev/null) || starting=""
            # crash-looping containers never turn "unhealthy", docker just keeps restarting them
            # ponytail: only sees the restarting state, track RestartCount deltas if slow crash loops slip through
            restarting=$(docker ps --filter status=restarting --format "{{.Names}}" 2>/dev/null) || restarting=""

            # containers we stopped for crash-looping alert again (once per mail cooldown) while they stay down
            for marker in "$STATE/stopped"/*; do
              [ -e "$marker" ] || continue
              c=$(basename "$marker")
              if [ "$(docker inspect --format "{{.State.Status}}" "$c" 2>/dev/null)" = "exited" ]; then
                confirm "containers/$c"
              else
                # started again, recreated or removed: mail right away if it breaks again
                rm -f "$marker" "$STATE/mailed/containers/$c"
              fi
            done

            # recovery: a container in "starting" or stopped by us is not recovered, keep its marker
            for marker in "$STATE/seen/containers"/*; do
              [ -e "$marker" ] || continue
              c=$(basename "$marker")
              contains "$c" $unhealthy $starting $restarting || [ -e "$STATE/stopped/$c" ] || rm -f "$marker"
            done

            for c in $unhealthy $restarting; do
              contains "$c" $EXCLUDED_CONTAINERS && continue
              if [ -e "$STATE/seen/containers/$c" ]; then
                confirm "containers/$c"
                # stop crash loops instead of letting them spam the logs
                if contains "$c" $restarting; then
                  docker stop "$c" >/dev/null && touch "$STATE/stopped/$c" || echo "WARNING: could not stop container $c"
                fi
              else
                touch "$STATE/seen/containers/$c"
              fi
              # docker is already restarting it
              contains "$c" $restarting && continue
              docker restart "$c" >/dev/null || echo "WARNING: could not restart container $c"
            done
          fi
        ''}

        ### bundled email ###

        if [ ''${#confirmed[@]} -gt 0 ]; then
          body=$(mktemp)
          trap 'rm -f "$body"' EXIT
          for key in "''${confirmed[@]}"; do
            name=''${key#*/}
            {
              echo "=== $key ==="
              echo "failing since: $(date -r "$STATE/seen/$key" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo unknown)"
              case "$key" in
                units/*)
                  journalctl -u "$name" -n 15 --no-pager 2>&1 || true
                  ;;
                containers/*)
                  [ -e "$STATE/stopped/$name" ] && echo "crash-looping, stopped by failure-monitor - start it again once fixed"
                  docker inspect --format "{{range .State.Health.Log}}{{.End}} exit={{.ExitCode}} {{.Output}}{{end}}" "$name" 2>&1 | tail -5 || true
                  docker logs --tail 15 "$name" 2>&1 || true
                  ;;
              esac
              echo
            } >> "$body"
          done

          if send_failure_email "$body" "''${#confirmed[@]}"; then
            for key in "''${confirmed[@]}"; do
              touch "$STATE/mailed/$key"
            done
          else
            echo "WARNING: sending email failed, will retry next run"
          fi
        fi
      '';

      startAt = cfg.interval;

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.timers.failure-monitor = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "2min";
        FixedRandomDelay = true;
      };
    };
  };
}
