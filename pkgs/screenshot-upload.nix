{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.screenshot-upload;
in
{
  options.cpkgs.screenshot-upload = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    cpkgs.upload-file.enable = true;
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "screenshot-upload" ''
        set -euo pipefail

        _now=$(date +"%H_%M_%S-%d_%m_%Y")
        folder="$HOME/Pictures/Screenshot/"
        file="$folder$_now.png"

        if [ ! -d "$folder" ]; then
          mkdir -p "$folder"
        fi

        # check if grimblast or flameshot is available
        if command -v grimblast &> /dev/null; then
          grimblast save area "$file"
        elif command -v flameshot &> /dev/null; then
          flameshot gui -r > "$file"
        else
          echo "No screenshot tool found"
        fi

        echo "$file"
        upload-file "$file"
      '')
    ];
  };
}
