# ClewdR NixOS Flake

A comprehensive production-ready NixOS flake for [ClewdR](https://github.com/Xerxes-2/clewdr) - a high-performance LLM proxy for Claude and Google Gemini APIs. This flake provides complete package building, service management, container deployment, and development tooling.

## ✨ Features

- 🚀 **Complete NixOS Integration** - Package, service module, and system configuration
- 🐳 **Container Support** - Docker, Kubernetes, and multi-architecture builds  
- 📊 **Development Tools** - Full development environment with profiling and testing
- 🔒 **Production Ready** - Security hardening, monitoring, and automated deployment
- 🛠️ **Developer Experience** - IDE integration, pre-commit hooks, and automated workflows

## 🚀 Quick Start

### Using the Flake

```bash
# Run ClewdR directly
nix run github:your-username/clewdr-flake

# Build the package
nix build github:your-username/clewdr-flake#clewdr

# Enter full development environment
nix develop github:your-username/clewdr-flake

# Build container image
nix build github:your-username/clewdr-flake#container
```

### NixOS Service Configuration

Add to your `flake.nix`:

```nix
{
  inputs.clewdr-flake.url = "github:your-username/clewdr-flake";
  
  outputs = { self, nixpkgs, clewdr-flake }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        clewdr-flake.nixosModules.clewdr
        ./configuration.nix
      ];
    };
  };
}
```

Then configure the service in your `configuration.nix`:

```nix
{
  services.clewdr = {
    enable = true;
    ip = "127.0.0.1";
    port = 8484;
    
    settings = {
      password = "your-api-password";
      admin_password = "your-admin-password";
      check_update = false;
      auto_update = false;
    };
    
    environment = {
      ANTHROPIC_API_KEY = "your-claude-key";
      GOOGLE_AI_API_KEY = "your-gemini-key";
    };
    
    openFirewall = true;
  };
}
```

## 📦 What's Included

### Core Components
- **📦 NixOS Package** - ClewdR built with reqwest HTTP client for compatibility
- **⚙️ NixOS Module** - Complete service configuration with security hardening
- **🐳 Container Images** - Docker and OCI-compatible images with multi-arch support
- **☸️ Kubernetes Deployment** - Production-ready manifests and Helm charts
- **🔄 GitOps Integration** - Kustomize and ArgoCD configurations

### Development Environment
- **🛠️ Full Toolchain** - Rust, Node.js, security tools, and profiling utilities
- **🔍 IDE Integration** - VS Code configuration with debugging support
- **🧪 Testing Framework** - Unit tests, integration tests, and security scanning
- **📊 Performance Tools** - CPU/memory profiling, benchmarking, and flame graphs
- **🔒 Security Tools** - Dependency auditing, license compliance, and secrets management

### Deployment Options
- **🖥️ NixOS Service** - Native systemd service with full integration
- **🐳 Docker Containers** - Optimized layered images for production
- **☸️ Kubernetes** - Complete manifests with auto-scaling and monitoring
- **🔄 GitOps** - Automated deployment with staging and production environments

## 🛠️ Technical Details

### Architecture
- **Language**: Rust (backend) + React (frontend)
- **HTTP Client**: migrated from `wreq` to `reqwest` for NixOS compatibility
- **TLS Backend**: `rustls` (replaces BoringSSL)
- **Build System**: Cargo + npm/pnpm
- **Packaging**: Nix flakes with buildRustPackage

### Key Modifications
This package includes several patches to make ClewdR work seamlessly on NixOS:

1. **HTTP Client Migration**: Replaced `wreq` (BoringSSL) with `reqwest` (rustls)
2. **Filesystem Compatibility**: Added environment variable support for data directories
3. **OAuth2 Integration**: Fixed API compatibility between HTTP libraries
4. **Service Integration**: Enhanced directory handling for read-only filesystems

## 🧪 Testing

The package includes comprehensive VM tests:

```bash
# Run all tests
nix flake check

# Run specific VM test
nix build .#checks.x86_64-linux.nixos-vm-test
```

### Test Coverage
- ✅ Service starts and stays running
- ✅ HTTP endpoints are accessible
- ✅ Systemd security settings are properly applied
- ✅ User and group creation
- ✅ Firewall configuration
- ✅ Configuration file generation
- ✅ Service restart and recovery

## 📝 Configuration Options

### Basic Options
```nix
services.clewdr = {
  enable = true;                    # Enable the service
  package = pkgs.clewdr;           # Package to use (default: auto)
  user = "clewdr";                 # Service user (default: clewdr)
  group = "clewdr";                # Service group (default: clewdr)
  dataDir = "/var/lib/clewdr";     # Data directory
  
  # Network settings
  ip = "127.0.0.1";                # Bind IP address
  port = 8484;                     # Port number
  openFirewall = false;            # Open firewall port
  
  # Feature toggles
  checkUpdate = true;              # Check for updates
  autoUpdate = false;              # Auto-update (disabled in service)
  webSearch = false;               # Web search capability
  preserveChats = true;            # Preserve chat history
}
```

### Advanced Configuration
```nix
services.clewdr = {
  # Password management
  passwordFile = "/run/secrets/clewdr-password";
  adminPasswordFile = "/run/secrets/clewdr-admin-password";
  
  # API credentials
  environment = {
    ANTHROPIC_API_KEY = "your-key";
    GOOGLE_AI_API_KEY = "your-key";
    GOOGLE_APPLICATION_CREDENTIALS = "/path/to/service-account.json";
  };
  
  # Raw settings (merged with options above)
  settings = {
    cache_response = 100;
    max_retries = 3;
    # ... any other ClewdR config options
  };
  
  # Extra command line arguments
  extraArgs = [ "--verbose" ];
}
```

## 🐳 Container Deployment

### Docker

```bash
# Build container image
nix build .#container

# Load and run
docker load < result
docker run -p 8484:8484 -e ANTHROPIC_API_KEY=your_key clewdr:latest

# Or use multi-arch build
nix run .#build-multiarch
docker run -p 8484:8484 clewdr:latest-amd64
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/deployment.yaml

# Or use Helm
helm install clewdr k8s/helm-chart/

# GitOps with Kustomize
kubectl apply -k gitops/environments/staging/
kubectl apply -k gitops/environments/production/
```

### Development Utilities

```bash
# All deployment options via dev-utils.sh
./dev-utils.sh deploy docker        # Docker Compose
./dev-utils.sh deploy k8s           # Kubernetes
./dev-utils.sh deploy helm          # Helm chart
./dev-utils.sh deploy staging       # Staging environment
./dev-utils.sh deploy production    # Production environment
```

## 🔌 API Endpoints

Once running, ClewdR exposes several endpoints:

- **Claude/OpenAI format**: `http://127.0.0.1:8484/v1`
- **Claude Code format**: `http://127.0.0.1:8484/code/v1`
- **Gemini format**: `http://127.0.0.1:8484/v1/vertex`
- **Gemini/OpenAI format**: `http://127.0.0.1:8484/gemini`
- **Web Admin Interface**: `http://127.0.0.1:8484/`

## 🔧 Development

### Quick Development Setup

```bash
# Clone the repository
git clone https://github.com/your-username/clewdr-flake
cd clewdr-flake

# Setup development environment
./dev-utils.sh setup

# Start development with auto-rebuild
./dev-utils.sh watch

# Run comprehensive tests
./dev-utils.sh test
```

### Available Applications

```bash
# Development tools
nix run .#dev-watch              # Auto-rebuild on changes
nix run .#dev-env                # Setup development environment

# Testing and quality
nix run .#security-audit         # Security vulnerability scanning
nix run .#test-integration       # Integration testing suite
nix run .#test-ci                # Local CI pipeline testing

# Performance analysis
nix run .#profile cpu            # CPU profiling with perf
nix run .#profile memory         # Memory profiling with valgrind
nix run .#profile flamegraph     # Generate flame graphs
nix run .#bench                  # Performance benchmarking

# Container and deployment
nix run .#container-build        # Build container images
nix run .#build-multiarch        # Multi-architecture builds
nix run .#deploy                 # Container deployment

# Documentation and utilities
nix run .#docs                   # Generate documentation
nix run .#secrets                # Secrets management
```

### Development Shells

```bash
# Full development environment (default)
nix develop                      # Complete toolchain + all utilities

# Specialized environments
nix develop .#minimal            # Essential tools only
nix develop .#pre-commit         # Code quality environment
```

### File Structure
```
├── 📁 Core Configuration
│   ├── flake.nix                # Main flake with 16 applications & 4 shells
│   ├── package.nix              # Package build with reqwest migration
│   ├── module.nix               # NixOS service module
│   └── dev-utils.sh             # Development workflow management
├── 📁 Container & Orchestration
│   ├── k8s/                     # Kubernetes manifests and Helm chart
│   ├── gitops/                  # Kustomize and ArgoCD configurations
│   └── monitoring/              # Prometheus rules and configurations
├── 📁 Development & Testing
│   ├── tests/                   # NixOS VM and performance tests
│   ├── .vscode/                 # IDE configuration and debugging
│   ├── .pre-commit-config.yaml  # Code quality automation
│   └── deny.toml                # Dependency policy enforcement
├── 📁 Documentation
│   ├── README.md                # Main documentation (this file)
│   ├── ENHANCEMENT-SUMMARY.md   # Complete feature overview
│   ├── docs/                    # Additional documentation
│   └── examples/                # Usage examples and configurations
├── 📁 Source & Build
│   ├── upstream-source/         # Patched ClewdR source code
│   ├── source-patches/          # HTTP client compatibility patches
│   └── scripts/                 # CI and verification scripts
└── 📁 Generated (gitignored)
    ├── result*                  # Nix build outputs
    ├── profiles/                # Performance profiling data
    └── docs/book/               # Generated documentation
```

## 🐛 Troubleshooting

### Service won't start
Check the service logs:
```bash
journalctl -u clewdr.service -f
```

### Permission issues
Ensure the data directory is writable:
```bash
sudo chown clewdr:clewdr /var/lib/clewdr
```

### API key issues
Verify environment variables are set:
```bash
systemctl show clewdr.service | grep Environment
```

## 📄 License

This packaging is provided under the same license as the original ClewdR project. See [LICENSE](./LICENSE) for details.

## 🙏 Acknowledgments

- [ClewdR](https://github.com/Xerxes-2/clewdr) - The original project by Xerxes-2
- [NixOS](https://nixos.org/) - The purely functional Linux distribution
- [Nix Flakes](https://nixos.wiki/wiki/Flakes) - The experimental package management system

## 🔗 Links

- [Original ClewdR Repository](https://github.com/Xerxes-2/clewdr)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)  
- [Nix Package Manager](https://nixos.org/manual/nix/stable/)