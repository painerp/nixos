{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.legion-keyboard;
in
{
  options.cpkgs.legion-keyboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.writers.writePython3Bin "legion-keyboard"
        {
          libraries = with pkgs.python3Packages; [
            pyusb
          ];
        }
        ''
          import argparse, re, usb.core

          colors = {
              'black': [0, 0, 0],
              'white': [255, 255, 255],
              'darkgray': [128, 128, 128],
              'lightgray': [176, 176, 176],
              'red': [255, 0, 0],
              'darkred': [128, 0, 0],
              'green': [0, 255, 0],
              'darkgreen': [0, 128, 0],
              'blue': [0, 0, 255],
              'darkblue': [0, 0, 128],
              'yellow': [255, 255, 0],
              'olive': [128, 128, 0],
              'cyan': [0, 255, 255],
              'magenta': [255, 0, 255],
              'purple': [128, 0, 128]
          }


          class LedController:
              VENDOR = 0x048D
              PRODUCT = 0xC955  # 0xC965 2021 model
              EFFECT = {"static": 1, "breath": 3, "wave": 4, "hue": 6}

              def __init__(self):
                  device = usb.core.find(idVendor=self.VENDOR, idProduct=self.PRODUCT)

                  if device is None:
                      raise ValueError("Light device not found")

                  # Prevent usb.core.USBError: [Errno 16] Resource busy
                  if device.is_kernel_driver_active(0):
                      device.detach_kernel_driver(0)

                  self.device = device

              # Build light device control string
              def build_control_string(
                      self,
                      effect,
                      colors=None,
                      speed=1,
                      brightness=1,
                      wave_direction=None,
              ):
                  data = [204, 22]

                  if effect == "off":
                      data.append(self.EFFECT["static"])
                      data += [0] * 30
                      return data

                  data.append(self.EFFECT[effect])
                  data.append(speed)
                  data.append(brightness)

                  if effect not in ["static", "breath"]:
                      data += [0] * 12
                  else:
                      chunk = None
                      for section in range(0, 4):

                          if section < len(colors):
                              color = colors[section].lower()

                              model = None
                              # Detect color model
                              if re.match(r"^[0-9a-f]{6}$", color):
                                  # HEX model
                                  chunk = [
                                      int(color[i: i + 2], 16) for i in range(0, len(color), 2)
                                  ]
                              else:
                                  components = color.split(",")

                                  if components[0].isdigit():
                                      # RGB model
                                      components = list(map(lambda c: int(c), components))

                                      # Validate RGB input
                                      for component in components:
                                          if not 0 <= component <= 255:
                                              raise ValueError(
                                                  f"Invalid RGB color model: {color}"
                                              )

                                      chunk = list(components)

                                  elif re.match(r"^\d+\.\d+$", components[0]):
                                      # HSV model
                                      components = list(map(lambda c: float(c), components))

                                      # Validate HSV input
                                      for component in components:
                                          if not 0 <= component <= 1:
                                              raise ValueError(
                                                  f"Invalid HSV color model: {color}"
                                              )

                                      from colorsys import hsv_to_rgb

                                      chunk = list(
                                          map(lambda c: int(c * 255), hsv_to_rgb(*components))
                                      )

                                  else:
                                      raise ValueError(f"Invalid color model: {color}")

                          data += chunk

                  # Unused
                  data += [0]

                  # Wave direction
                  if wave_direction == "rtl":
                      data += [1, 0]
                  elif wave_direction == "ltr":
                      data += [0, 1]
                  else:
                      data += [0, 0]

                  # Unused
                  data += [0] * 13

                  return data

              # Send command to device
              def send_control_string(self, data):
                  self.device.ctrl_transfer(
                      bmRequestType=0x21,
                      bRequest=0x9,
                      wValue=0x03CC,
                      wIndex=0x00,
                      data_or_wLength=data,
                  )


          def string_to_color(i_str):
              if i_str in colors:
                  return colors[i_str]
              return []


          def main():
              parser = argparse.ArgumentParser(description='Process some integers.')
              parser.add_argument('color', type=str, nargs='?', default="blue",
                                  help='the color you want to set')
              parser.add_argument('brightness', type=int, nargs='?', default=100,
                                  help='the brightness you want to set')
              args = parser.parse_args()

              color = args.color
              brightness = args.brightness
              if color != "":
                  if args.color.isdigit():
                      color = "blue"
                      brightness = int(args.color)
                  color_list = string_to_color(color)
                  if color_list:
                      if 0 <= brightness <= 100:
                          if brightness != 100:
                              for i, c in enumerate(color_list):
                                  color_list[i] = round(c / 100 * brightness)
                          print("changing color & brightness")
                          controller = LedController()
                          data = controller.build_control_string(
                              effect="static" if brightness > 0 else "off",
                              colors=[",".join(str(x) for x in color_list)] * 4
                          )
                          controller.send_control_string(data)
                      else:
                          print("brightness must be between 0-100")


          if __name__ == '__main__':
              main()
        ''
      )
    ];
  };
}
