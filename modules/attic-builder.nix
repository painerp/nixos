{
  config,
  lib,
  pkgs,
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

    # Build all systems
    echo ""
    echo "=== Building systems with nix-fast-build ==="
    for system in $SYSTEMS; do
      echo ""
      echo ">>> Building $system..."
      ${pkgs.nix-fast-build}/bin/nix-fast-build \
        --skip-cached \
        --no-nom \
        --flake ".#nixosConfigurations.$system.config.system.build.toplevel" || {
          echo "Warning: Failed to build $system, continuing..."
        }
    done

    # Push all results to Attic cache
    echo ""
    echo "=== Pushing to Attic cache ==="
    PUSHED=0
    FAILED=0

    for system in $SYSTEMS; do
      echo ""
      echo ">>> Checking $system..."
      RESULT=$(${pkgs.nix}/bin/nix build \
        --no-link \
        --print-out-paths \
        ".#nixosConfigurations.$system.config.system.build.toplevel" \
        2>/dev/null || true)

      if [ -n "$RESULT" ]; then
        echo "Pushing $system ($RESULT)..."
        if ${pkgs.attic-client}/bin/attic push "$CACHE_NAME" "$RESULT"; then
          echo "✓ Successfully pushed $system"
          PUSHED=$((PUSHED + 1))
        else
          echo "✗ Failed to push $system"
          FAILED=$((FAILED + 1))
        fi
      else
        echo "✗ No result for $system (build may have failed)"
        FAILED=$((FAILED + 1))
      fi
    done

    # Summary
    echo ""
    echo "=== Build Summary ==="
    echo "Completed at: $(date)"
    echo "Successfully pushed: $PUSHED systems"
    echo "Failed: $FAILED systems"
    echo ""
    echo "=== Disk Usage ==="
    ${pkgs.coreutils}/bin/df -h / /nix
    echo ""
    echo "=== Memory Usage ==="
    ${pkgs.procps}/bin/free -h
    echo ""
    echo "=== Nix Store Size ==="
    ${pkgs.gdu}/bin/gdu -n /nix/store 2>/dev/null || echo "Could not calculate store size"
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
  };

  config = lib.mkIf cfg.enable {
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
        build-script
      ];

      script = "${build-script}/bin/build-and-cache";

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
