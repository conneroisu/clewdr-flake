# Development Guide

This document provides detailed information for developers working on the ClewdR NixOS package.

## 🏗️ Architecture Overview

### Project Structure

```
clewdr-flake/
├── flake.nix                 # Main flake definition
├── package.nix               # Package build specification
├── module.nix                # NixOS service module
├── nixos-test.nix            # VM integration tests
├── clewdr-source/            # Patched ClewdR source code
│   ├── Cargo.toml           # Modified dependencies (wreq → reqwest)
│   ├── src/                 # Rust source with compatibility patches
│   └── frontend/            # React web interface
├── source-patches/          # Patch files for source modifications
├── development-notes/       # Development artifacts and scripts
└── docs/                    # Documentation
```

### Key Components

1. **Flake Infrastructure** (`flake.nix`)
   - Package outputs for multiple platforms
   - NixOS module exports
   - Development shell with all dependencies
   - Integration test definitions

2. **Package Definition** (`package.nix`)  
   - Rust backend build with `buildRustPackage`
   - React frontend build with Node.js/pnpm
   - Static asset bundling and installation
   - Cross-platform compatibility handling

3. **Service Module** (`module.nix`)
   - Complete NixOS service configuration
   - Security-hardened systemd service
   - User/group management
   - Configuration file generation

4. **Testing Suite** (`nixos-test.nix`)
   - VM-based integration testing
   - Service lifecycle validation
   - HTTP endpoint testing
   - Security configuration verification

## 🔧 Development Workflow

### Setting Up Development Environment

```bash
# Clone and enter the repository
git clone <repository-url>
cd clewdr-flake

# Enter development shell (provides all dependencies)
nix develop

# Verify development environment
rustc --version
node --version
pnpm --version
```

### Building and Testing

```bash
# Build the package
nix build .#clewdr

# Run comprehensive tests
nix flake check

# Run specific VM test
nix build .#checks.x86_64-linux.nixos-vm-test

# Build for different platforms
nix build .#packages.aarch64-linux.clewdr
nix build .#packages.x86_64-darwin.clewdr
```

### Local Development

```bash
# Enter development shell
nix develop

# Work on source code
cd clewdr-source

# Build locally for testing
cargo build --release

# Run locally (requires configuration)
./target/release/clewdr --config /path/to/config.toml
```

## 🔄 Dependency Migration Details

### HTTP Client Migration: wreq → reqwest

The major technical challenge was migrating from the `wreq` HTTP client to `reqwest`:

#### Original Dependencies (BoringSSL-based)
```toml
[dependencies]
wreq = "0.2"
wreq-util = "0.1"
```

#### Migrated Dependencies (rustls-based)
```toml
[dependencies]
reqwest = { version = "0.12", features = [
    "json", "stream", "multipart", "socks", 
    "cookies", "charset", "rustls-tls"
], default-features = false }
```

#### API Compatibility Issues Resolved

1. **HTTP Request/Response Types**
   - `wreq::Request` → `reqwest::Request`
   - Field access patterns updated for privacy
   - Method call chains converted

2. **OAuth2 Integration**
   - `HttpClientError` type compatibility
   - Error handling and conversion
   - Async/await pattern alignment

3. **Cookie Management**
   - Cookie jar implementation differences
   - Header handling variations
   - Session persistence patterns

### Filesystem Compatibility

Enhanced `src/utils/mod.rs` with NixOS-aware directory handling:

```rust
pub fn set_clewdr_dir() -> Result<PathBuf, ClewdrError> {
    let dir = if *IS_DEV {
        // Development: use cargo manifest directory
        let cargo_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        cargo_dir.canonicalize()?
    } else {
        // Production: check environment overrides first
        if let Ok(env_dir) = std::env::var("CLEWDR_DIR") {
            PathBuf::from(env_dir)
        } else if let Ok(env_dir) = std::env::var("CLEWDR_DATA_DIR") {
            PathBuf::from(env_dir)
        } else {
            // Fallback to executable directory
            std::env::current_exe()?.parent()?.canonicalize()?.to_path_buf()
        }
    };
    
    // Handle read-only filesystem gracefully
    if let Err(_) = std::env::set_current_dir(&dir) {
        eprintln!("Warning: Could not change to directory {}, using current directory", dir.display());
    }
    
    Ok(dir)
}
```

## 🧪 Testing Strategy

### Test Levels

1. **Unit Tests**: Rust code testing within the source
2. **Integration Tests**: NixOS VM testing with real service
3. **Cross-platform Tests**: Multi-architecture builds
4. **Security Tests**: Systemd service configuration validation

### VM Test Coverage

The VM tests verify:

- Service lifecycle (start, stop, restart)
- Network binding and HTTP responses
- User/group creation and permissions
- Systemd security settings
- Configuration file generation
- Firewall rule application
- Service recovery after failures

### Debugging Test Failures

```bash
# Get detailed test logs
nix log /nix/store/<test-derivation-path>

# Run test with verbose output
nix build .#checks.x86_64-linux.nixos-vm-test --show-trace

# Access VM interactively for debugging
nix build .#checks.x86_64-linux.nixos-vm-test.driver
./result/bin/nixos-test-driver
```

## 🔐 Security Considerations

### Systemd Service Hardening

The service module implements security best practices:

```nix
serviceConfig = {
  # Process restrictions
  NoNewPrivileges = true;
  ProtectSystem = "full";
  ProtectHome = true;
  PrivateTmp = true;
  PrivateDevices = true;
  
  # Network restrictions  
  RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
  
  # Filesystem restrictions
  ReadWritePaths = [ cfg.dataDir ];
  WorkingDirectory = cfg.dataDir;
  
  # Process properties
  User = cfg.user;
  Group = cfg.group;
};
```

### Secret Management

API keys and passwords should be managed securely:

```nix
services.clewdr = {
  # Use password files instead of direct strings
  passwordFile = "/run/secrets/clewdr-password";
  adminPasswordFile = "/run/secrets/clewdr-admin-password";
  
  # Environment variables for API keys
  environment = {
    ANTHROPIC_API_KEY = "your-key"; # Consider using sops-nix or agenix
  };
};
```

## 📝 Code Style and Conventions

### Nix Code Style
- Use 2-space indentation
- Prefer explicit attribute sets
- Use meaningful variable names
- Add comments for complex logic
- Follow nixos-unstable conventions

### Rust Code Style
- Follow standard Rust formatting (rustfmt)
- Use explicit error handling
- Prefer owned types for clarity
- Document public APIs
- Handle filesystem errors gracefully

### Documentation Standards
- Use clear, concise language
- Provide practical examples
- Include troubleshooting guides
- Keep README up-to-date
- Document breaking changes

## 🚀 Release Process

### Version Management
1. Update version in `package.nix`
2. Update changelog with new features
3. Tag release with semantic versioning
4. Update documentation examples

### Testing Checklist
- [ ] All platforms build successfully
- [ ] VM tests pass
- [ ] Manual service testing
- [ ] Documentation accuracy
- [ ] Security review

### Release Artifacts
- Source code with patches
- Built packages for all platforms
- NixOS module
- Comprehensive test results
- Updated documentation

## 🔮 Future Development

### Planned Improvements
- Enhanced security options
- Better secret management integration
- Performance optimization flags
- Additional configuration validation
- Monitoring and logging improvements

### Contributing Guidelines
- Follow existing code patterns
- Add tests for new features
- Update documentation
- Ensure cross-platform compatibility
- Verify security implications