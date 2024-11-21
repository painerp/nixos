{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.brightness;
in
{
  options.cpkgs.brightness = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      pkgs.brightnessctl
      (pkgs.writers.writePython3Bin "brightness" { } ''
        import os
        import shutil
        import subprocess
        import sys


        def get_brightness(device: str) -> int:
            stdout, stderr = subprocess.Popen(["brightnessctl", "-md", device],
                                              stdout=subprocess.PIPE,
                                              stderr=subprocess.PIPE).communicate()
            if "not found" in str(stderr):
                print("[ERROR] Getting brightness for " + device)
                exit(1)
            return int(str(stdout).split(",")[-2].strip("%"))


        def set_brightness(device: str, change: str) -> int:
            stdout, stderr = subprocess.Popen(["brightnessctl", "-md", device, "set", change],
                                              stdout=subprocess.PIPE,
                                              stderr=subprocess.PIPE).communicate()
            if "invalid" in str(stderr):
                print("[ERROR] Invalid brightness value")
                exit(1)
            return int(str(stdout).split(",")[-2].strip("%"))


        def get_device_name():
            device_names = os.listdir('/sys/class/backlight/')
            amdgpu_devices = [name for name in device_names if name.startswith('amdgpu')]
            if amdgpu_devices:
                return amdgpu_devices[0]
            nvidia_devices = [name for name in device_names if name.startswith('nvidia')]
            if nvidia_devices:
                return nvidia_devices[0]
            acpi_devices = [name for name in device_names if name.startswith('acpi_video')]
            if acpi_devices:
                return acpi_devices[0]
            return None


        def main(args):
            device = get_device_name()
            if device is None:
                print("[ERROR] No device found")
                exit(1)

            brightness = get_brightness(device)
            if len(args) == 0:
                print(brightness)
                return

            new_brightness = set_brightness(device, args[0])

            if "5%" in args[0] and brightness != new_brightness and new_brightness != 0 and new_brightness != 100:
                difference = brightness - new_brightness
                if abs(difference) % 5 != 0:
                    # fixing brightnessctl bug
                    new_brightness = set_brightness(device, str(abs(difference) % 5) + ("+" if difference > 0 else "-"))

            if shutil.which("dunstify") is not None:
                brightness_status = ("Stayed at " if brightness == new_brightness else ("Decreased" if brightness > new_brightness else "Increased") + " to ") + str(new_brightness) + "%"
                brightness_icon = "display-brightness-off" if new_brightness == 0 else (
                    "display-brightness-low" if new_brightness < 34 else "display-brightness-medium" if new_brightness < 67 else "display-brightness-high")
                os.system("dunstify -a 'BRIGHTNESS' '" + brightness_status + "' -h int:value:" + str(
                    new_brightness) + " -i " + brightness_icon + " -r 2593 -u normal")


        if __name__ == '__main__':
            main(sys.argv[1:])
      '')
    ];
  };
}
