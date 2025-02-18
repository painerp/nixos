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
        gdu
        jq
        ffmpeg
        zoxide
        zip
        tealdeer
      ]
      ++ (
        if cfg.desktop then
          [
            inputs.apod-wallpaper.packages.${pkgs.system}.default
            brave
            nextcloud-client
            nomacs
            kdePackages.kate
            kdePackages.ark
            vlc
            vorta
            keepassxc
            gparted
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
            hunspell
            hunspellDicts.de_DE
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
            pkgs-unstable.teamspeak6-client
            vesktop
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
            inputs.agenix.packages.${pkgs.system}.default
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
      nix-ld.enable = cfg.dev;
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
      firefox = {
        enable = cfg.desktop;
        package = pkgs.librewolf;
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          Preferences = {
            "cookiebanners.service.mode.privateBrowsing" = 1;
            "cookiebanners.service.mode" = 1;
            "privacy.donottrackheader.enabled" = false;
            "privacy.fingerprintingProtection" = true;
            "privacy.resistFingerprinting" = true;
            "privacy.trackingprotection.emailtracking.enabled" = true;
            "privacy.trackingprotection.enabled" = true;
            "privacy.trackingprotection.fingerprinting.enabled" = true;
            "privacy.trackingprotection.socialtracking.enabled" = true;
          };
          ExtensionSettings = {
            "keepassxc-browser@keepassxc.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
              installation_mode = "force_installed";
            };
            "addon@darkreader.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
              installation_mode = "force_installed";
            };
            "uMatrix@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/umatrix/latest.xpi";
              installation_mode = "force_installed";
            };
            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };
            "newtaboverride@agenedia.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/new-tab-override/latest.xpi";
              installation_mode = "force_installed";
            };
          };
        };
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

    systemd.user = lib.mkIf (cfg.desktop) {
      services.apod-wallpaper = {
        serviceConfig.Type = "oneshot";
        script = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.libnotify
              pkgs.hyprland
              pkgs.swww
            ]
          };
          export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt;
          ${inputs.apod-wallpaper.packages.${pkgs.system}.default}/bin/apod-wallpaper -m
        '';
      };
      timers.apod-wallpaper = {
        wantedBy = [ "default.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 07:15:00 ${config.time.timeZone}";
          Persistent = true;
          Unit = "apod-wallpaper.service";
        };
      };
    };
  };
}
