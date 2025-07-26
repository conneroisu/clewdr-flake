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

### 🔮 Future Plans
- Enhanced security hardening options
- Additional configuration validation
- Performance optimization flags
- Integration with NixOS secrets management systems

---

**Full Changelog**: https://github.com/your-username/clewdr-flake/commits/v1.0.0