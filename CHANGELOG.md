# Changelog

All notable changes to the ClewdR NixOS package and module will be documented in this file.

## [1.0.0] - 2025-01-25

### 🚀 Initial Release

**Complete NixOS packaging of ClewdR v0.10.9 with full compatibility**

### ✨ Features Added

#### Package Infrastructure
- **Full NixOS flake** with package and module definitions
- **Cross-platform support** for x86_64 and aarch64 Linux/macOS  
- **Rust backend + React frontend** complete build pipeline
- **Development shell** with all required dependencies

#### NixOS Service Module
- **Comprehensive service module** with all ClewdR configuration options
- **Security hardened systemd service** with appropriate restrictions
- **Automatic user/group management** with proper permissions
- **Firewall integration** with optional port opening
- **Environment variable management** for API keys and secrets
- **Data directory handling** with proper ownership and permissions

#### Testing & Validation
- **Comprehensive VM test suite** with full integration testing
- **Service lifecycle testing** (start, stop, restart, recovery)
- **HTTP endpoint validation** and connectivity testing
- **Security settings verification** for systemd service
- **Configuration file generation testing**

### 🔧 Technical Improvements

#### Dependency Migration
- **HTTP client migration**: Replaced `wreq` (BoringSSL) with `reqwest` (rustls)
- **TLS backend switch**: BoringSSL → rustls for better NixOS compatibility
- **OAuth2 integration**: Fixed API compatibility between HTTP libraries
- **Error handling updates**: Proper error type conversions and handling

#### Filesystem Compatibility  
- **Read-only filesystem support**: Enhanced directory handling for Nix store
- **Environment variable overrides**: Added `CLEWDR_DIR` and `CLEWDR_DATA_DIR` support
- **Graceful fallback**: Safe handling when executable directory is read-only
- **Working directory management**: Proper current directory handling

#### Build System Enhancements
- **Cargo dependency management**: Updated Cargo.toml with compatible versions
- **Frontend build integration**: Proper React build pipeline in Nix
- **Static asset handling**: Correct packaging of web UI resources
- **Cross-compilation support**: Multi-architecture build compatibility

### 📋 Configuration Options

#### Basic Service Options
- `enable` - Enable/disable the service
- `package` - Package version to use  
- `user`/`group` - Service user/group configuration
- `dataDir` - Data directory location
- `ip`/`port` - Network binding configuration
- `openFirewall` - Automatic firewall rule management

#### Advanced Configuration
- `passwordFile`/`adminPasswordFile` - Secure password management
- `environment` - Environment variable configuration
- `settings` - Raw ClewdR configuration passthrough
- `extraArgs` - Additional command-line arguments

#### Feature Toggles
- `checkUpdate`/`autoUpdate` - Update behavior control
- `webSearch` - Web search capability
- `preserveChats` - Chat history preservation
- `vertexAI` - Google Vertex AI integration

### 🧪 Test Coverage

#### Service Integration Tests
- ✅ Service starts and stays running
- ✅ HTTP endpoints respond correctly
- ✅ Port binding and network accessibility  
- ✅ Service restart and recovery behavior
- ✅ User and group creation

#### Security & Configuration Tests
- ✅ Systemd security settings application
- ✅ Filesystem permissions and ownership
- ✅ Environment variable handling
- ✅ Configuration file generation
- ✅ Firewall rule creation

#### Compatibility Tests
- ✅ Cross-platform build verification
- ✅ Dependency resolution and linking
- ✅ Frontend asset serving
- ✅ API endpoint functionality

### 🔄 Migration Details

#### From Original ClewdR
This package includes several compatibility patches:

1. **HTTP Client**: `wreq` → `reqwest` migration with API compatibility fixes
2. **TLS Backend**: BoringSSL → rustls for NixOS compatibility  
3. **Directory Handling**: Added environment variable overrides for data directories
4. **OAuth2 Integration**: Fixed type compatibility between HTTP request/response types
5. **Filesystem Awareness**: Enhanced handling of read-only filesystems

#### Breaking Changes
- None (first release)

### 📦 Dependencies

#### Runtime Dependencies
- `reqwest` with rustls-tls feature
- `tokio` async runtime
- `axum` web framework
- `serde` serialization
- Standard Rust/Node.js ecosystem packages

#### Build Dependencies  
- Rust toolchain (stable)
- Node.js and pnpm
- pkg-config, cmake
- OpenSSL development headers

### 🐛 Known Issues
- Configuration save attempts to read-only filesystem (non-fatal warning)
- Some systemd security restrictions relaxed for filesystem compatibility

## [2.0.0] - 2025-01-26

### 🚀 Comprehensive Platform Release

**Major expansion from simple package to comprehensive development and deployment platform**

### ✨ New Platform Features

#### Container & Orchestration (🐳)
- **Docker Images**: Layered and OCI-compatible container builds with multi-architecture support
- **Kubernetes**: Production-ready deployment manifests with security hardening and auto-scaling
- **Helm Chart**: Complete Helm chart with configurable values and environment management
- **Multi-Architecture**: Cross-platform container builds for AMD64 and ARM64

#### GitOps & Automation (🔄)
- **Kustomize**: Environment-specific configurations for staging and production
- **ArgoCD**: Complete GitOps automation with continuous deployment
- **Network Security**: Production-ready network policies and service monitoring
- **CI/CD Integration**: Local testing with act and comprehensive pipeline validation

#### Advanced Development (🛠️)
- **16 Applications**: Comprehensive workflow management (up from 1)
- **4 Development Shells**: Full, minimal, and pre-commit environments  
- **Performance Profiling**: CPU, memory, and flame graph analysis tools
- **Integration Testing**: Comprehensive test framework with automated validation

#### Monitoring & Observability (📊)
- **Prometheus Integration**: Custom metrics and alerting rules for ClewdR
- **Performance Benchmarking**: Automated performance testing and analysis
- **Health Monitoring**: Service monitoring for Kubernetes deployments
- **Security Auditing**: Dependency scanning and license compliance

#### Developer Experience (🔧)
- **VS Code Integration**: Complete workspace with debugging and task configuration
- **Pre-commit Hooks**: Automated code quality enforcement and security scanning
- **Development Utils**: 13-command workflow management script
- **IDE Support**: Debugging configurations and intelligent code completion

### 📊 Platform Statistics
- **Applications**: 1 → 16 (1500% increase)
- **Development Shells**: 1 → 4 specialized environments
- **Checks**: 2 → 14 comprehensive validations
- **Deployment Methods**: 3 → 7 deployment targets
- **File Structure**: Organized into logical directory hierarchy

### 🔧 Enhanced Applications

#### Development Tools
- `dev-watch` - Auto-rebuild on code changes with cargo-watch
- `dev-env` - Complete development environment setup automation
- `security-audit` - Comprehensive vulnerability and policy scanning
- `test-integration` - Full integration testing with server lifecycle management

#### Performance & Analysis  
- `profile` - Multi-mode profiling (CPU, memory, flamegraph, benchstat)
- `bench` - Performance benchmarking with wrk and hyperfine
- `test-ci` - Local CI pipeline testing with GitHub Actions simulation

#### Container & Deployment
- `container-build` - Docker image building with registry push support
- `build-multiarch` - Multi-architecture container builds
- `deploy` - Unified deployment interface (Docker, K8s, Helm, GitOps)

#### Utilities & Documentation
- `docs` - Documentation generation with mdbook integration
- `secrets` - Secrets management with sops and age encryption

### 🔒 Security Enhancements
- **Container Security**: Non-root execution and read-only filesystems
- **Network Policies**: Kubernetes network isolation and traffic control
- **Secrets Management**: Encrypted secrets with sops-nix integration
- **Dependency Auditing**: Automated vulnerability scanning and license compliance
- **Code Quality**: Pre-commit hooks preventing security issues

### 📁 Repository Organization
Restructured repository with logical directory hierarchy:
- **Core Configuration**: `flake.nix`, `package.nix`, `module.nix`, `dev-utils.sh`
- **Container & Orchestration**: `k8s/`, `gitops/`, `monitoring/`
- **Development & Testing**: `tests/`, `.vscode/`, quality automation files
- **Documentation**: Comprehensive guides and examples
- **Build Artifacts**: Organized in `scripts/` and proper gitignore

### 🔮 Future Plans
- Multi-cloud deployment support
- Advanced monitoring and alerting integrations  
- Extended IDE integrations (JetBrains, Emacs, Vim)
- Performance optimization and caching strategies

---

**Full Changelog**: https://github.com/your-username/clewdr-flake/commits/v2.0.0