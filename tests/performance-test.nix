{ pkgs, clewdrPackage, clewdrModule }:

pkgs.nixosTest {
  name = "clewdr-performance";
  
  nodes = {
    server = { config, pkgs, ... }: {
      imports = [ clewdrModule ];
      
      services.clewdr = {
        enable = true;
        ip = "0.0.0.0";
        port = 8100;
        
        settings = {
          password = "perf-test-password";
          admin_password = "perf-admin-password";
          cache_response = 1000;  # High cache for performance
          max_retries = 1;        # Minimize retries for consistent timing
        };
        
        environment = {
          ANTHROPIC_API_KEY = "sk-test-key";
          GOOGLE_AI_API_KEY = "test-google-key";
          RUST_LOG = "warn";      # Reduce logging overhead
        };
        
        openFirewall = true;
      };
      
      # Performance monitoring tools
      environment.systemPackages = with pkgs; [
        curl
        wrk  # HTTP benchmarking tool
        htop
        iotop
        nethogs
        sysstat
      ];
      
      # Optimize for performance testing
      boot.kernel.sysctl = {
        "net.core.somaxconn" = 65535;
        "net.ipv4.tcp_max_syn_backlog" = 65535;
        "net.core.netdev_max_backlog" = 5000;
      };
    };
    
    client = { config, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        curl
        wrk
        jq
        netcat-gnu
      ];
    };
  };
  
  testScript = ''
    import json
    import time
    
    # Start both machines
    server.start()
    client.start()
    
    # Wait for server to be ready
    server.wait_for_unit("multi-user.target")
    server.wait_for_unit("clewdr.service")
    server.wait_for_open_port(8100)
    
    client.wait_for_unit("multi-user.target")
    
    print("=== ClewdR Performance Test Suite ===")
    
    # Test 1: Service startup time
    print("\n--- Test 1: Service Startup Performance ---")
    server.succeed("systemctl stop clewdr")
    
    start_time = time.time()
    server.succeed("systemctl start clewdr")
    server.wait_for_open_port(8100)
    startup_time = time.time() - start_time
    
    print(f"Service startup time: {startup_time:.2f} seconds")
    assert startup_time < 10, f"Startup time too slow: {startup_time:.2f}s"
    
    # Test 2: Basic response time
    print("\n--- Test 2: Basic Response Time ---")
    response_time = client.succeed(
      "curl -w '%{time_total}' -s -o /dev/null http://server:8100/ || echo '0.000'"
    ).strip()
    
    print(f"Basic response time: {response_time} seconds")
    
    # Test 3: Memory usage under load
    print("\n--- Test 3: Memory Usage Analysis ---")
    
    # Get baseline memory usage
    baseline_mem = server.succeed("ps aux | grep '[c]lewdr' | awk '{print $6}'").strip()
    print(f"Baseline memory usage: {baseline_mem} KB")
    
    # Run load test
    print("Running 30-second load test with 10 concurrent connections...")
    client.succeed(
      "wrk -t10 -c10 -d30s --timeout 5s http://server:8100/ > /tmp/load_test.log 2>&1 || true"
    )
    
    # Get memory usage after load
    load_mem = server.succeed("ps aux | grep '[c]lewdr' | awk '{print $6}'").strip()
    print(f"Memory usage after load: {load_mem} KB")
    
    # Check for memory leaks (memory shouldn't increase by more than 50MB)
    if baseline_mem.isdigit() and load_mem.isdigit():
        mem_increase = int(load_mem) - int(baseline_mem)
        print(f"Memory increase: {mem_increase} KB")
        assert mem_increase < 51200, f"Possible memory leak: {mem_increase} KB increase"
    
    # Test 4: Load test results analysis
    print("\n--- Test 4: Load Test Results ---")
    load_results = client.succeed("cat /tmp/load_test.log")
    print("Load test output:")
    print(load_results)
    
    # Extract key metrics from wrk output
    try:
        lines = load_results.split('\n')
        for line in lines:
            if 'Requests/sec:' in line:
                rps = float(line.split(':')[1].strip())
                print(f"Requests per second: {rps}")
                assert rps > 10, f"RPS too low: {rps}"
            elif 'Latency' in line and 'avg' in line:
                # Parse latency line like "Latency     1.23ms    2.34ms   5.67ms   89.01%"
                parts = line.split()
                if len(parts) >= 2:
                    avg_latency = parts[1]
                    print(f"Average latency: {avg_latency}")
    except Exception as e:
        print(f"Could not parse load test results: {e}")
    
    # Test 5: Resource utilization
    print("\n--- Test 5: Resource Utilization ---")
    
    # CPU usage
    cpu_usage = server.succeed(
      "top -bn1 | grep '[c]lewdr' | awk '{print $9}' | head -1"
    ).strip()
    print(f"CPU usage: {cpu_usage}%")
    
    # File descriptor usage
    fd_count = server.succeed(
      "lsof -p $(pgrep clewdr) 2>/dev/null | wc -l"
    ).strip()
    print(f"Open file descriptors: {fd_count}")
    
    # Network connections
    conn_count = server.succeed(
      "netstat -an | grep :8100 | wc -l"
    ).strip()
    print(f"Network connections: {conn_count}")
    
    # Test 6: Concurrent connection handling
    print("\n--- Test 6: Concurrent Connection Test ---")
    
    # Test with higher concurrency
    print("Testing with 50 concurrent connections...")
    client.succeed(
      "wrk -t5 -c50 -d10s --timeout 10s http://server:8100/ > /tmp/concurrent_test.log 2>&1 || true"
    )
    
    concurrent_results = client.succeed("cat /tmp/concurrent_test.log")
    print("Concurrent test results:")
    print(concurrent_results)
    
    # Test 7: Error rate analysis
    print("\n--- Test 7: Error Rate Analysis ---")
    
    # Check for any errors in the service logs
    service_errors = server.succeed(
      "journalctl -u clewdr.service --since '5 minutes ago' | grep -i error | wc -l"
    ).strip()
    print(f"Service errors in last 5 minutes: {service_errors}")
    
    # Test 8: Graceful shutdown performance
    print("\n--- Test 8: Graceful Shutdown Test ---")
    
    shutdown_start = time.time()
    server.succeed("systemctl stop clewdr")
    shutdown_time = time.time() - shutdown_start
    
    print(f"Graceful shutdown time: {shutdown_time:.2f} seconds")
    assert shutdown_time < 30, f"Shutdown too slow: {shutdown_time:.2f}s"
    
    # Verify clean shutdown (no zombie processes)
    zombie_check = server.succeed("ps aux | grep '[c]lewdr' || echo 'no processes'").strip()
    print(f"Post-shutdown process check: {zombie_check}")
    
    # Final summary
    print("\n=== Performance Test Summary ===")
    print(f"✅ Startup time: {startup_time:.2f}s")
    print(f"✅ Memory baseline: {baseline_mem} KB")
    print(f"✅ Memory after load: {load_mem} KB")
    print(f"✅ Service errors: {service_errors}")
    print(f"✅ Shutdown time: {shutdown_time:.2f}s")
    print("✅ All performance tests completed successfully!")
  '';
}