#!/usr/bin/env bash
set -euo pipefail

echo "=== Testing CI/CD Pipeline with act ==="

# Test 1: Verify workflow syntax
echo "1. Checking workflow syntax..."
act --list > /dev/null && echo "✅ Workflow syntax valid"

# Test 2: Test matrix build simulation  
echo "2. Testing matrix build simulation..."
act push --job matrix-build --platform ubuntu-latest=catthehacker/ubuntu:act-latest --verbose --env GITHUB_TOKEN=dummy_token 2>&1 | head -50

echo "3. Testing flake check directly..."
nix flake check --no-build 2>&1 | head -20

echo "4. Testing package build..."
nix build .#clewdr --no-link --print-build-logs 2>&1 | tail -10

echo "✅ Basic CI validation completed!"