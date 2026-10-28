# servers list what they may reach in variants/<host>/tailnet.nix:
#   outgoing.<dst>.routers: traefik routers on <dst>, implies tcp:443
#   outgoing.<dst>.ports:   ports, acl only
# builtins only, CI evaluates it without the flake
rec {
  devices = {
    truenas.ip = "100.111.75.128";
    proxmox.ip = "100.67.2.33";
  };

  # granted to every server
  common.outgoing = {
    nixcit.routers = [ "attic" ];
  };

  servers =
    let
      dirs = builtins.readDir ./variants;
      isServer = d: dirs.${d} == "directory" && builtins.pathExists (./variants + "/${d}/tailnet.nix");
    in
    builtins.listToAttrs (
      map (d: {
        name = "nix${d}";
        value = import (./variants + "/${d}/tailnet.nix");
      }) (builtins.filter isServer (builtins.attrNames dirs))
    );

  hosts = builtins.mapAttrs (_: h: h.ip) (servers // devices);

  # src -> dst -> { routers; ports; }
  outgoing = builtins.mapAttrs (
    src: h:
    let
      own = h.outgoing or { };
      extra = if servers ? ${src} then common.outgoing else { };
      get = dst: attr: (own.${dst}.${attr} or [ ]) ++ (extra.${dst}.${attr} or [ ]);
    in
    builtins.mapAttrs (
      dst: _:
      if hosts ? ${dst} then
        {
          routers = get dst "routers";
          ports = get dst "ports";
        }
      else
        throw "tailnet: ${src} has outgoing to unknown host ${dst}"
    ) (own // extra)
  ) (servers // devices);

  # dst -> router -> [ src ]
  incoming =
    let
      uniqSort =
        l:
        builtins.attrNames (
          builtins.listToAttrs (
            map (x: {
              name = x;
              value = null;
            }) l
          )
        );
      pairs = builtins.concatMap (
        src:
        builtins.concatMap (dst: map (router: { inherit src dst router; }) outgoing.${src}.${dst}.routers) (
          builtins.attrNames outgoing.${src}
        )
      ) (builtins.attrNames outgoing);
      result = builtins.mapAttrs (
        _: ps: builtins.mapAttrs (_: rs: uniqSort (map (p: p.src) rs)) (builtins.groupBy (p: p.router) ps)
      ) (builtins.groupBy (p: p.dst) pairs);
    in
    # policy tests can't see traefik grants
    if !builtins.elem "nixrun" (result.nixcit.forgejo or [ ]) then
      throw "tailnet: nixrun (CI runner) must keep the forgejo router on nixcit"
    else
      result;

  generatedGrants = builtins.concatMap (
    src:
    builtins.concatMap (
      dst:
      let
        o = outgoing.${src}.${dst};
        ip = o.ports ++ (if o.routers != [ ] then [ "tcp:443" ] else [ ]);
      in
      if ip == [ ] || src == dst then
        [ ]
      else
        [
          {
            src = [ src ];
            dst = [ dst ];
            inherit ip;
          }
        ]
    ) (builtins.attrNames outgoing.${src})
  ) (builtins.attrNames outgoing);

  # CI only evaluates policy
  policy = builtins.seq incoming {
    groups = { };

    inherit hosts;

    tagOwners = {
      "tag:admin" = [ ];
      "tag:ssh" = [ ];
      "tag:nfs" = [ ];
      "tag:dns" = [ ];
      "tag:git-ssh" = [ ];
      "tag:outpost" = [ ];
      "tag:webadmin" = [ ];
      "tag:authentik-local" = [ ];
      "tag:monitoring" = [ ];
      "tag:git-user" = [ ];
      "tag:syncthing" = [ ];
      "tag:pbs" = [ ];
      "tag:pbs-server" = [ ];
      "tag:nixos" = [ ];
      "tag:adguardhome-sync" = [ ];
    };

    ssh = [
      {
        action = "accept";
        src = [ "tag:admin" ];
        dst = [ "tag:ssh" ];
        users = [
          "autogroup:nonroot"
          "root"
        ];
      }
    ];

    grants = [
      # allow all to access internal dns
      {
        src = [ "*" ];
        dst = [ "tag:dns" ];
        ip = [ "53" ];
      }
      # allow admins to access everything
      {
        src = [ "tag:admin" ];
        dst = [ "*" ];
        ip = [ "*" ];
      }
      # allow webadmins to only access webpages on outposts
      {
        src = [ "tag:webadmin" ];
        dst = [ "tag:outpost" ];
        ip = [ "443" ];
      }
      # allow nfs tags to access nas devices (allow all ports since 111,2049 doesn't work)
      {
        src = [ "tag:nfs" ];
        dst = [ "truenas" ];
        ip = [ "*" ];
      }
      # allow proxmox to access pbs
      {
        src = [ "tag:pbs" ];
        dst = [ "tag:pbs-server" ];
        ip = [ "8007" ];
      }
      # allow local authentik-proxy to work
      {
        src = [ "tag:authentik-local" ];
        dst = [ "nixcit" ];
        ip = [
          "80"
          "443"
        ];
      }
      # allow nixos to reach binary cache
      {
        src = [ "tag:nixos" ];
        dst = [ "nixcit" ];
        ip = [
          "80"
          "443"
        ];
      }
      # allow exit nodes to be used
      {
        src = [
          "tag:admin"
          "tag:webadmin"
        ];
        dst = [ "autogroup:internet" ];
        ip = [ "*" ];
      }
      # allow syncthing devices to access the syncthing server
      {
        src = [ "tag:syncthing" ];
        dst = [ "tag:syncthing" ];
        ip = [ "22000" ];
      }
      # allow git-ssh tags to access the forgejo instance
      {
        src = [ "tag:git-ssh" ];
        dst = [ "nixcit" ];
        ip = [ "22" ];
      }
      {
        src = [ "host:nixcit" ];
        dst = [ "192.168.10.240/29" ];
        ip = [ "tcp:80" ];
      }
      # lets the sync server at nixcit connect to all replicas
      {
        src = [ "host:nixcit" ];
        dst = [ "tag:adguardhome-sync" ];
        ip = [ "tcp:443" ];
      }
      # allow forgejo runners and users access to forgejo host
      {
        src = [ "tag:git-user" ];
        dst = [ "nixcit" ];
        ip = [ "80" ];
      }
      {
        src = [ "tag:git-user" ];
        dst = [ "nixcit" ];
        ip = [ "443" ];
      }
      {
        src = [ "tag:monitoring" ];
        dst = [ "nixlog" ];
        ip = [ "20100" ];
      }
      {
        src = [ "tag:monitoring" ];
        dst = [ "nixlog" ];
        ip = [ "20101" ];
      }
    ]
    ++ generatedGrants;

    tests = [
      # CI runner -> forgejo
      {
        src = "tag:git-user";
        accept = [ "nixcit:443" ];
      }
      {
        src = "tag:admin";
        accept = [
          "nixcit:22"
          "nixlog:443"
        ];
      }
      {
        src = "nixgam";
        deny = [ "nixgra:443" ];
      }
      {
        src = "nixsex";
        deny = [ "nixcit:22" ];
      }
    ];
  };
}
