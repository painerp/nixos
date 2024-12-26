{
  description = "system config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
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

    hyprpanel.url = "github:painerp/HyprPanel";

    apod-wallpaper.url = "github:painerp/apod-wallpaper";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
        ./containers
      ];
      desktop-modules = server-modules ++ [
        ./pkgs
      ];
      desktop-overlays = [
        (import ./overlays/teamspeak_client.nix { })
        (import ./overlays/btop.nix { })
        inputs.hyprpanel.overlay
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

        ext =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            pkgs = (import nixpkgs) { inherit system; };
            modules = server-modules ++ [
              ./variants/ext.nix
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
              config.allowUnfree = true;
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/kronos.nix
              ./hardware/lenovo-15arh05h.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.kronos = import ./variants/homes/default.nix;
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
            pkgs = (import nixpkgs) {
              inherit system;
              config.allowUnfree = true;
              overlays = desktop-overlays;
            };
            modules = desktop-modules ++ [
              ./variants/dionysus.nix
              ./hardware/amd-5800x3d.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
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
      };
    };
}
