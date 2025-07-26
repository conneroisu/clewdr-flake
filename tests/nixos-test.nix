{ pkgs, clewdrPackage, clewdrModule }:

pkgs.nixosTest {
  name = "clewdr";

  nodes.machine = { config, pkgs, ... }: {
    imports = [ clewdrModule ];

    # Enable the clewdr service with basic configuration
    services.clewdr = {
      enable = true;
      package = clewdrPackage;
      
      # Basic configuration
      ip = "127.0.0.1";
      port = 8100;
      
      # Basic settings
      settings = {
        password = "test-password";
        admin_password = "test-admin-password";
        check_update = false;
        auto_update = false;
      };
      
      # Set required environment variables for testing
      environment = {
        ANTHROPIC_API_KEY = "sk-test-key-for-testing";
        GOOGLE_AI_API_KEY = "test-google-key";
      };
      
      # Allow access from test client
      openFirewall = true;  
    };

    # Configure nixpkgs for testing (remove allowUnfree as it's not needed here)
    
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
    
    # Verify the service responds to HTTP requests (but expect 404 for root path)
    machine.succeed("curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8100/ | grep -E '^(200|404)$'")
    
    # Check systemd service status and logs
    machine.succeed("systemctl status clewdr")
    
    # Verify the service is actually running and bound to the port
    machine.succeed("ss -tlnp | grep ':8100'")
    
    # Check that the service has not crashed and is not restarting
    machine.succeed("! systemctl is-failed clewdr")
    
    # Check that the service user was created
    machine.succeed("id clewdr")
    
    # Verify systemd service security settings are applied
    service_status = machine.succeed("systemctl show clewdr.service")
    assert "PrivateTmp=yes" in service_status
    assert "ProtectSystem=full" in service_status  # Changed from strict to full for filesystem compatibility
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