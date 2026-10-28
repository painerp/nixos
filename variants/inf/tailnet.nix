{
  ip = "100.115.5.117";
  outgoing = {
    nixgra.routers = [ "jellyfin" ];
    nixarr.routers = [
      "gluetun"
      "sabnzbd"
    ];
    nixcit.routers = [
      "adguardhome"
      "authentik"
      "forgejo"
      "peanut"
      "truenas"
    ];
    nixfpi.ports = [ "tcp:443" ];
    nixjbx.ports = [ "tcp:443" ];
  };
}
