{
  ip = "100.115.5.117";
  outgoing = {
    nixgra.ports = [ "tcp:443" ];
    nixarr.ports = [ "tcp:443" ];
    nixfpi.ports = [ "tcp:443" ];
    nixjbx.ports = [ "tcp:443" ];
    nixcit.ports = [ "tcp:443" ];
  };
}
