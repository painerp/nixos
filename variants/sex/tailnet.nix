{
  ip = "100.82.15.66";
  outgoing = {
    nixgam.ports = [
      "7777"
      "8888"
      "25565"
      "25569"
      "25575"
    ];
    nixarr.routers = [ "prdl" ];
    nixgra.ports = [
      "3478"
      "8096"
      "11000"
    ];
    nixlog.routers = [ "prometheus-public" ];
    nixcit.routers = [ "forgejo" ];
  };
}
