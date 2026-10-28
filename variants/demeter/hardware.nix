{
  imports = [ ../../hardware/lenovo-legion-15arh05h.nix ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8DC6-573B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0ebe90ed-0ab3-498b-92b1-f60bc27fb7b6";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/36361ec2-9a77-4002-9772-947f7054dd4c"; } ];
}
