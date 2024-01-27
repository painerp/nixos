{ pkgs, config, secrets, ... }:

let
 ssh-field = if config.options.server.tailscale.ssh then " --ssh" else "";
in {
  options.server.tailscale = {
	  ssh = lib.mkOption {
	    type = lib.types.bool;
	    default = true;
	  };
	};

	config = {
    environment.systemPackages = [ pkgs.tailscale ];

    age.secrets.tailscale-api-key.file = secrets.tailscale-api-key;

    services.tailscale.enable = true;
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up${ssh-field} --authkey $(cat "${config.age.secrets.tailscale-api-key.path}")
      '';
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  };
}