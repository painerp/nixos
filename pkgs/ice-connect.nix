{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.cpkgs.ice-connect;
in
{
  options.cpkgs.ice-connect = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "ice-connect" ''
        # if not connected to network connect to WIFIonICE SSID using networkmanager
        if [ "$(nmcli -t -f active,ssid dev wifi | grep -E '^yes' | cut -d ':' -f2)" != "WIFIonICE" ]; then
            nmcli dev wifi connect WIFIonICE
        fi

        # get ip using dig for "iceportal.de" from the dns provider given by the network interface
        DNS_IP=$(ip route | grep default | awk '{print $3}')
        ICEPORTALIP=$(dig +short iceportal.de "@$DNS_IP" | head -n 1)
        WIFIONICEIP=$(dig +short login.wifionice.de "@$DNS_IP" | head -n 1)

        # check if ips are not empty else quit
        if [ -z "$ICEPORTALIP" ] || [ -z "$WIFIONICEIP" ]; then
            echo "Could not find IP address of iceportal.de or login.wifionice.de"
            exit 1
        fi

        # remove lines with "iceportal.de" and "login.wifionice.de" from the hosts file
        sudo sed -i '/iceportal.de/d' /etc/hosts
        sudo sed -i '/login.wifionice.de/d' /etc/hosts

        # add "iceportal.de" and "login.wifionice.de" to the hosts file with the ip from the dns provider
        echo "$ICEPORTALIP iceportal.de" | sudo tee -a /etc/hosts
        echo "$WIFIONICEIP login.wifionice.de" | sudo tee -a /etc/hosts

        # open the login.wifionice.de url in the default browser
        xdg-open https://login.wifionice.de
      '')
    ];
  };
}
