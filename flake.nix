{
  description = "macDots — declarative macOS config via nix-darwin + home-manager + NixVim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nixvim, nix-homebrew, nix-vscode-extensions, ... }:
    let
      username = "christory";
      hostname = "macbook";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit username nixvim nix-vscode-extensions; };
        modules = [
          # Overlay: fix packages that fail to build from source on macOS
          {
            nixpkgs.overlays = [
              (final: prev: {
                direnv = prev.direnv.overrideAttrs (old: {
                  doCheck = false;  # test suite hangs on macOS (checkPhase >1hr)
                });
              })
            ];
          }

          ./hosts/macbook/default.nix
          ./hosts/macbook/homebrew.nix

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = username;
              autoMigrate = true;
            };
          }

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              extraSpecialArgs = { inherit username nixvim nix-vscode-extensions; };
              users.${username} = import ./home/default.nix;
            };
          }
        ];
      };
    };
}
