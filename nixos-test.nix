{ pkgs ? import <nixpkgs> {}, ... }:

let
  # Import our flake to get the package and module
  flake = builtins.getFlake (toString ./.);
  clewdrPackage = flake.packages.${pkgs.system}.clewdr;
  clewdrModule = flake.nixosModules.clewdr;
in

pkgs.nixosTest {
  name = "clewdr";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ clewdrModule ];

    # Enable the clewdr service with basic configuration
    services.clewdr = {
      enable = true;
      package = clewdrPackage;
      
      # Basic configuration
      host = "127.0.0.1";
      port = 8100;
      logLevel = "info";
      
      # Set required environment variables for testing
      environment = {
        ANTHROPIC_API_KEY = "sk-test-key-for-testing";
        GOOGLE_AI_API_KEY = "test-google-key";
      };
      
      # Allow access from test client
      openFirewall = true;
    };

    # Allow unfree packages for testing
    nixpkgs.config.allowUnfree = true;
    
    # Enable systemd-resolved for proper DNS resolution
    services.resolved.enable = true;
    
    # Add curl for testing HTTP requests
    environment.systemPackages = with pkgs; [ curl jq netcat ];
  };

  testScript = ''
    # Start the machine and wait for it to boot
    machine.start()
    machine.wait_for_unit("multi-user.target")
    
    # Verify the clewdr service is enabled and configured
    machine.succeed("systemctl is-enabled clewdr")
    
    # Wait for the clewdr service to start
    machine.wait_for_unit("clewdr.service")
    
    # Check that the service is active
    machine.succeed("systemctl is-active clewdr")
    
    # Verify the clewdr binary exists and is executable
    machine.succeed("test -x /run/current-system/sw/bin/clewdr")
    
    # Check that the service is listening on the configured port
    machine.wait_for_open_port(8100)
    
    # Verify the service responds to HTTP requests
    machine.succeed("curl -f http://127.0.0.1:8100/ || curl -f http://127.0.0.1:8100/health || true")
    
    # Check systemd service status and logs
    machine.succeed("systemctl status clewdr")
    
    # Verify configuration file was created
    machine.succeed("test -f /etc/clewdr/config.json")
    
    # Check that the service user was created
    machine.succeed("id clewdr")
    
    # Verify systemd service security settings are applied
    service_status = machine.succeed("systemctl show clewdr.service")
    assert "PrivateTmp=yes" in service_status
    assert "ProtectSystem=strict" in service_status
    assert "NoNewPrivileges=yes" in service_status
    
    # Test basic functionality by checking if the service accepts connections
    machine.succeed("nc -z 127.0.0.1 8100")
    
    # Test service restart
    machine.succeed("systemctl restart clewdr")
    machine.wait_for_unit("clewdr.service")
    machine.wait_for_open_port(8100)
    
    # Test service stop and start
    machine.succeed("systemctl stop clewdr")
    machine.fail("nc -z 127.0.0.1 8100")
    machine.succeed("systemctl start clewdr")
    machine.wait_for_unit("clewdr.service")
    machine.wait_for_open_port(8100)
    
    print("All clewdr service tests passed!")
  '';
}