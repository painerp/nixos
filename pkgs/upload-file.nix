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

        function _fail()
        {
            _notify '${config.server.base-domain} uploader' "Error"
            echo "$1" 1>&2
            exit 1
        }

        file_path="''${1:-}"

        # check if file exists and is readable and not empty
        if [ ! -f "$file_path" ] || [ ! -r "$file_path" ] || [ ! -s "$file_path" ]; then
            _fail "File does not exist, is not readable or is empty."
        fi

        name="$(basename "$file_path")"
        size="$(stat -L -c %s -- "$file_path")"
        body_file="$(mktemp)"
        trap 'rm -f "$body_file"' EXIT

        # A request's body goes to $body_file; its HTTP status is printed, "000" whenever the transfer failed (even
        # after the headers arrived, so a cut answer is never taken for a complete one).
        function _request()
        {
            local method="$1" path="$2" code
            shift 2
            if code="$(curl -sS --connect-timeout 20 --speed-limit 1 --speed-time 60 \
                -o "$body_file" -w '%{http_code}' -X "$method" "$@" "$url$path")"; then
                echo "$code"
            else
                echo 000
            fi
        }

        # One piece: the bytes from $1, $2 of them, at the offset the server holds. Prints the status like _request.
        function _put_piece()
        {
            local code
            if code="$(dd if="$file_path" iflag=skip_bytes,count_bytes skip="$1" count="$2" bs=4M status=none \
                | curl -sS --connect-timeout 20 --speed-limit 1 --speed-time 60 \
                    -o "$body_file" -w '%{http_code}' -X PUT \
                    -H "X-Upload-Token: $token" -H 'Content-Type: application/octet-stream' \
                    --data-binary @- "$url/api/up/$id/files/0?offset=$1")"; then
                echo "$code"
            else
                echo 000
            fi
        }

        # A number from the last answer ($1 is the jq path); fails when the answer isn't the JSON expected.
        function _json_num()
        {
            jq -e -r "$1 | numbers" "$body_file" 2>/dev/null
        }

        # Waits a little longer after each failure in a row; gives up after 8.
        attempt=0
        function _backoff()
        {
            attempt=$((attempt + 1))
            if [ "$attempt" -gt 8 ]; then
                _fail "Upload failed: the server stopped answering ($1)."
            fi
            sleep $((attempt < 5 ? attempt * attempt : 30))
        }

        # The server's count is the truth; bytes it gained since the last answer reset the failures.
        received=0
        function _advance()
        {
            if [ "$1" -gt "$received" ]; then
                attempt=0
            fi
            received="$1"
        }

        # Asks the server how much it holds and continues from there.
        function _resync()
        {
            local now
            if [ "$(_request GET "/api/up/$id/progress" -H "X-Upload-Token: $token")" = 200 ] \
                && now="$(_json_num '.files[0]')"; then
                _advance "$now"
            fi
        }

        # Sends the rest of the file, piece by piece, from what the server holds.
        function _send_rest()
        {
            local length status before now
            while [ "$received" -lt "$size" ]; do
                length=$((size - received < piece_size ? size - received : piece_size))
                status="$(_put_piece "$received" "$length")"
                case "$status" in
                    200|409)
                        if now="$(_json_num .received)"; then
                            before="$received"
                            _advance "$now"
                            if [ "$received" -le "$before" ]; then
                                _backoff "no progress"
                            fi
                        else
                            _backoff "piece answer"
                            _resync
                        fi
                        ;;
                    507) _fail "The server's disk is full." ;;
                    000|5??)
                        # A piece cut short (a proxy's timeout, a dropped connection) keeps the bytes that arrived.
                        _backoff "piece $status"
                        _resync
                        ;;
                    *) _fail "The server refused a piece ($status): $(cat "$body_file")" ;;
                esac
            done
        }

        start_body="$(jq -n --arg name "$name" --argjson size "$size" --argjson days "$time" \
            '{files: [{name: $name, size: $size}], duration: $days}')"
        while true; do
            status="$(_request POST /api/up/start -H "X-API-KEY: $api_key" \
                -H 'Content-Type: application/json' --data "$start_body")"
            case "$status" in
                200)
                    if jq -e '(.id | strings) and (.token | strings)' "$body_file" >/dev/null 2>&1; then
                        break
                    fi
                    _backoff "start answer"
                    ;;
                000|5??) _backoff "start $status" ;;
                *) _fail "The server refused the upload ($status): $(cat "$body_file")" ;;
            esac
        done
        id="$(jq -r .id "$body_file")"
        token="$(jq -r .token "$body_file")"
        piece_size="$(jq -r '.piece_size // 16777216' "$body_file")"
        attempt=0

        _send_rest
        while true; do
            status="$(_request POST "/api/up/$id/finish" -H "X-Upload-Token: $token")"
            case "$status" in
                200) break ;;
                # The server misses bytes (it says which): send them, then finish again.
                409)
                    if now="$(_json_num '.files[0]')"; then
                        received="$now"
                        _send_rest
                    else
                        _backoff "finish answer"
                    fi
                    ;;
                000|5??) _backoff "finish $status" ;;
                *) _fail "The server refused to finish ($status): $(cat "$body_file")" ;;
            esac
        done

        result="$url/up/$id"

        echo "file uploaded to: $result"

        wl-copy "$result"
        _notify '${config.server.base-domain} uploader' 'Success! The link was sent to your clipboard'
        exit 0
      '')
    ];
  };
}
