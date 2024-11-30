{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Theme Options:
      #### Powerline
      set -xg LC_ALL en_US.UTF-8
      set -xg LANG en_US.UTF-8

      ##### BobTheFish
      set -g theme_display_virtualenv yes
      set -g theme_display_user yes
      set -g theme_display_hostname ssh
      set -g theme_date_format '+%a %H:%M'
      set -g theme_date_timezone ${config.time.timeZone}
      set -g theme_powerline_fonts yes
      set -g theme_nerd_fonts yes
      set -g theme_show_exit_status yes
      set -g theme_color_scheme dark
      set -g theme_title_display_path yes
      set -x VIRTUAL_ENV_DISABLE_PROMPT 1
    '';
  };
  users.defaultUserShell = pkgs.fish;
  environment = with pkgs; {
    shells = [ fish ];
    shellAliases =
      {
        "cat" = "${bat}/bin/bat";
        "l" = "${eza}/bin/eza -l";
        "ls" = "${eza}/bin/eza -la";
        "ll" = "${eza}/bin/eza -la --tree";
        "cp" = "cp -i";
        "mv" = "mv -i";
        "sc" = "systemctl";
        "scs" = "systemctl status";
        "scr" = "systemctl restart";
        "sce" = "systemctl enable";
        "c" = "clear";
        "cdp" = "pushd";
        "ve" = "source ./venv/bin/activate";
        "jctl" = "journalctl -p 3 -xb";
        "ncdur" = "${ncdu}/bin/ncdu -x / --exclude /mnt --exclude-caches --exclude-kernfs --color dark";
      }
      // lib.attrsets.optionalAttrs (config.modules.packages.desktop) {
        "f" = "${xfce.thunar}/bin/thunar .";
      }
      // lib.attrsets.optionalAttrs (config.modules.packages.dev) { "lgit" = "${lazygit}/bin/lazygit"; }
      // lib.attrsets.optionalAttrs (config.modules.packages.video) {
        "yt-best" = "${yt-dlp}/bin/yt-dlp -f bestvideo+bestaudio/best";
        "yt-mp3" = "${yt-dlp}/bin/yt-dlp --extract-audio --audio-format mp3";
        "yt-flac" = "${yt-dlp}/bin/yt-dlp --extract-audio --audio-format flac";
      };
    systemPackages = [
      fishPlugins.done
      fishPlugins.puffer
      fishPlugins.fzf-fish
      fishPlugins.pisces
      fishPlugins.bobthefish
    ];
  };
}
