{
  description = "system config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };

    ags.url = "github:Aylur/ags";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      agenix,
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      secrets = import ./secrets;
      specialArgs = {
        inherit inputs secrets;
      };
      server-modules = [
        agenix.nixosModules.default
        ./modules
      ];
    in
    {
      nixosConfigurations = {
        jpi = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          pkgs = (import nixpkgs) { system = "aarch64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/jpi.nix
              ./hardware/rpi.nix
            ];
        };

        bpi = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          pkgs = (import nixpkgs) { system = "aarch64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/bpi.nix
              ./hardware/rpi.nix
            ];
        };

        ext = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/ext.nix
              ./hardware/vps.nix
            ];
        };

        run = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/run.nix
              ./hardware/int-vps.nix
            ];
        };

        log = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/log.nix
              ./hardware/int-vps.nix
            ];
        };

        cit = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/cit.nix
              ./hardware/int-vps.nix
            ];
        };

        inf = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules = server-modules ++ [
            ./variants/inf.nix
            ./hardware/int-vps.nix
          ];
        };

        gra = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) {
            system = "x86_64-linux";
            overlays = [ inputs.nvidia-patch.overlays.default ];
            config.allowUnfree = true;
          };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/gra.nix
              ./hardware/int-vps.nix
            ];
        };

        gam = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/gam.nix
              ./hardware/int-vps.nix
            ];
        };

        arr = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) { system = "x86_64-linux"; };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/arr.nix
              ./hardware/int-vps.nix
            ];
        };

        kronos = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs secrets;
            pkgs-unstable = (import nixpkgs-unstable) {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
          system = "x86_64-linux";
          pkgs = (import nixpkgs) {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          modules = server-modules ++ [
            ./variants/kronos.nix
            ./hardware/lenovo-15arh05h.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.kronos = import ./variants/homes/default.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                pkgs-unstable = (import nixpkgs-unstable) {
                  system = "x86_64-linux";
                  config.allowUnfree = true;
                };
              };
            }
          ];
        };

        dionysus = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs secrets;
            pkgs-unstable = (import nixpkgs-unstable) {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
          system = "x86_64-linux";
          pkgs = (import nixpkgs) {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [
              (import ./overlays/teamspeak_client.nix { })
              (import ./overlays/btop.nix { })
            ];
          };
          modules = server-modules ++ [
            ./variants/dionysus.nix
            ./hardware/amd-5800x3d.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.dionysus = import ./variants/homes/default.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs;
                pkgs-unstable = (import nixpkgs-unstable) {
                  system = "x86_64-linux";
                  config.allowUnfree = true;
                };
              };
            }
          ];
        };

        jbx = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          pkgs = (import nixpkgs) {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          modules =
            server-modules
            ++ [ ./containers ]
            ++ [
              ./variants/jbx.nix
              ./hardware/thinkcentre-m715q.nix
            ];
        };
      };
    };
}
