{
  inputs,
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
    system = lib.mkOption {
      type = lib.types.str;
      default = "x86_64-linux";
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
        zip
        tealdeer
      ]
      ++ (
        if cfg.desktop then
          [
            inputs.apod-wallpaper.packages.${cfg.system}.default
            brave
            librewolf
            nextcloud-client
            nomacs
            kdePackages.kate
            kdePackages.ark
            vlc
            vorta
            keepassxc
          ]
          ++ (
            if config.modules.amd.enable then
              [ btop_amd ]
            else
              (if config.modules.nvidia.enable then [ btop_nvidia ] else [ btop ])
          )
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
            teamspeak_client
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
            nixd
            inputs.agenix.packages.${cfg.system}.default
            lazygit
            nodePackages_latest.nodejs
            nodePackages_latest.pnpm
            (python3Full.withPackages (python-pkgs: [
              python-pkgs.pytest
              python-pkgs.requests
            ]))
            jdk
            pkgs-unstable.uv
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
        clean.enable = true;
        clean.extraArgs = "--keep-since 30d --keep 30";
        flake = "/etc/nixos";
      };
      java = {
        enable = cfg.dev;
        package = pkgs.jdk;
      };
    };

    nix.nixPath = lib.mkIf (cfg.dev) [ "nixpkgs=${inputs.nixpkgs}" ];

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
