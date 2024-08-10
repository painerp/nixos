{ inputs, ... }:

{
  imports = [ inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
