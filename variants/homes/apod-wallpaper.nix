{
  inputs,
  pkgs,
  osConfig,
}:

{
  environment.systemPackages = [
    inputs.apod-wallpaper.packages.${pkgs.system}.default
  ];
  systemd.user = {
    services.apod-wallpaper = {
      serviceConfig.Type = "oneshot";
      script = ''
        apod-wallpaper -m
      '';
    };
    timers = {
      apod-wallpaper = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 07:15:00 ${osConfig.time.timeZone}";
          Persistent = true;
          Unit = "apod-wallpaper.service";
        };
      };
    };
  };
}
