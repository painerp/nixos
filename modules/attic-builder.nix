{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.modules.attic-builder;

  build-script = pkgs.writeShellScriptBin "build-and-cache" ''
    set -e

    REPO_PATH="${cfg.repo-path}"
    CACHE_NAME="${cfg.cache-name}"

    # Check if systems specified via command line
    if [ $# -gt 0 ]; then
      MANUAL_SYSTEMS="$@"
      echo "=== Manual mode: building specified systems ==="
      echo "Systems: $MANUAL_SYSTEMS"
    else
      MANUAL_SYSTEMS=""
    fi

    echo "=== Starting build at $(date) ==="
    echo "Repository: $REPO_PATH"
    echo "Cache: $CACHE_NAME"

    cd "$REPO_PATH"

    # Pull latest changes (skip in manual mode with --no-pull flag)
    if [ "$1" != "--no-pull" ] && [ -z "$MANUAL_SYSTEMS" ]; then
      echo "=== Pulling latest changes ==="
      ${pkgs.git}/bin/git pull
    elif [ "$1" = "--no-pull" ]; then
      shift  # Remove --no-pull from arguments
      MANUAL_SYSTEMS="$@"
      echo "=== Skipping git pull (--no-pull flag) ==="
    fi

    # Determine which systems to build
    ${
      if cfg.systems == [ ] then
        ''
          if [ -n "$MANUAL_SYSTEMS" ]; then
            # Use command-line arguments
            SYSTEMS="$MANUAL_SYSTEMS"
          else
            # Auto-detect x86_64-linux systems only (exclude ARM)
            echo "=== Auto-detecting x86_64-linux systems ==="
            SYSTEMS=$(${pkgs.nix}/bin/nix eval --json --impure --expr '
              let
                flake = builtins.getFlake "git+file://${cfg.repo-path}";
                configs = flake.nixosConfigurations;
                isX86 = name:
                  let
                    sys = configs.''${name}.pkgs.system or null;
                  in
                    sys == "x86_64-linux";
              in
                builtins.filter isX86 (builtins.attrNames configs)
            ' | ${pkgs.jq}/bin/jq -r '.[]')

            echo "Found systems: $SYSTEMS"
          fi
        ''
      else if cfg.systems == [ "*" ] then
        ''
          if [ -n "$MANUAL_SYSTEMS" ]; then
            # Use command-line arguments
            SYSTEMS="$MANUAL_SYSTEMS"
          else
            # Build ALL systems (including ARM via emulation - SLOW!)
            echo "=== Building ALL systems (including ARM) ==="
            SYSTEMS=$(${pkgs.nix}/bin/nix eval --json ".#nixosConfigurations" --apply builtins.attrNames | ${pkgs.jq}/bin/jq -r '.[]')
            echo "Found systems: $SYSTEMS"
          fi
        ''
      else
        ''
          if [ -n "$MANUAL_SYSTEMS" ]; then
            # Use command-line arguments
            SYSTEMS="$MANUAL_SYSTEMS"
          else
            # Use specified systems
            echo "=== Building specified systems ==="
            SYSTEMS="${lib.concatStringsSep " " cfg.systems}"
            echo "Systems: $SYSTEMS"
          fi
        ''
    }

    # Build all systems and track which ones succeeded
    echo ""
    echo "=== Building systems with nix-fast-build ==="

    # Track successful builds
    SUCCESSFUL_BUILDS=()

    for system in $SYSTEMS; do
      echo ""
      echo ">>> Building $system..."

      if ${pkgs.nix-fast-build}/bin/nix-fast-build \
        --skip-cached \
        --no-nom \
        --eval-max-memory-size ${toString cfg.max-memory-per-worker} \
        --eval-workers ${toString cfg.workers} \
        --flake ".#nixosConfigurations.$system.config.system.build.toplevel"; then

        echo "✓ Build completed for $system"
        SUCCESSFUL_BUILDS+=("$system")
      else
        echo "✗ Build failed for $system, skipping push"
      fi
    done

    # Push only successful builds to Attic cache
    echo ""
    echo "=== Pushing to Attic cache ==="
    PUSHED=0
    FAILED=0

    for system in "''${SUCCESSFUL_BUILDS[@]}"; do
      echo ""
      echo ">>> Pushing $system..."

      RESULT=$(${pkgs.nix}/bin/nix build \
        --no-link \
        --print-out-paths \
        ".#nixosConfigurations.$system.config.system.build.toplevel" \
        2>/dev/null || true)

      if [ -n "$RESULT" ]; then
        echo "Result: $RESULT"

        # Retry logic: Try up to 5 times with exponential backoff
        RETRY_COUNT=0
        MAX_RETRIES=${toString cfg.max-retries}
        SUCCESS=false
        BACKOFF=5

        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
          if [ $RETRY_COUNT -gt 0 ]; then
            echo "  Retry attempt $RETRY_COUNT/$MAX_RETRIES (waiting ''${BACKOFF}s)..."
            sleep $BACKOFF
            BACKOFF=$((BACKOFF * 2))
          fi

          if ${pkgs.attic-client}/bin/attic push "$CACHE_NAME" "$RESULT"; then
            echo "✓ Successfully pushed $system"
            PUSHED=$((PUSHED + 1))
            SUCCESS=true
            break
          else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
              echo "  Push failed, will retry..."
            fi
          fi
        done

        if [ "$SUCCESS" = false ]; then
          echo "✗ Failed to push $system after $MAX_RETRIES attempts"
          FAILED=$((FAILED + 1))
        fi
      else
        echo "✗ No result found for $system"
        FAILED=$((FAILED + 1))
      fi

      # Brief pause between pushes
      sleep 2
    done

    # Calculate total failed (builds that never made it to push attempts)
    TOTAL_SYSTEMS=$(echo "$SYSTEMS" | wc -w)
    TOTAL_FAILED=$((TOTAL_SYSTEMS - ''${#SUCCESSFUL_BUILDS[@]}))

    # Summary
    echo ""
    echo "=== Build Summary ==="
    echo "Completed at: $(date)"
    echo "Total systems: $TOTAL_SYSTEMS"
    echo "Successful builds: ''${#SUCCESSFUL_BUILDS[@]}"
    echo "Failed builds: $TOTAL_FAILED"
    echo "Successfully pushed: $PUSHED"
    echo "Failed to push: $FAILED"
    echo "=== Disk Usage ==="
    ${pkgs.coreutils}/bin/df -h / /nix
    echo ""
    echo "=== Memory Usage ==="
    ${pkgs.procps}/bin/free -h
    echo ""
    echo "=== Nix Store Size ==="
    ${pkgs.gdu}/bin/gdu -snp /nix/store 2>/dev/null || echo "Could not calculate store size"

    # Exit with error if there were any failures
    if [ $TOTAL_FAILED -gt 0 ] || [ $FAILED -gt 0 ]; then
      echo ""
      echo "=== Build/push failures detected ==="
      exit 1
    fi
  '';
in
{
  options.modules.attic-builder = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automated building and caching to Attic";
    };
    repo-path = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Path to the NixOS repository";
    };
    cache-name = lib.mkOption {
      type = lib.types.str;
      default = "ci:nixos";
      description = "Attic cache name in format 'remote:cache'";
    };
    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "cit"
        "inf"
        "gra"
        "gam"
        "arr"
        "run"
        "log"
      ];
      description = ''
        List of system names to build.

        - Empty list ([]): Auto-builds all x86_64-linux systems (recommended)
        - ["*"]: Builds ALL systems including ARM (slow, uses emulation)
        - Specific list: Builds only those systems

        Note: Can be overridden by command-line arguments when running manually.
      '';
    };
    max-memory-per-worker = lib.mkOption {
      type = lib.types.int;
      default = 4092;
      description = "Maximum memory in MB per nix-eval-jobs worker";
    };
    workers = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Number of parallel evaluation workers";
    };
    max-retries = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Number of retry attempts for pushing to Attic cache on failure";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "When to run the build (systemd timer OnCalendar format)";
    };
    timer-enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic scheduled builds";
    };
    gc-after-build = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run garbage collection after successful build";
    };
    gc-older-than = lib.mkOption {
      type = lib.types.str;
      default = "3d";
      description = "Delete generations older than this after build (e.g., '3d', '7d', '1w')";
    };
    enable-email-notifications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Send email notifications on build failures";
    };
    env-file = lib.mkOption {
      type = lib.types.path;
      default = secrets.extras-smtp;
      description = "Path to the SMTP configuration file for email notifications";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure SMTP secret for email notifications
    age.secrets.smtp = lib.mkIf cfg.enable-email-notifications {
      file = cfg.env-file;
    };

    # Ensure required packages are available
    environment.systemPackages = [
      pkgs.attic-client
      pkgs.git
      pkgs.nix-fast-build
      pkgs.jq
      pkgs.gdu
      build-script
    ];

    # Nix settings optimized for building
    nix.settings = {
      # Resource limits (already set in system.nix, but ensure they exist)
      max-jobs = lib.mkDefault 4;
      cores = lib.mkDefault 2;

      # Aggressive disk management
      min-free = lib.mkDefault 21474836480; # 20GB - triggers GC
      max-free = lib.mkDefault 107374182400; # 100GB - aggressive cleanup

      # Use substituters during build
      builders-use-substitutes = true;
    };

    # Systemd service for building
    systemd.services.attic-builder = {
      description = "Build and cache NixOS configurations to Attic";

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = cfg.repo-path;

        # Resource limits
        Nice = 10; # Lower priority
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
      };

      path = [
        pkgs.git
        pkgs.nix
        pkgs.attic-client
        pkgs.nix-fast-build
        pkgs.jq
        pkgs.coreutils
        pkgs.procps
        pkgs.gdu
        pkgs.msmtp
        pkgs.hostname
        build-script
      ];

      script = ''
        # Setup logging
        mkdir -p $HOME/attic-builds
        TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
        LOG_FILE="$HOME/attic-builds/$TIMESTAMP.log"

        # Function to send email on failure
        send_failure_email() {
          ${lib.optionalString cfg.enable-email-notifications ''
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

            echo -e "To: $EMAIL_TO\nSubject: [NixOS] Attic builder failed on $(hostname)" | cat - "$LOG_FILE" | msmtp -t \
              --from="$EMAIL_FROM" \
              --host="$SMTP_SERVER" \
              --port="$SMTP_PORT" \
              --auth=on \
              --user="$SMTP_USERNAME" \
              --passwordeval="echo $SMTP_PASSWORD" \
              --tls=on \
              --tls-starttls=on
          ''}
        }

        # Run the build script and capture output
        if ${build-script}/bin/build-and-cache 2>&1 | tee "$LOG_FILE"; then
          echo "Build completed successfully"
        else
          EXIT_CODE=$?
          echo "Build failed with exit code $EXIT_CODE"
          send_failure_email
          exit $EXIT_CODE
        fi
      '';

      # Garbage collection after build
      postStop = lib.mkIf cfg.gc-after-build ''
        echo "=== Running garbage collection ==="
        ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than ${cfg.gc-older-than}
        ${pkgs.nix}/bin/nix-store --gc
        echo "=== Garbage collection complete ==="
        echo "Disk usage after GC:"
        ${pkgs.coreutils}/bin/df -h /nix
      '';
    };

    # Systemd timer for scheduled builds
    systemd.timers.attic-builder = lib.mkIf cfg.timer-enable {
      description = "Timer for building and caching NixOS configurations";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true; # Run missed builds
        RandomizedDelaySec = "15m"; # Spread load
      };
    };
  };
}
