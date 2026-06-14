{
  description = "system config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
        (import ./overlays/btop.nix { })
        (import ./overlays/hyprpanel.nix { })
        (import ./overlays/tailscale-patch.nix { })
        inputs.llm-agents.overlays.shared-nixpkgs
      ];
      desktop-insecure-packages = [ ];

      mkServer =
        {
          name,
          system ? "x86_64-linux",
          hardware,
          pkgConfig ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          pkgs = (import nixpkgs) ({ inherit system; } // pkgConfig);
          modules = server-modules ++ [
            ./variants/${name}.nix
            hardware
          ];
        };

      mkDesktop =
        { name, hardware }:
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
            ./variants/${name}.nix
            hardware
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.${name} = import ./variants/homes/default.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs pkgs-unstable;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        # Servers
        fpi = mkServer {
          name = "fpi";
          system = "aarch64-linux";
          hardware = ./hardware/rpi.nix;
        };
        sex = mkServer {
          name = "sex";
          hardware = ./hardware/vps.nix;
        };
        run = mkServer {
          name = "run";
          hardware = ./hardware/int-vps.nix;
        };
        log = mkServer {
          name = "log";
          hardware = ./hardware/int-vps.nix;
        };
        cit = mkServer {
          name = "cit";
          hardware = ./hardware/int-vps.nix;
        };
        inf = mkServer {
          name = "inf";
          hardware = ./hardware/int-vps.nix;
        };
        gra = mkServer {
          name = "gra";
          hardware = ./hardware/int-vps.nix;
          pkgConfig = {
            overlays = [ inputs.nvidia-patch.overlays.default ];
            config.allowUnfree = true;
          };
        };
        gam = mkServer {
          name = "gam";
          hardware = ./hardware/int-vps.nix;
        };
        arr = mkServer {
          name = "arr";
          hardware = ./hardware/int-vps.nix;
        };
        jbx = mkServer {
          name = "jbx";
          hardware = ./hardware/thinkcentre-m715q.nix;
          pkgConfig = {
            config.allowUnfree = true;
          };
        };

        # Desktops
        kronos = mkDesktop {
          name = "kronos";
          hardware = ./hardware/lenovo-legion-15arh05h.nix;
        };
        demeter = mkDesktop {
          name = "demeter";
          hardware = ./hardware/lenovo-legion-15arh05h.nix;
        };
        dionysus = mkDesktop {
          name = "dionysus";
          hardware = ./hardware/amd-5800x3d.nix;
        };
        artemis = mkDesktop {
          name = "artemis";
          hardware = ./hardware/tuxedo-infinitybook-pro-14-gen10.nix;
        };
      };
    };
}
