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

    # Homebrew itself is a read-only nix store copy (nix-homebrew symlinks
    # /opt/homebrew/Library/Homebrew into /nix/store), so `brew update` CANNOT
    # upgrade brew — its version is entirely whatever this input pins.
    #
    # Left as a transitive input of nix-homebrew, brew-src is locked to the tag
    # that zhaofengli's repo happens to pin, which lags upstream by weeks: `nix
    # flake update` respects nix-homebrew's own flake.lock and so never moves it.
    # Cask/formula metadata meanwhile refreshes on every activation, so brew
    # drifts behind the taps and starts failing on casks it can't parse.
    #
    # Declaring it here + `follows` puts brew on the normal update cadence.
    # Tracks main (brew releases are cut from it); pin a tag like
    # "github:Homebrew/brew/6.0.20" if an unreleased commit ever breaks a rebuild.
    brew-src = {
      url = "github:Homebrew/brew";
      flake = false;
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nixvim, nix-homebrew, nix-vscode-extensions, ... }:
    let
      # Transitional two-machine setup — see
      # docs/superpowers/specs/2026-07-01-two-machine-transitional-coexistence-design.md
      # Both machines build from one flake; only hostname + username differ.
      # TEARDOWN: delete the `macbook` (old) entry once that Mac is wiped.
      mkHost = { hostname, username }: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit username hostname nixvim nix-vscode-extensions; };
        modules = [
          # Overlay: fix packages that fail to build from source on macOS
          {
            nixpkgs.overlays = [
              # VS Code marketplace sets (pkgs.vscode-marketplace, pkgs.open-vsx).
              # Consumed as an overlay rather than via the flake's own
              # `extensions.<system>` output on purpose: that output builds
              # against nix-vscode-extensions' OWN nixpkgs instance, whose config
              # is empty, so `nixpkgs.config.allowUnfree` below does not reach it.
              # The set also substitutes nixpkgs' own derivation for extensions
              # nixpkgs packages specially ("fixes"), and those carry real license
              # metadata — so an extension like rangav.vscode-thunder-client
              # becomes an eval-time unfree refusal the moment nixpkgs starts
              # packaging it. As an overlay, `pkgsWithFixes` defaults to this
              # nixpkgs, and allowUnfree applies.
              nix-vscode-extensions.overlays.default

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
              extraSpecialArgs = { inherit username hostname nixvim nix-vscode-extensions; };
              users.${username} = import ./home/default.nix;
            };
          }
        ];
      };
    in
    {
      darwinConfigurations = {
        # OLD machine — wiped after migration; delete this entry at teardown.
        macbook = mkHost {
          hostname = "macbook";
          username = "christopherstory";
        };

        # NEW machine — the keeper / canonical config.
        christoryCertifyOSMacbook = mkHost {
          hostname = "christoryCertifyOSMacbook";
          username = "christory";
        };
      };
    };
}
