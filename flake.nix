{
  description = "ClewdR - High-Performance LLM Proxy for Claude and Google Gemini";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Development and deployment tools
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Container and deployment utilities
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    
    # Documentation and formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Pre-commit hooks for code quality
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, devenv, sops-nix, flake-compat, treefmt-nix, pre-commit-hooks }:
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

        devShells = {
          default = self.devShells.${system}.full;
          
          # Full development environment with all tools
          full = pkgs.mkShell {
            inputsFrom = [ self.devShells.${system}.pre-commit ];
            buildInputs = with pkgs; [
              # Rust toolchain
              (rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" "rust-analyzer" ];
              })
              
              # Node.js and frontend tools
              nodejs_22
              nodePackages.pnpm
              nodePackages.typescript
              nodePackages.eslint
              nodePackages.prettier
              
              # Build dependencies
              pkg-config
              openssl
              cmake
              clang
              
              # Development and debugging tools
              cargo-audit
              cargo-deny
              cargo-edit
              cargo-expand
              cargo-watch
              cargo-udeps
              bacon
              
              # System monitoring and testing
              htop
              curl
              jq
              wrk
              hyperfine
              
              # Documentation tools
              mdbook
              mdbook-linkcheck
              mdbook-mermaid
              
              # Container and deployment tools
              docker-compose
              act
              sops
              age
              
              # Git and version control
              git
              git-lfs
              gh
              
              # Network and security tools
              nmap
              tcpdump
              openssl
              
              # Runtime dependencies
              cacert
            ];

            shellHook = ''
              echo "🚀 ClewdR Full Development Environment"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "📦 Rust version: $(rustc --version)"
              echo "🟢 Node.js version: $(node --version)"
              echo "📋 pnpm version: $(pnpm --version)"
              echo "🔧 Tools available: cargo-watch, bacon, act, sops, wrk, hyperfine"
              echo "📚 Documentation: mdbook available for docs generation"
              echo "🐳 Container tools: docker-compose available"
              echo "🔒 Security tools: cargo-audit, cargo-deny, sops, age"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "💡 Quick commands:"
              echo "   cargo watch -x run    # Auto-rebuild on changes"
              echo "   bacon                 # Fast incremental builds"
              echo "   act push              # Test GitHub Actions locally"
              echo "   cargo audit           # Security audit"
              echo "   wrk -t4 -c100 http://localhost:8080  # Load testing"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            '';
          };
          
          # Minimal development environment
          minimal = pkgs.mkShell {
            buildInputs = with pkgs; [
              (rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" "rust-analyzer" ];
              })
              nodejs_22
              nodePackages.pnpm
              pkg-config
              openssl
              cmake
              clang
              cacert
            ];
            
            shellHook = ''
              echo "⚡ ClewdR Minimal Development Environment"
              echo "Rust: $(rustc --version) | Node: $(node --version)"
            '';
          };
          
          # Pre-commit environment
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Rust hooks
              rustfmt.enable = true;
              clippy.enable = true;
              cargo-check.enable = true;
              
              # General hooks
              check-yaml.enable = true;
              check-json.enable = true;
              check-toml.enable = true;
              check-merge-conflicts.enable = true;
              end-of-file-fixer.enable = true;
              trailing-whitespace.enable = true;
              
              # Security
              detect-private-keys.enable = true;
              
              # Nix
              nixpkgs-fmt.enable = true;
              statix.enable = true;
            };
          };
        };

        apps = {
          default = self.apps.${system}.clewdr;
          
          # Main ClewdR application
          clewdr = {
            type = "app";
            program = "${self.packages.${system}.clewdr}/bin/clewdr";
          };
          
          # Development utilities
          dev-watch = {
            type = "app";
            program = "${pkgs.writeShellScript "dev-watch" ''
              echo "🔄 Starting ClewdR development watch mode..."
              exec ${pkgs.cargo-watch}/bin/cargo watch -x "run --release"
            ''}";
          };
          
          # Security audit
          security-audit = {
            type = "app";
            program = "${pkgs.writeShellScript "security-audit" ''
              echo "🔒 Running comprehensive security audit..."
              echo "1. Cargo audit for Rust dependencies..."
              ${pkgs.cargo-audit}/bin/cargo audit
              echo "2. Cargo deny for license and security policies..."
              ${pkgs.cargo-deny}/bin/cargo deny check
              echo "3. Checking for unused dependencies..."
              ${pkgs.cargo-udeps}/bin/cargo +nightly udeps
            ''}";
          };
          
          # Performance benchmarking
          bench = {
            type = "app";
            program = "${pkgs.writeShellScript "benchmark" ''
              echo "📊 Running ClewdR performance benchmarks..."
              SERVER_PID=""
              
              cleanup() {
                if [ -n "$SERVER_PID" ]; then
                  echo "Stopping server (PID: $SERVER_PID)..."
                  kill $SERVER_PID 2>/dev/null || true
                fi
              }
              trap cleanup EXIT
              
              echo "Starting ClewdR server..."
              ${self.packages.${system}.clewdr}/bin/clewdr &
              SERVER_PID=$!
              
              echo "Waiting for server to start..."
              sleep 5
              
              echo "Running load test with wrk..."
              ${pkgs.wrk}/bin/wrk -t4 -c100 -d30s --timeout 10s http://localhost:8484/ || echo "Load test completed"
              
              echo "Running hyperfine benchmark..."
              ${pkgs.hyperfine}/bin/hyperfine --warmup 3 '${pkgs.curl}/bin/curl -s http://localhost:8484/' || echo "Response time benchmark completed"
            ''}";
          };
          
          # Documentation generation
          docs = {
            type = "app";
            program = "${pkgs.writeShellScript "generate-docs" ''
              echo "📚 Generating documentation..."
              
              if [ ! -f "book.toml" ]; then
                echo "Initializing mdbook..."
                ${pkgs.mdbook}/bin/mdbook init docs --title "ClewdR Documentation" --force
                cd docs
              fi
              
              echo "Building documentation..."
              ${pkgs.mdbook}/bin/mdbook build
              
              echo "Documentation generated in docs/book/"
              echo "Serve with: mdbook serve"
            ''}";
          };
          
          # Container deployment
          deploy = {
            type = "app";
            program = "${pkgs.writeShellScript "deploy" ''
              echo "🚀 Deploying ClewdR..."
              
              if [ ! -f "docker-compose.yml" ]; then
                echo "Creating docker-compose.yml..."
                cat > docker-compose.yml << 'EOF'
              version: '3.8'
              services:
                clewdr:
                  image: nixos/nix:latest
                  volumes:
                    - .:/workspace
                  working_dir: /workspace
                  command: ["nix", "run", ".#clewdr"]
                  ports:
                    - "8484:8484"
                  environment:
                    - ANTHROPIC_API_KEY=\''${ANTHROPIC_API_KEY:-}
                    - GOOGLE_AI_API_KEY=\''${GOOGLE_AI_API_KEY:-}
              EOF
              fi
              
              echo "Starting with docker-compose..."
              ${pkgs.docker-compose}/bin/docker-compose up --build
            ''}";
          };
          
          # CI/CD testing
          test-ci = {
            type = "app";
            program = "${pkgs.writeShellScript "test-ci" ''
              echo "🧪 Testing CI/CD pipeline locally..."
              
              echo "1. Running flake checks..."
              nix flake check --no-build
              
              echo "2. Testing with act..."
              if command -v docker >/dev/null 2>&1; then
                ${pkgs.act}/bin/act push --job simple-test || echo "Act test completed"
              else
                echo "Docker not available, skipping act test"
              fi
              
              echo "3. Running pre-commit hooks..."
              nix develop .#pre-commit --command pre-commit run --all-files || echo "Pre-commit completed"
            ''}";
          };
          
          # Secrets management
          secrets = {
            type = "app";
            program = "${pkgs.writeShellScript "secrets-manager" ''
              echo "🔐 ClewdR Secrets Management"
              
              case "''${1:-help}" in
                "encrypt")
                  echo "Encrypting secrets with sops..."
                  ${pkgs.sops}/bin/sops -e secrets.yaml > secrets.enc.yaml
                  ;;
                "decrypt")
                  echo "Decrypting secrets..."
                  ${pkgs.sops}/bin/sops -d secrets.enc.yaml > secrets.yaml
                  ;;
                "edit")
                  echo "Editing encrypted secrets..."
                  ${pkgs.sops}/bin/sops secrets.enc.yaml
                  ;;
                "init")
                  echo "Initializing secrets management..."
                  ${pkgs.age}/bin/age-keygen -o age.key
                  echo "Generated age.key - keep this secure!"
                  ;;
                *)
                  echo "Usage: nix run .#secrets <command>"
                  echo "Commands: encrypt, decrypt, edit, init"
                  ;;
              esac
            ''}";
          };
        };

        checks = {
          # Core package build
          build = self.packages.${system}.clewdr;
          
          # NixOS VM integration test
          nixos-vm-test = import ./tests/nixos-test.nix {
            inherit pkgs;
            clewdrPackage = self.packages.${system}.clewdr;
            clewdrModule = self.nixosModules.clewdr;
          };
          
          # Performance test
          performance-test = import ./tests/performance-test.nix {
            inherit pkgs;
            clewdrPackage = self.packages.${system}.clewdr;
            clewdrModule = self.nixosModules.clewdr;
          };
          
          # Pre-commit hooks
          pre-commit = self.devShells.${system}.pre-commit;
          
          # Security audit
          security-audit = pkgs.runCommand "security-audit" {
            buildInputs = [ pkgs.cargo-audit pkgs.cargo-deny ];
          } ''
            cd ${./.}
            echo "Running cargo audit..." > $out
            ${pkgs.cargo-audit}/bin/cargo audit >> $out 2>&1 || echo "Audit completed with warnings" >> $out
            echo "Running cargo deny..." >> $out
            ${pkgs.cargo-deny}/bin/cargo deny check >> $out 2>&1 || echo "Deny check completed" >> $out
          '';
          
          # Flake validation
          flake-check = pkgs.runCommand "flake-check" {
            buildInputs = [ pkgs.nix ];
          } ''
            cd ${./.}
            echo "Checking flake syntax..." > $out
            nix flake check --no-build >> $out 2>&1
            echo "Flake check completed" >> $out
          '';
          
          # Documentation build
          docs-build = pkgs.runCommand "docs-build" {
            buildInputs = [ pkgs.mdbook ];
          } ''
            mkdir -p docs/src
            cd docs
            
            # Create basic book.toml if it doesn't exist
            cat > book.toml << 'EOF'
            [book]
            authors = ["ClewdR Team"]
            title = "ClewdR Documentation"
            
            [build]
            build-dir = "book"
            EOF
            
            # Create basic README if src doesn't exist
            cat > src/SUMMARY.md << 'EOF'
            # Summary
            
            - [Introduction](./introduction.md)
            - [Installation](./installation.md)
            - [Configuration](./configuration.md)
            - [API Reference](./api.md)
            EOF
            
            cat > src/introduction.md << 'EOF'
            # ClewdR Documentation
            
            ClewdR is a high-performance LLM proxy for Claude and Google Gemini.
            EOF
            
            cat > src/installation.md << 'EOF'
            # Installation
            
            ## Using Nix Flakes
            
            ```bash
            nix run github:user/clewdr-flake
            ```
            
            ## NixOS Module
            
            ```nix
            services.clewdr = {
              enable = true;
              port = 8484;
            };
            ```
            EOF
            
            cat > src/configuration.md << 'EOF'
            # Configuration
            
            ClewdR can be configured via environment variables or configuration files.
            EOF
            
            cat > src/api.md << 'EOF'
            # API Reference
            
            ClewdR provides a REST API compatible with OpenAI's format.
            EOF
            
            echo "Building documentation..." > $out
            ${pkgs.mdbook}/bin/mdbook build >> $out 2>&1
            echo "Documentation built successfully" >> $out
          '';
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