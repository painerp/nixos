{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [ "kvm-amd" ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  security.rtkit.enable = true;
  modules.pipewire.enable = true;

  services.udev.extraRules = ''
    ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x43d0" ATTR{power/wakeup}="disabled"
  '';

  hardware = {
    cpu.amd.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };
  };
}
