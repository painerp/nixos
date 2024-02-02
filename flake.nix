{
  description = "system config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = { agenix, nixpkgs, ... }@inputs:
    let
      secrets = import ./secrets;
      specialArgs = { inherit inputs secrets; };
      server-modules = [
        agenix.nixosModules.default
        ./modules/arion.nix
        ./modules/auto-update.nix
        ./modules/firewall.nix
        ./modules/micro.nix
        ./modules/packages.nix
        ./modules/ssh-server.nix
        ./modules/shell.nix
        ./modules/tailscale.nix
        ./modules/system.nix
      ];
    in {
      nixosConfigurations = {
        jpi = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          pkgs = (import nixpkgs) { system = "aarch64-linux"; };
          modules = server-modules ++ [ ./containers ./modules/kodi.nix ]
            ++ [ ./variants/jpi.nix ./hardware/rpi.nix ];
        };

        bpi = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          pkgs = (import nixpkgs) { system = "aarch64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/bpi.nix ./hardware/rpi.nix ];
        };

        ext = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/ext.nix ./hardware/vps.nix ];
        };

        run = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/run.nix ./hardware/int-vps.nix ];
        };

        log = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/log.nix ./hardware/int-vps.nix ];
        };

        cit = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/cit.nix ./hardware/int-vps.nix ];
        };

        inf = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [ ./containers ]
            ++ [ ./variants/inf.nix ./hardware/int-vps.nix ];
        };
      };
    };
}
