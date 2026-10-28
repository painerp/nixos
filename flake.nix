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
          pkgConfig ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs system;
          pkgs = (import nixpkgs) ({ inherit system; } // pkgConfig);
          modules = server-modules ++ [
            ./variants/${name}
            {
              system.flake = name;
              networking.hostName = "nix${name}";
              server.tailscale-ip = (import ./variants/${name}/tailnet.nix).ip;
            }
          ];
        };

      mkDesktop =
        { name }:
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
            ./variants/${name}
            ./variants/desktop.nix
            home-manager.nixosModules.home-manager
            {
              system = {
                flake = name;
                username = name;
                home-manager = true;
              };
              networking.hostName = name;
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
        };
        sex = mkServer { name = "sex"; };
        run = mkServer { name = "run"; };
        log = mkServer { name = "log"; };
        cit = mkServer { name = "cit"; };
        inf = mkServer { name = "inf"; };
        gra = mkServer {
          name = "gra";
          pkgConfig = {
            overlays = [ inputs.nvidia-patch.overlays.default ];
            config.allowUnfree = true;
          };
        };
        gam = mkServer { name = "gam"; };
        arr = mkServer { name = "arr"; };
        jbx = mkServer {
          name = "jbx";
          pkgConfig = {
            config.allowUnfree = true;
          };
        };

        # Desktops
        kronos = mkDesktop { name = "kronos"; };
        demeter = mkDesktop { name = "demeter"; };
        dionysus = mkDesktop { name = "dionysus"; };
        artemis = mkDesktop { name = "artemis"; };
      };
    };
}
