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
    users.extraUsers.kodi.isNormalUser = true;
    users.extraUsers.kodi.extraGroups = [ "video" "audio" ];

    services.xserver.enable = true;
    services.xserver.desktopManager.kodi.enable = true;
    services.xserver.desktopManager.kodi.package =
      (pkgs.kodi.passthru.withPackages
        (kodiPackages: with kodiPackages; [ jellyfin ]));
    services.xserver.displayManager.autoLogin.enable = true;
    services.xserver.displayManager.autoLogin.user = "kodi";
    services.xserver.displayManager.lightdm.autoLogin.timeout = 3;

    # services.cage.user = "kodi";
    # services.cage.program = "${pkgs.kodi-wayland.withPackages (p: with p; [ jellyfin ])}/bin/kodi-standalone";
    # services.cage.enable = true;
    networking.firewall = {
      allowedTCPPorts = [ 8080 9090 ];
      allowedUDPPorts = [ 8080 9090 ];
    };
  };
}
