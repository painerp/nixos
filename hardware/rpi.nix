{ inputs, pkgs, ... }:

{
  imports = [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  sound.enable = true;
  hardware.enableRedistributableFirmware = true;

  # tries to enable hdmi-cec support
  nixpkgs.overlays = [
    (self: super: {
      libcec = super.libcec.override { withLibraspberrypi = true; };
    })
  ];

  environment.systemPackages = with pkgs; [ libcec ];

  services.udev.extraRules = ''
    # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
    SUBSYSTEM=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

  # optional: attach a persisted cec-client to `/run/cec.fifo`, to avoid the CEC ~1s startup delay per command
  # scan for devices: `echo 'scan' &gt; /run/cec.fifo ; journalctl -u cec-client.service`
  # set pi as active source: `echo 'as' &gt; /run/cec.fifo`
  # systemd.sockets."cec-client" = {
  #   after = [ "dev-vchiq.device" ];
  #   bindsTo = [ "dev-vchiq.device" ];
  #   wantedBy = [ "sockets.target" ];
  #   socketConfig = {
  #     ListenFIFO = "/run/cec.fifo";
  #     SocketGroup = "video";
  #     SocketMode = "0660";
  #   };
  # };
  # systemd.services."cec-client" = {
  #   after = [ "dev-vchiq.device" ];
  #   bindsTo = [ "dev-vchiq.device" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = ''${pkgs.libcec}/bin/cec-client -d 1'';
  #     ExecStop = ''/bin/sh -c "echo q &gt; /run/cec.fifo"'';
  #     StandardInput = "socket";
  #     StandardOutput = "journal";
  #     Restart="no";
  # };
}
