{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.toggle-refresh;
in
{
  options.cpkgs.toggle-refresh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "toggle-refresh" ''
        MONITORS=$(hyprctl monitors -j)

        if [ "$(echo "$MONITORS" | ${pkgs.jq} length)" -gt 1 ]; then
          echo "Only one monitor is supported"
          exit 1
        fi

        MONITOR=$(echo "$MONITORS" | ${pkgs.jq} -r .[0].name)
        CURRENT_RATE=$(echo "$MONITORS" | ${pkgs.jq} -r .[0].refreshRate)

        LOW_RATE="60"
        HIGH_RATE="$(echo "$MONITORS" | ${pkgs.jq} -r .[0].availableModes.[0] | sed 's/.*@\(.*\)Hz/\1/')"

        if [[ $(printf "%.0f" "$CURRENT_RATE") -eq "$LOW_RATE" ]]; then
          hyprctl keyword monitor "$MONITOR",1920x1080@"$HIGH_RATE",auto,1
          echo "Setting refresh rate to: $HIGH_RATE"
        else
          hyprctl keyword monitor "$MONITOR",1920x1080@"$LOW_RATE",auto,1
          echo "Setting refresh rate to: $LOW_RATE"
        fi
      '')
    ];
  };
}
