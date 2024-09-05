{ lib, config, pkgs, ... }:

let
  cfg = config.modules.packages;
  makeOption = defaultVal:
    lib.mkOption {
      type = lib.types.bool;
      default = if cfg.full then true else defaultVal;
    };
in {
  options.modules.packages = {
    full = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    video = makeOption false;
    office = makeOption false;
    desktop = makeOption false;
    gaming = makeOption false;
    tor = makeOption false;
    communication = makeOption false;
    dev = makeOption false;
    crypto = makeOption false;
  };

  config = {
    environment.systemPackages = with pkgs;
      [ vim nano eza dig htop git home-manager ncdu jq ffmpeg zoxide tldr ]
      ++ (if cfg.desktop then [
        btop
        brave
        firefox
        librewolf
        nextcloud-client
        nomacs
        kdePackages.kate
        kdePackages.ark
        vlc
        vorta
        keepassxc
      ] else
        [ ]) ++ (if cfg.video then [
          freetube
          handbrake
          kdenlive
          yt-dlp
          obs-studio
          obs-studio-plugins.advanced-scene-switcher
        ] else
          [ ]) ++ (if cfg.office then [ libreoffice okular ] else [ ])
      ++ (if cfg.gaming then [
        lutris
        protonup
        steamguard-cli
        prismlauncher
      ] else
        [ ]) ++ (if cfg.tor then [ tor nyx protonvpn-gui ] else [ ])
      ++ (if cfg.communication then [
        teamspeak-client
        webcord
        signal-desktop
      ] else
        [ ]) ++ (if cfg.dev then [
          gimp
          lazygit
          vscodium
          jetbrains.webstorm
          jetbrains.rust-rover
          jetbrains.pycharm-professional
          jetbrains.idea-ultimate
        ] else
          [ ]) ++ (if cfg.crypto then [ electrum monero-gui ] else [ ]);

    programs = {
      steam.enable = cfg.gaming;
      kdeconnect.enable = cfg.desktop;
    };
  };
}
