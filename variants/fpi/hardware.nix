{
  imports = [ ../../hardware/rpi.nix ];

  # wired, rpi.nix defaults to wlan
  networking.wireless.enable = false;
}
