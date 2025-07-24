{ lib, config, ... }:

let
  cfg = config.modules.ssh;
in
{
  options.modules.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable) {
    services = {
      openssh = {
        enable = true;
        allowSFTP = false;
        ports = [ 22 ];
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };

        extraConfig = ''
          MaxAuthTries 5
          MaxSessions 2
          TCPKeepAlive no
        '';
      };
      fail2ban = {
        enable = true;
        maxretry = 10;
        bantime-increment.enable = true;
      };
    };
    security.pam.sshAgentAuth.enable = true;
    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
