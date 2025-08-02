# Contributing to ClewdR Flake

Thank you for your interest in contributing to the ClewdR Flake project! This document provides guidelines for contributing to the Nix flake packaging for ClewdR.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project follows a professional and respectful code of conduct. All contributors are expected to:

- Be respectful and inclusive in all interactions
- Focus on constructive feedback and collaboration
- Maintain a professional tone in discussions
- Help create a welcoming environment for all contributors

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/) with flakes support enabled
- Git for version control
- Basic understanding of Nix expressions and flakes

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/your-username/clewdr-flake.git
   cd clewdr-flake
   ```

## Development Setup

### Quick Setup

```bash
# Initialize development environment
nix run .#dev-env

# Enter development shell
nix develop

# Start development with auto-rebuild
./dev-utils.sh watch
```

### Development Shells

- **Full Environment**: `nix develop` - Complete toolchain with all utilities
- **Minimal Environment**: `nix develop .#minimal` - Essential tools only

### Available Development Tools

- `./dev-utils.sh setup` - Initialize development environment
- `./dev-utils.sh watch` - Auto-rebuild on changes
- `./dev-utils.sh test` - Run comprehensive tests
- `./dev-utils.sh lint` - Code formatting and linting
- `./dev-utils.sh security` - Security audit and vulnerability scanning

## Contributing Guidelines

### Areas for Contribution

1. **Package Improvements**
   - Bug fixes in the Nix package definition
   - Performance optimizations
   - Dependency updates

2. **Module Enhancements**
   - New configuration options for the NixOS module
   - Security hardening improvements
   - Service reliability features

3. **Container Support**
   - Docker image optimizations
   - Kubernetes manifest improvements
   - Multi-architecture build enhancements

4. **Development Tools**
   - New development utilities
   - CI/CD pipeline improvements
   - Testing framework enhancements

5. **Documentation**
   - Usage examples
   - Configuration guides
   - Troubleshooting documentation

### What We're Looking For

- **Bug Reports**: Clear reproduction steps and expected behavior
- **Feature Requests**: Well-motivated use cases with implementation suggestions
- **Code Contributions**: Clean, tested, and documented changes
- **Documentation**: Clear, accurate, and helpful content

## Pull Request Process

### Before Submitting

1. **Test Your Changes**
   ```bash
   # Run all checks
   nix flake check
   
   # Test the package builds
   nix build .#clewdr
   
   # Test NixOS module (if applicable)
   nix build .#checks.x86_64-linux.nixos-vm-test
   ```

2. **Run Security Checks**
   ```bash
   nix run .#security-audit
   ```

3. **Verify Documentation**
   ```bash
   # Generate and review documentation
   nix run .#docs
   ```

### Submitting Your PR

1. **Create a Clear Title**
   - Use conventional commit format: `type(scope): description`
   - Examples: `fix(package): resolve reqwest compatibility issue`
   - Examples: `feat(module): add new configuration option`

2. **Write a Detailed Description**
   - Explain what the change does and why
   - Reference any related issues
   - Include testing steps if applicable

3. **Keep Changes Focused**
   - One feature or fix per PR
   - Separate refactoring from feature changes
   - Keep commits logical and atomic

### PR Review Process

1. Automated checks will run (CI, security scanning, tests)
2. Maintainers will review the code and design
3. Address any feedback or requested changes
4. Once approved, the PR will be merged

## Code Style

### Nix Code Style

- Use 2-space indentation
- Keep lines under 100 characters where reasonable
- Use descriptive variable names
- Add comments for complex logic
- Follow nixpkgs conventions

### Example Nix Code

```nix
{
  # Good: Clear, well-documented configuration
  services.clewdr = {
    enable = true;
    port = 8484;
    
    # API credentials from secure sources
    environment = {
      ANTHROPIC_API_KEY = config.age.secrets.anthropic-key.path;
    };
    
    # Security hardening options
    settings = {
      check_update = false;  # Disable in production
      auto_update = false;   # Prevent automatic updates
    };
  };
}
```

### Shell Scripts

- Use `#!/usr/bin/env bash`
- Include error handling with `set -euo pipefail`
- Add descriptive comments
- Follow shellcheck recommendations

## Testing

### Required Tests

All contributions should include appropriate tests:

1. **Package Tests**
   ```bash
   # Verify package builds correctly
   nix build .#clewdr
   ```

2. **Module Tests**
   ```bash
   # Test NixOS module functionality
   nix build .#checks.x86_64-linux.nixos-vm-test
   ```

3. **Integration Tests**
   ```bash
   # Run integration test suite
   nix run .#test-integration
   ```

### Test Categories

- **Build Tests**: Ensure packages build successfully
- **VM Tests**: Verify NixOS module functionality
- **Security Tests**: Check for vulnerabilities and compliance
- **Performance Tests**: Validate performance characteristics

### Running Tests Locally

```bash
# Run all tests
nix flake check

# Run specific test categories
nix build .#checks.x86_64-linux.build
nix build .#checks.x86_64-linux.security-audit
nix build .#checks.x86_64-linux.container-build
```

## Documentation

### Documentation Standards

- Write clear, concise documentation
- Include practical examples
- Test all code examples
- Keep documentation up-to-date with changes

### Documentation Types

1. **Code Comments**: Explain complex logic and design decisions
2. **Configuration Examples**: Show real-world usage patterns
3. **Troubleshooting Guides**: Help users solve common problems
4. **API Documentation**: Document all configuration options

### Building Documentation

```bash
# Generate documentation
nix run .#docs

# Serve documentation locally
mdbook serve docs/
```

## Release Process

Maintainers handle releases, but contributors should:

1. Update version numbers where appropriate
2. Add entries to CHANGELOG.md for significant changes
3. Ensure all tests pass before requesting release

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bug Reports**: Create a GitHub Issue
- **Feature Requests**: Open a GitHub Issue with the "enhancement" label
- **Security Issues**: Email maintainers privately

## Recognition

All contributors will be recognized in:
- Git commit history
- Release notes for significant contributions
- Project documentation

Thank you for contributing to make ClewdR more accessible on NixOS! 🚀