{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.tsmusicbot-cookies;
in
{
  options.cpkgs.tsmusicbot-cookies = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "tsmusicbot-cookies" ''
        # Signs a throwaway account into YouTube in a fresh LibreWolf profile and pushes the cookies to the tsmusicbot.
        # The profile is deleted afterwards, so the session never runs in a browser again and YouTube doesn't rotate the exported cookies.
        set -euo pipefail

        host=''${1:-root@nixsex}
        dest=/root/config/tsmusicbot/data/cookies.txt
        profile=$(mktemp -d)
        trap 'rm -rf "$profile"' EXIT

        # librewolf wipes cookies on shutdown by default
        echo 'user_pref("privacy.sanitize.sanitizeOnShutdown", false);' >"$profile/user.js"

        echo "Sign in with the throwaway account, then close the browser window."
        ${pkgs.librewolf}/bin/librewolf --no-remote --profile "$profile" \
          'https://accounts.google.com/ServiceLogin?service=youtube&passive=true&continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Faction_handle_signin%3Dtrue%26app%3Ddesktop%26next%3Dhttps%253A%252F%252Fwww.youtube.com%252F' \
          >/dev/null 2>&1

        # yt-dlp copies only cookies.sqlite, so fold the write-ahead log into it first
        ${pkgs.python3}/bin/python3 -I -c 'import sqlite3, sys; sqlite3.connect(sys.argv[1]).execute("PRAGMA wal_checkpoint(TRUNCATE)")' "$profile/cookies.sqlite"
        # yt-dlp complains about the missing URL but still writes the cookie file
        ${pkgs.yt-dlp}/bin/yt-dlp --cookies-from-browser "firefox:$profile" --cookies "$profile/cookies.txt" >/dev/null 2>&1 || true
        if ! grep -sqE $'\t(LOGIN_INFO|SAPISID)\t' "$profile/cookies.txt"; then
          echo "No YouTube login cookies found, nothing uploaded." >&2
          exit 1
        fi

        # the bot (uid 2000) must be able to write it, yt-dlp saves rotated cookies back
        ssh "$host" "cat > $dest && chown 2000:2000 $dest && chmod 600 $dest" <"$profile/cookies.txt"
        echo "Uploaded to $host:$dest"
      '')
    ];
  };
}
