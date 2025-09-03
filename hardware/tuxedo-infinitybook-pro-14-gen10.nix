{
  config,
  inputs,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "thunderbolt"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    #    kernelPackages =
    #      let
    #        linux_tuxedo_pkg =
    #          { fetchFromGitLab, buildLinux, ... }@args:
    #          buildLinux (
    #            args
    #            // rec {
    #              version = "6.11";
    #              modDirVersion = version;
    #
    #              src = fetchFromGitLab {
    #                owner = "tuxedocomputers/development/packages";
    #                repo = "linux";
    #                #                url = "https://gitlab.com/tuxedocomputers/development/packages/linux";
    #                rev = "69f9c936b9403a9a0008b89da93edac402bcdb8b";
    #                hash = "";
    #              };
    #
    #              extraMeta.branch = "6.11";
    #            }
    #            // (args.argsOverride or { })
    #          );
    #        linux_tuxedo = pkgs.callPackage linux_tuxedo_pkg { };
    #      in
    #      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor tuxedo);

    kernelModules = [ "kvm-amd" ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 30;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  security.rtkit.enable = true;
  modules.pipewire.enable = true;
  services = {
    tlp = {
      enable = true;
      settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        USB_EXCLUDE_BTUSB = 1;
        USB_EXCLUDE_PHONE = 1;
        WOL_DISABLE = "Y";
      };
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Experimental = true;
    };
  };
}
