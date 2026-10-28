{
  ip = "100.118.176.61";
  outgoing = {
    nixarr.routers = [
      "sonarr"
      "radarr"
    ];
    nixcit.routers = [ "authentik" ];
  };
}
