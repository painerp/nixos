{
  description = "system config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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

    hyprpanel = {
      url = "github:painerp/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apod-wallpaper = {
      url = "github:painerp/apod-wallpaper-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-deploy = {
      url = "github:painerp/nix-deploy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-private.url = "git+ssh://git@github.com/painerp/nixos-private.git";
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
        ./containers
      ];
      desktop-modules = server-modules ++ [
        ./pkgs
      ];
      desktop-overlays = [
        (import ./overlays/teamspeak3.nix { })
        (import ./overlays/btop.nix { })
        (import ./overlays/hyprpanel.nix { })
        (import ./overlays/tailscale-patch.nix { })
      ];
      desktop-insecure-packages = [
        "qtwebengine-5.15.19"
      ];
    in
    {
      nixosConfigurations = {
        jpi =
          let
            system = "aarch64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/jpi.nix
              ./hardware/rpi.nix
            ];
          };

        bpi =
          let
            system = "aarch64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/bpi.nix
              ./hardware/rpi.nix
            ];
          };

        sex =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/sex.nix
              ./hardware/vps.nix
            ];
          };

        run =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/run.nix
              ./hardware/int-vps.nix
            ];
          };

        log =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/log.nix
              ./hardware/int-vps.nix
            ];
          };

        cit =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/cit.nix
              ./hardware/int-vps.nix
            ];
          };

        inf =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/inf.nix
              ./hardware/int-vps.nix
            ];
          };

        gra =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) {
              inherit system;
              overlays = [ inputs.nvidia-patch.overlays.default ];
              config.allowUnfree = true;
            };
            modules = server-modules ++ [
              ./variants/gra.nix
              ./hardware/int-vps.nix
            ];
          };

        gam =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/gam.nix
              ./hardware/int-vps.nix
            ];
          };

        arr =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/arr.nix
              ./hardware/int-vps.nix
            ];
          };

        kronos =
          let
            system = "x86_64-linux";
            pkgs-unstable = (import nixpkgs-unstable) {
              inherit system;
              config.allowUnfree = true;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs secrets pkgs-unstable;
            };
            inherit system;
            pkgs = (import nixpkgs) {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = desktop-insecure-packages;
              };
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/kronos.nix
              ./hardware/lenovo-legion-15arh05h.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "bak";
                home-manager.users.kronos = import ./variants/homes/default.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs pkgs-unstable;
                };
              }
            ];
          };

        demeter =
          let
            system = "x86_64-linux";
            pkgs-unstable = (import nixpkgs-unstable) {
              inherit system;
              config.allowUnfree = true;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs secrets pkgs-unstable;
            };
            inherit system;
            pkgs = (import nixpkgs) {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = desktop-insecure-packages;
              };
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/demeter.nix
              ./hardware/lenovo-legion-15arh05h.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "bak";
                home-manager.users.demeter = import ./variants/homes/default.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs pkgs-unstable;
                };
              }
            ];
          };

        dionysus =
          let
            system = "x86_64-linux";
            pkgs-unstable = (import nixpkgs-unstable) {
              inherit system;
              config.allowUnfree = true;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs secrets pkgs-unstable;
            };
            inherit system;
            pkgs = (import nixpkgs) {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = desktop-insecure-packages;
              };
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/dionysus.nix
              ./hardware/amd-5800x3d.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "bak";
                home-manager.users.dionysus = import ./variants/homes/default.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs pkgs-unstable;
                };
              }
            ];
          };

        jbx =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) {
              inherit system;
              config.allowUnfree = true;
            };
            modules = server-modules ++ [
              ./variants/jbx.nix
              ./hardware/thinkcentre-m715q.nix
            ];
          };

        artemis =
          let
            system = "x86_64-linux";
            pkgs-unstable = (import nixpkgs-unstable) {
              inherit system;
              config.allowUnfree = true;
            };
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs secrets pkgs-unstable;
            };
            inherit system;
            pkgs = (import nixpkgs) {
              inherit system;
              config = {
                allowUnfree = true;
                permittedInsecurePackages = desktop-insecure-packages;
              };
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/artemis.nix
              ./hardware/tuxedo-infinitybook-pro-14-gen10.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "bak";
                home-manager.users.artemis = import ./variants/homes/default.nix;
                home-manager.extraSpecialArgs = {
                  inherit inputs pkgs-unstable;
                };
              }
            ];
          };
      };
    };
}
