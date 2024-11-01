{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  cfg = config.modules.packages;
  makeOption =
    defaultVal:
    lib.mkOption {
      type = lib.types.bool;
      default = if cfg.full then true else defaultVal;
    };
in
{
  options.modules.packages = {
    full = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    video = makeOption false;
    image = makeOption false;
    office = makeOption false;
    desktop = makeOption false;
    gaming = makeOption false;
    tor = makeOption false;
    communication = makeOption false;
    dev = makeOption false;
    crypto = makeOption false;
    vm = makeOption false;
  };

  config = {
    environment.systemPackages =
      with pkgs;
      [
        vim
        nano
        eza
        dig
        htop
        git
        home-manager
        ncdu
        jq
        ffmpeg
        zoxide
        tldr
      ]
      ++ (
        if cfg.desktop then
          [
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
          ]
        else
          [ ]
      )
      ++ (
        if cfg.video then
          [
            pkgs-unstable.freetube
            handbrake
            kdenlive
            yt-dlp
            (pkgs.wrapOBS { plugins = with pkgs.obs-studio-plugins; [ advanced-scene-switcher ]; })
          ]
        else
          [ ]
      )
      ++ (
        if cfg.office then
          [
            libreoffice
            okular
            obsidian
          ]
        else
          [ ]
      )
      ++ (
        if cfg.image then
          [
            krita
            upscayl
          ]
        else
          [ ]
      )
      ++ (
        if cfg.gaming then
          [
            mangohud
            heroic
            lutris
            protonup
            steamguard-cli
            prismlauncher
          ]
        else
          [ ]
      )
      ++ (
        if cfg.tor then
          [
            tor
            nyx
            protonvpn-gui
          ]
        else
          [ ]
      )
      ++ (
        if cfg.communication then
          [
            teamspeak_client.overrideAttrs
            (oldAttrs: rec {
              soundpack = lib.fetchzip {
                url = "https://addons-content.teamspeak.com/8a9a93a7-5dd6-403e-8d15-435e5bfbd970/files/3/dukenukem-2.0.0.ts3_soundpack";
                hash = "341199c11963c0773f20bbf81824d8c3e9296bf989b6657ad489f76689449941";
              };
              iconpack = lib.fetchzip {
                url = "https://addons-content.teamspeak.com/0b57d54d-b46c-433d-8f7e-2eea28470007/files/8/DarkenTS_v1.7.1.ts3_iconpack";
                hash = "9b26447f3d5bb4a54422a8c6903628cb167a02d35b2ad8a75f4090964e68ee50";
              };
              style = lib.fetchzip {
                url = "https://addons-content.teamspeak.com/686209af-0b66-4805-b2d7-0e990f7cb9e0/files/15/DarkenTSv172_5ec97131ef925.ts3_style";
                hash = "77bcaa82e01646383871c0647f4f86195b3ca0ac1d2cddae1b7f18a331601f2f";
              };
              installPhase =
                oldAttrs.installPhase
                + ''
                  cp -r ${soundpack}/sound/dukenukem $out/lib/teamspeak/sound
                  cp -r ${iconpack}/gfx/DarkenTS $out/lib/teamspeak/gfx
                  cp -r ${style}/styles/* $out/lib/teamspeak/styles
                '';
            })
            webcord
            signal-desktop
          ]
        else
          [ ]
      )
      ++ (
        if cfg.dev then
          [
            ungoogled-chromium
            nixfmt-rfc-style
            lazygit
            nodePackages_latest.nodejs
            nodePackages_latest.pnpm
            python3
            jdk
            jetbrains.webstorm
            jetbrains.rust-rover
            jetbrains.pycharm-professional
            jetbrains.idea-ultimate
          ]
        else
          [ ]
      )
      ++ (
        if cfg.crypto then
          [
            electrum
            monero-gui
          ]
        else
          [ ]
      );

    programs = {
      steam = {
        enable = cfg.gaming;
        gamescopeSession.enable = true;
      };
      gamemode.enable = cfg.gaming;
      kdeconnect.enable = cfg.desktop;
      xfconf.enable = cfg.desktop;
      thunar = {
        enable = cfg.desktop;
        plugins = with pkgs.xfce; [
          thunar-archive-plugin
          thunar-volman
        ];
      };
      nh = {
        enable = true;
        #        clean.enable = true;
        #        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/etc/nixos";
      };
      java = {
        enable = cfg.dev;
        package = pkgs.jdk;
      };
    };

    virtualisation.virtualbox.host.enable = cfg.vm;
    users.extraGroups.vboxusers.members = [ "${config.system.username}" ];

    services = {
      tumbler.enable = cfg.desktop;
      syncthing = {
        enable = cfg.desktop;
        user = config.system.username;
        dataDir = "/home/${config.system.username}/Syncthing";
        configDir = "/home/${config.system.username}/.config/syncthing";
      };
    };
  };
}
