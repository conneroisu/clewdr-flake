{
  description = "ClewdR - High-Performance LLM Proxy for Claude and Google Gemini";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        overlays = [ rust-overlay.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      in
      {
        packages = {
          default = self.packages.${system}.clewdr;
          clewdr = pkgs.callPackage ./package.nix { };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain
            (rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" "rust-analyzer" ];
            })
            
            # Node.js and pnpm for frontend
            nodejs_22
            nodePackages.pnpm
            
            # Build dependencies
            pkg-config
            openssl
            cmake
            clang
            
            # Runtime dependencies
            cacert
          ];

          shellHook = ''
            echo "ClewdR development environment"
            echo "Rust version: $(rustc --version)"
            echo "Node.js version: $(node --version)"
            echo "pnpm version: $(pnpm --version)"
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.clewdr}/bin/clewdr";
        };

        checks = {
          build = self.packages.${system}.clewdr;
          nixos-vm-test = import ./nixos-test.nix { inherit pkgs; };
        };
      }
    ) // {
      # NixOS module
      nixosModules.default = import ./module.nix;
      nixosModules.clewdr = import ./module.nix;
      
      # Overlay for easy integration
      overlays.default = final: prev: {
        clewdr = final.callPackage ./package.nix { };
      };
    };
}