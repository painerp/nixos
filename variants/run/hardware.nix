{
  imports = [ ../../hardware/int-vps.nix ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6b1b23b8-f684-4e29-8680-78e5214ae4b6";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e5863ec2-52d0-4a56-a0e8-43c211e28e69";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/351ceb5f-c78d-4560-ad86-d78d646fd3a5"; } ];
}
