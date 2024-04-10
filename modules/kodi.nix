{ lib, config, pkgs, ... }:

let cfg = config.modules.kodi;
in {
  options.modules.kodi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    users.extraUsers.kodi = {
      isNormalUser = true;
      extraGroups = [ "video" "audio" ];
    };

    services.xserver = {
      enable = true;
      desktopManager.kodi = {
        enable = true;
        package = (pkgs.kodi.passthru.withPackages
          (kodiPackages: with kodiPackages; [ jellyfin ]));
      };
      displayManager = {
        autoLogin = {
          enable = true;
          user = "kodi";
        };
        lightdm.autoLogin.timeout = 3;
      };
    };

    systemd.user.services.disable-dpms = {
      description = "Disable DPMS";
      serviceConfig.PassEnvironment = "DISPLAY";
      script = ''
        sudo -u kodi bash -c 'export DISPLAY=:0; xset s off -dpms'
      '';
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall = {
      allowedTCPPorts = [ 8080 9090 ];
      allowedUDPPorts = [ 8080 9090 ];
    };
  };
}
