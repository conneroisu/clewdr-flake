# ClewdR NixOS Package & Module

A complete NixOS flake providing a package and service module for [ClewdR](https://github.com/Xerxes-2/clewdr) - a high-performance LLM proxy for Claude and Google Gemini.

## 🚀 Quick Start

### Using the Flake

```bash
# Build the package
nix build github:your-username/clewdr-flake#clewdr

# Run directly
nix run github:your-username/clewdr-flake#clewdr

# Enter development shell
nix develop github:your-username/clewdr-flake
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

### Package Features
- ✅ **Full NixOS compatibility** - Properly packaged with all dependencies
- ✅ **Rust + React frontend** - Complete build of both backend and web UI
- ✅ **Cross-platform support** - Works on x86_64 and aarch64 Linux/macOS
- ✅ **TLS security** - Uses rustls instead of BoringSSL for better compatibility
- ✅ **Filesystem-aware** - Respects NixOS read-only store and service directories

### NixOS Module Features
- 🔒 **Security hardened** - Systemd service with appropriate restrictions
- 🔧 **Fully configurable** - All ClewdR options exposed as NixOS options
- 👤 **User management** - Automatic service user and group creation
- 🔥 **Firewall integration** - Optional automatic firewall rule configuration
- 📁 **Data directory management** - Proper handling of configuration and logs
- 🔐 **Secret management** - Secure handling of API keys via environment files

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

## 🔌 API Endpoints

Once running, ClewdR exposes several endpoints:

- **Claude/OpenAI format**: `http://127.0.0.1:8484/v1`
- **Claude Code format**: `http://127.0.0.1:8484/code/v1`
- **Gemini format**: `http://127.0.0.1:8484/v1/vertex`
- **Gemini/OpenAI format**: `http://127.0.0.1:8484/gemini`
- **Web Admin Interface**: `http://127.0.0.1:8484/`

## 🔧 Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/your-username/clewdr-flake
cd clewdr-flake

# Enter development environment
nix develop

# Build the package
nix build .#clewdr

# Run tests
nix flake check
```

### File Structure
```
├── flake.nix                    # Main flake definition
├── package.nix                  # Package build configuration  
├── module.nix                   # NixOS service module
├── README.md                    # Main documentation
├── CHANGELOG.md                 # Release history
├── LICENSE                      # License information
├── tests/
│   └── nixos-test.nix          # VM integration tests
├── upstream-source/
│   └── clewdr-source/          # Patched ClewdR source code
├── source-patches/             # Compatibility patches
├── docs/                       # Additional documentation
├── development-notes/          # Development artifacts
└── build-artifacts/            # Build-related files
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