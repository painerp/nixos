{
  imports = [ ../../hardware/tuxedo-infinitybook-pro-14-gen10.nix ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/5070-501D";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f17744c3-6eea-4e50-b1e6-3e2cea40633d";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/73350b87-60ae-4b36-aff7-898f1077bc36"; } ];

  boot.initrd.luks.devices = {
    "luks-1c8482e1-c564-4a5d-9945-b849b8ea7725".device =
      "/dev/disk/by-uuid/1c8482e1-c564-4a5d-9945-b849b8ea7725";
    "luks-d6eeba2f-1c7e-45f2-bad8-ccafdbd03559".device =
      "/dev/disk/by-uuid/d6eeba2f-1c7e-45f2-bad8-ccafdbd03559";
  };

  modules.amd.enable = true;
}
