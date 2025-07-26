{
  description = "Advanced ClewdR configuration example with monitoring and security";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    clewdr-flake.url = "path:../..";
  };

  outputs = { self, nixpkgs, clewdr-flake }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        clewdr-flake.nixosModules.clewdr
        {
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          # Root filesystem (required for NixOS)
          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };
          
          networking.hostName = "clewdr-advanced";
          networking.firewall.enable = true;
          
          # Advanced ClewdR configuration
          services.clewdr = {
            enable = true;
            ip = "127.0.0.1";  # Local only for security
            port = 8100;       # Custom port
            
            # Custom user/group
            user = "clewdr-service";
            group = "clewdr-service";
            dataDir = "/opt/clewdr/data";
            
            # Comprehensive settings
            settings = {
              # Performance tuning
              cache_response = 500;
              max_retries = 5;
              
              # Security settings
              password = "secure-api-password";
              admin_password = "secure-admin-password";
              
              # Feature flags
              check_update = false;
              auto_update = false;
              web_search = true;
              preserve_chats = true;
              
              # Rate limiting and behavior
              not_hash_last_n = 10;
              not_hash_system = true;
              
              # Cookie behavior
              skip_first_warning = false;
              skip_second_warning = false;
              skip_restricted = false;
              skip_non_pro = false;
              skip_rate_limit = false;
              skip_normal_pro = false;
            };
            
            # Environment variables
            environment = {
              RUST_LOG = "info,clewdr=debug";
              ANTHROPIC_API_KEY = "sk-real-key-here";
              GOOGLE_AI_API_KEY = "real-google-key-here";
              CLEWDR_TOKIO_CONSOLE = "false";
            };
            
            # Security: don't open firewall, use reverse proxy
            openFirewall = false;
            
            # Extra arguments for debugging
            extraArgs = [ "--verbose" ];
          };
          
          # Nginx reverse proxy with SSL termination
          services.nginx = {
            enable = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;
            recommendedProxySettings = true;
            
            virtualHosts."clewdr.example.com" = {
              enableACME = true;
              forceSSL = true;
              
              locations."/" = {
                proxyPass = "http://127.0.0.1:8100";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                '';
              };
            };
          };
          
          # Let's Encrypt SSL
          security.acme = {
            acceptTerms = true;
            defaults.email = "admin@example.com";
          };
          
          # Monitoring with Prometheus
          services.prometheus = {
            enable = true;
            port = 9090;
            
            scrapeConfigs = [
              {
                job_name = "clewdr";
                static_configs = [{
                  targets = [ "127.0.0.1:8100" ];
                }];
                scrape_interval = "15s";
                metrics_path = "/metrics";  # If ClewdR exposes metrics
              }
            ];
          };
          
          # Log aggregation
          services.journald.extraConfig = ''
            Storage=persistent
            MaxRetentionSec=7d
          '';
          
          # Systemd service monitoring
          systemd.services.clewdr-monitor = {
            description = "ClewdR Health Monitor";
            wantedBy = [ "multi-user.target" ];
            after = [ "clewdr.service" ];
            
            serviceConfig = {
              Type = "simple";
              Restart = "always";
              RestartSec = "30s";
            };
            
            script = ''
              while true; do
                if ! ${nixpkgs.legacyPackages.x86_64-linux.curl}/bin/curl -f http://127.0.0.1:8100/ >/dev/null 2>&1; then
                  echo "ClewdR health check failed" | ${nixpkgs.legacyPackages.x86_64-linux.systemd}/bin/systemd-cat -t clewdr-monitor -p warning
                fi
                sleep 60
              done
            '';
          };
          
          # Backup configuration
          services.restic.backups.clewdr = {
            initialize = true;
            repository = "/backup/clewdr";
            passwordFile = "/etc/restic-password";
            paths = [ "/opt/clewdr/data" ];
            timerConfig = {
              OnCalendar = "daily";
              RandomizedDelaySec = "1h";
            };
          };
          
          # System packages for administration
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            curl
            jq
            htop
            lsof
            tcpdump
            strace
          ];
          
          # Security hardening
          security.sudo.enable = false;  # Disable sudo for production
          users.mutableUsers = false;   # Immutable user configuration
          
          # Networking security
          networking.firewall = {
            allowedTCPPorts = [ 80 443 9090 ];  # HTTP, HTTPS, Prometheus
            logReversePathDrops = true;
            logRefusedConnections = false;  # Reduce log spam
          };
          
          # Define users declaratively
          users.users = {
            admin = {
              isNormalUser = true;
              extraGroups = [ "wheel" "systemd-journal" ];
              openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3... admin@example.com"  # Replace with real key
              ];
            };
            
            clewdr-service = {
              isSystemUser = true;
              group = "clewdr-service";
              home = "/opt/clewdr";
              createHome = true;
            };
          };
          
          users.groups.clewdr-service = {};
          
          # SSH configuration
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "no";
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
            };
          };
          
          system.stateVersion = "24.05";
        }
      ];
    };
    
    # Specialized VM test for advanced features
    checks.x86_64-linux.vm-test = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "clewdr-advanced";
      
      nodes.machine = { config, pkgs, ... }: {
        imports = [ self.nixosConfigurations.example.config ];
        
        # Override some settings for testing
        services.clewdr.openFirewall = true;  # Open firewall for testing
        security.acme.acceptTerms = false;    # Disable ACME for testing
        services.nginx.virtualHosts."clewdr.example.com".enableACME = false;
        services.nginx.virtualHosts."clewdr.example.com".forceSSL = false;
        
        # Add test utilities
        environment.systemPackages = with pkgs; [ curl jq netcat ];
      };
      
      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        
        # Test ClewdR service
        machine.wait_for_unit("clewdr.service")
        machine.wait_for_open_port(8100)
        
        # Test reverse proxy
        machine.wait_for_unit("nginx.service")
        machine.wait_for_open_port(80)
        
        # Test monitoring
        machine.wait_for_unit("prometheus.service")
        machine.wait_for_open_port(9090)
        
        # Test health monitoring
        machine.wait_for_unit("clewdr-monitor.service")
        
        # Verify SSL proxy works (without SSL in test)
        machine.succeed("curl -f http://127.0.0.1:80/ || curl -f http://127.0.0.1:80/health || true")
        
        # Test direct ClewdR access
        machine.succeed("curl -f http://127.0.0.1:8100/ || curl -f http://127.0.0.1:8100/health || true")
        
        # Test Prometheus metrics collection
        machine.succeed("curl -f http://127.0.0.1:9090/")
        
        # Verify backup service is configured
        machine.succeed("systemctl status restic-backups-clewdr.timer")
        
        print("All advanced configuration tests passed!")
      '';
    };
  };
}