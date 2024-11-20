{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.upload-file;
in
{
  options.cpkgs.upload-file = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    key-file = lib.mkOption { type = lib.types.path; };
  };

  config = lib.mkIf (cfg.enable) {
    age.secrets.upload-file = {
      file = cfg.key-file;
      mode = "770";
      owner = config.system.username;
      group = "users";
    };
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "upload-file" ''
        set -euo pipefail

        url='https://${config.server.base-domain}'
        api_key="$(cat ${config.age.secrets.upload-file.path})"
        time='7'

        function _notify()
        {
            notify-send --expire-time 5000 \
                --app-name 'uploadfile' \
                --icon 'upload-pictures' \
                "$1" "$2"
        }

        set -e

        file_path="$1"

        # check if file exists and is readable and not empty
        if [ ! -f "$file_path" ] || [ ! -r "$file_path" ] || [ ! -s "$file_path" ]; then
            _notify '${config.server.base-domain} uploader' "Error"
            echo "File does not exist, is not readable or is empty." 1>&2
            exit 1
        fi

        res=$(curl -s -X POST \
                -F "files[]=@$file_path" \
                -H "X-API-KEY: $api_key" \
                "$url/api/up?duration=$time")

        if [[ "$res" == Error* ]]; then
            _notify '${config.server.base-domain} uploader' "Error"
            echo "Error while uploading." 1>&2
            echo "$res" 1>&2
            exit 1
        fi

        result="$url/up/$(echo -n "$res" | jq .id | tr -d \")"

        echo "file uploaded to: $result"

        echo -n "$result" | ${pkgs.xclip}/bin/xclip -selection clipboard
        _notify '${config.server.base-domain} uploader' 'Success! The link was sent to your clipboard'
        exit 0
      '')
    ];
  };
}
