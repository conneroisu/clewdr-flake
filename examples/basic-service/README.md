# Basic ClewdR Service Example

This example demonstrates the simplest possible ClewdR deployment on NixOS.

## Features Demonstrated

- ✅ Minimal service configuration
- ✅ Basic authentication setup  
- ✅ Firewall integration
- ✅ Environment variable configuration

## Quick Start

```bash
# Build the system
nix build .#nixosConfigurations.example.config.system.build.toplevel

# Test with VM
nix build .#checks.x86_64-linux.vm-test

# Deploy (on actual NixOS system)
sudo nixos-rebuild switch --flake .#example
```

## Configuration Highlights

```nix
services.clewdr = {
  enable = true;
  ip = "0.0.0.0";         # Listen on all interfaces
  port = 8484;            # Default ClewdR port
  
  settings = {
    password = "demo-password";
    admin_password = "demo-admin-password";
  };
  
  openFirewall = true;    # Automatically open firewall
};
```

## Testing the Service

After deployment, you can test the service:

```bash
# Check service status
systemctl status clewdr

# Test API endpoint
curl http://localhost:8484/v1/models

# Access web interface
open http://localhost:8484/
```

## Security Note

⚠️ **This example uses demo passwords for illustration purposes only.**  
In production, use proper secret management:

```nix
services.clewdr = {
  passwordFile = "/run/secrets/clewdr-password";
  adminPasswordFile = "/run/secrets/clewdr-admin-password";
  
  environment = {
    ANTHROPIC_API_KEY_FILE = "/run/secrets/anthropic-key";
  };
};
```