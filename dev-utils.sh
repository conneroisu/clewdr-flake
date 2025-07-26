#!/usr/bin/env bash
# ClewdR Development Utilities
# Comprehensive development workflow management script
# Provides unified interface for common development tasks
# Usage: ./dev-utils.sh <command> [arguments]

# Exit on any error, undefined variables, or pipe failures
# Ensures script stops on first sign of trouble for safety
set -euo pipefail

# Change to script directory for consistent relative path behavior
# Ensures all operations work regardless of where script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ANSI color codes for enhanced terminal output readability
# Provides visual feedback for different types of operations
RED='\033[0;31m'      # Error messages and failures
GREEN='\033[0;32m'    # Success messages and completions
YELLOW='\033[1;33m'   # Warning messages and notifications
BLUE='\033[0;34m'     # Informational messages and progress
NC='\033[0m'          # Reset to default color

# Logging functions with emoji indicators for visual clarity
# Provides consistent formatting for different message types

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Development environment setup and initialization
# Prepares the development environment with all necessary tools
dev_setup() {
    log_info "Setting up ClewdR development environment..."
    
    # Initialize complete development environment with full toolchain
    log_info "Entering Nix development shell..."
    nix develop
}

# Automatic rebuild and development watch mode
# Monitors source files and rebuilds on changes for rapid iteration
dev_watch() {
    log_info "Starting development watch mode..."
    nix run .#dev-watch
}

# Comprehensive testing suite covering all aspects of code quality
# Runs unit tests, integration tests, security audits, and code quality checks
dev_test() {
    log_info "Running comprehensive tests..."
    
    # Run Rust unit and integration tests
    log_info "1. Running cargo tests..."
    cargo test
    
    # Validate Nix flake configuration and build definitions
    log_info "2. Running Nix flake checks..."
    nix flake check --no-build
    
    # Security vulnerability and policy compliance scanning
    log_info "3. Running security audit..."
    nix run .#security-audit
    
    # Code quality enforcement through pre-commit hooks
    log_info "4. Running pre-commit hooks..."
    nix develop .#pre-commit --command pre-commit run --all-files || true
    
    log_success "All tests completed!"
}

dev_docs() {
    log_info "Generating and serving documentation..."
    
    # Generate docs
    nix run .#docs
    
    # Serve docs if mdbook is available
    if command -v mdbook >/dev/null 2>&1; then
        log_info "Serving documentation at http://localhost:3000"
        cd docs && mdbook serve
    else
        log_info "Documentation generated in docs/book/"
        log_info "To serve: cd docs && nix shell nixpkgs#mdbook --command mdbook serve"
    fi
}

dev_bench() {
    log_info "Running performance benchmarks..."
    nix run .#bench
}

dev_lint() {
    log_info "Running code linting and formatting..."
    
    log_info "1. Formatting Rust code..."
    cargo fmt
    
    log_info "2. Running Clippy..."
    cargo clippy -- -D warnings
    
    log_info "3. Formatting Nix files..."
    nixpkgs-fmt *.nix || nix shell nixpkgs#nixpkgs-fmt --command nixpkgs-fmt *.nix
    
    log_info "4. Running pre-commit hooks..."
    nix develop .#pre-commit --command pre-commit run --all-files || true
    
    log_success "Linting completed!"
}

dev_clean() {
    log_info "Cleaning development artifacts..."
    
    # Clean Rust artifacts
    cargo clean
    
    # Clean Nix build results
    rm -rf result result-*
    
    # Clean documentation
    rm -rf docs/book
    
    # Clean temporary files
    find . -name "*.tmp" -delete
    find . -name "*.log" -delete
    
    log_success "Cleanup completed!"
}

dev_security() {
    log_info "Running comprehensive security checks..."
    
    log_info "1. Cargo audit..."
    cargo audit
    
    log_info "2. Cargo deny checks..."
    cargo deny check
    
    log_info "3. Detecting secrets..."
    if command -v detect-secrets >/dev/null 2>&1; then
        detect-secrets scan --all-files --baseline .secrets.baseline || true
    fi
    
    log_info "4. Nix security scan..."
    nix run .#security-audit
    
    log_success "Security checks completed!"
}

dev_deploy() {
    log_info "Deploying ClewdR..."
    
    case "${1:-docker}" in
        "docker")
            log_info "Deploying with Docker Compose..."
            nix run .#deploy
            ;;
        "nixos")
            log_info "Building NixOS configuration..."
            nix build .#nixosConfigurations.example.config.system.build.toplevel
            log_success "NixOS configuration built successfully!"
            ;;
        "vm")
            log_info "Testing with NixOS VM..."
            nix build .#checks.x86_64-linux.nixos-vm-test
            log_success "VM test completed!"
            ;;
        "k8s")
            log_info "Deploying to Kubernetes..."
            kubectl apply -f k8s/deployment.yaml
            log_success "Kubernetes deployment completed!"
            ;;
        "helm")
            log_info "Deploying with Helm..."
            helm upgrade --install clewdr k8s/helm-chart/ --create-namespace --namespace clewdr
            log_success "Helm deployment completed!"
            ;;
        "staging")
            log_info "Deploying to staging environment..."
            kubectl apply -k gitops/environments/staging/
            log_success "Staging deployment completed!"
            ;;
        "production")
            log_info "Deploying to production environment..."
            kubectl apply -k gitops/environments/production/
            log_success "Production deployment completed!"
            ;;
        *)
            log_error "Unknown deployment target: $1"
            log_info "Available targets: docker, nixos, vm, k8s, helm, staging, production"
            exit 1
            ;;
    esac
}

dev_ci() {
    log_info "Running CI pipeline locally..."
    nix run .#test-ci
}

dev_secrets() {
    log_info "Managing secrets..."
    shift # Remove 'secrets' from arguments
    nix run .#secrets -- "$@"
}

dev_profile() {
    log_info "Running performance profiling..."
    shift # Remove 'profile' from arguments
    nix run .#profile -- "$@"
}

dev_integration() {
    log_info "Running integration tests..."
    nix run .#test-integration
}

dev_multiarch() {
    log_info "Building multi-architecture images..."
    nix run .#build-multiarch
}

show_help() {
    cat << EOF
🚀 ClewdR Development Utilities

Usage: $0 <command> [arguments]

Commands:
  setup         Setup development environment
  watch         Start development watch mode  
  test          Run comprehensive tests
  docs          Generate and serve documentation
  bench         Run performance benchmarks
  lint          Run linting and formatting
  clean         Clean development artifacts
  security      Run security checks
  deploy        Deploy ClewdR (docker|nixos|vm|k8s|helm|staging|production)
  ci            Run CI pipeline locally
  secrets       Manage secrets (init|encrypt|decrypt|edit)
  profile       Performance profiling (cpu|memory|flamegraph|benchstat)
  integration   Run integration tests
  multiarch     Build multi-architecture images
  help          Show this help message

Examples:
  $0 setup                    # Setup development environment
  $0 watch                    # Start auto-rebuilding
  $0 test                     # Run all tests
  $0 deploy k8s               # Deploy to Kubernetes
  $0 deploy staging           # Deploy to staging environment
  $0 profile cpu              # Run CPU profiling
  $0 integration              # Run integration tests
  $0 multiarch                # Build multi-arch containers
  $0 secrets init             # Initialize secrets management
  $0 security                 # Run security audit

For more information, see the generated documentation.
EOF
}

# Main command dispatcher
main() {
    case "${1:-help}" in
        "setup") dev_setup ;;
        "watch") dev_watch ;;
        "test") dev_test ;;
        "docs") dev_docs ;;
        "bench") dev_bench ;;
        "lint") dev_lint ;;
        "clean") dev_clean ;;
        "security") dev_security ;;
        "deploy") shift; dev_deploy "$@" ;;
        "ci") dev_ci ;;
        "secrets") dev_secrets "$@" ;;
        "profile") dev_profile "$@" ;;
        "integration") dev_integration ;;
        "multiarch") dev_multiarch ;;
        "help"|"-h"|"--help") show_help ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Check if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi