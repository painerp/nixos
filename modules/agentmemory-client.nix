{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:

let
  cfg = config.modules.agentmemory-client;
  secret-path = config.age.secrets.agentmemory-client-env.path;
  read-secret = pkgs.writeShellScript "agentmemory-client-secret" ''
    # Read at login, never during Nix evaluation or a build.
    . ${lib.escapeShellArg secret-path}
    printf '%s' "$AGENTMEMORY_SECRET"
  '';
in
{
  options.modules.agentmemory-client = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    url = lib.mkOption {
      type = lib.types.str;
      default = "https://agentmemory-api.local.${config.server.base-domain}";
      description = "Shared AgentMemory REST API URL used by plugins and hooks.";
    };
    env-file = lib.mkOption {
      type = lib.types.path;
      default = secrets.inf-agentmemory-env;
      description = "Encrypted environment file containing the server's AGENTMEMORY_SECRET.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.agentmemory-client-env = {
      file = cfg.env-file;
      owner = config.system.username;
      mode = "0400";
    };

    environment = {
      systemPackages = [ pkgs.nodejs ];
      sessionVariables.AGENTMEMORY_URL = cfg.url;
      extraInit = ''
        if [ -r ${lib.escapeShellArg secret-path} ]; then
          export AGENTMEMORY_SECRET="$(${read-secret})"
        fi
      '';
    };
  };
}
