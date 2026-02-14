{ inputs, ... }:
{
  config = {
    server.base-domain = inputs.nixos-private.common.domain;
    users.users.root.openssh.authorizedKeys.keys = [
      inputs.nixos-private.common.ssh-key
    ];
  };
}
