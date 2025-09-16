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
      "ehci_pci"
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [
      "kvm-amd"
      "softdog"
    ];
    kernelParams = [
      "idle=nomwait"
      "processor.max_cstate=5"
      "rcu_nocbs=0-3"
    ];
    kernel.sysctl = {
      "kernel.watchdog_thresh" = 10;
    };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=500M
  '';

  security.rtkit.enable = true;
  modules.pipewire.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };
  };
}
