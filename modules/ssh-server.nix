{ lib, config, ... }:

let cfg = config.modules.ssh;
in {
  options.modules.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    security.pam.sshAgentAuth.enable = true;
  };
}
