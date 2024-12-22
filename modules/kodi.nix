{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.kodi;
in
{
  options.modules.kodi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    users.extraUsers.kodi = {
      isNormalUser = true;
      extraGroups = [
        "video"
        "audio"
      ];
    };

    services = {
      xserver = {
        enable = true;
        desktopManager.kodi = {
          enable = true;
          package = (pkgs.kodi.passthru.withPackages (kodiPackages: with kodiPackages; [ jellyfin ]));
        };
        displayManager.lightdm.autoLogin.timeout = 3;
      };
      displayManager.autoLogin = {
        enable = true;
        user = "kodi";
      };
    };

    systemd.services.kodi-dpms = {
      description = "Disable DPMS";
      serviceConfig = {
        User = "kodi";
        PassEnvironment = "DISPLAY";
      };
      environment = {
        DISPLAY = ":0";
      };
      script = "sleep 30; ${pkgs.xorg.xset}/bin/xset s off -dpms";
      wantedBy = [ "multi-user.target" ];
    };

    networking.firewall = {
      allowedTCPPorts = [
        8080
        9090
      ];
      allowedUDPPorts = [
        8080
        9090
      ];
    };
  };
}
