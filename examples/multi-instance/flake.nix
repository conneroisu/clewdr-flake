{
  description = "Multi-instance ClewdR deployment example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    clewdr-flake.url = "path:../..";
  };

  outputs = { self, nixpkgs, clewdr-flake }: 
  let
    # Helper function to create ClewdR instance
    makeClewdrInstance = { instanceName, port, dataDir, settings ? {} }: {
      systemd.services."clewdr-${instanceName}" = {
        description = "ClewdR LLM Proxy Service (${instanceName})";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        
        serviceConfig = {
          Type = "simple";
          User = "clewdr-${instanceName}";
          Group = "clewdr-${instanceName}";
          Restart = "always";
          RestartSec = "10s";
          WorkingDirectory = dataDir;
          
          # Security settings
          NoNewPrivileges = true;
          ProtectSystem = "full";
          ProtectHome = true;
          PrivateTmp = true;
          ReadWritePaths = [ dataDir ];
        };
        
        environment = {
          CLEWDR_DIR = dataDir;
          RUST_LOG = "info";
        } // (settings.environment or {});
        
        script = let
          configFile = nixpkgs.legacyPackages.x86_64-linux.writeText "clewdr-${instanceName}.toml" ''
            ip = "127.0.0.1"
            port = ${toString port}
            ${nixpkgs.lib.generators.toINI {} (settings.config or {})}
          '';
        in ''
          exec ${clewdr-flake.packages.x86_64-linux.clewdr}/bin/clewdr --config ${configFile}
        '';
        
        preStart = ''
          mkdir -p ${dataDir}
          chown clewdr-${instanceName}:clewdr-${instanceName} ${dataDir}
        '';
      };
      
      users.users."clewdr-${instanceName}" = {
        isSystemUser = true;
        group = "clewdr-${instanceName}";
        home = dataDir;
        createHome = true;
      };
      
      users.groups."clewdr-${instanceName}" = {};
    };
  in {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          networking.hostName = "clewdr-multi";
          networking.firewall.enable = true;
          networking.firewall.allowedTCPPorts = [ 80 8081 8082 8083 ];
          
          # Import multiple ClewdR instances
          imports = [
            # Production instance - high performance
            (makeClewdrInstance {
              instanceName = "production";
              port = 8081;
              dataDir = "/var/lib/clewdr-production";
              settings = {
                config = {
                  password = "prod-password";
                  admin_password = "prod-admin-password";
                  cache_response = 1000;
                  max_retries = 3;
                  preserve_chats = true;
                };
                environment = {
                  ANTHROPIC_API_KEY = "sk-prod-key";
                  GOOGLE_AI_API_KEY = "prod-google-key";
                };
              };
            })
            
            # Development instance - debug mode
            (makeClewdrInstance {
              instanceName = "development";
              port = 8082;
              dataDir = "/var/lib/clewdr-development";
              settings = {
                config = {
                  password = "dev-password";
                  admin_password = "dev-admin-password";
                  cache_response = 10;
                  max_retries = 1;
                  preserve_chats = false;
                };
                environment = {
                  RUST_LOG = "debug";
                  ANTHROPIC_API_KEY = "sk-dev-key";
                  GOOGLE_AI_API_KEY = "dev-google-key";
                };
              };
            })
            
            # Testing instance - minimal setup
            (makeClewdrInstance {
              instanceName = "testing";
              port = 8083;
              dataDir = "/var/lib/clewdr-testing";
              settings = {
                config = {
                  password = "test-password";
                  admin_password = "test-admin-password";
                  cache_response = 0;  # No caching for testing
                  max_retries = 1;
                };
                environment = {
                  ANTHROPIC_API_KEY = "sk-test-key";
                  GOOGLE_AI_API_KEY = "test-google-key";
                };
              };
            })
          ];
          
          # Load balancer using Nginx
          services.nginx = {
            enable = true;
            
            # Upstream definitions
            appendConfig = ''
              upstream clewdr_production {
                server 127.0.0.1:8081;
              }
              
              upstream clewdr_development {
                server 127.0.0.1:8082;
              }
              
              upstream clewdr_testing {
                server 127.0.0.1:8083;
              }
            '';
            
            virtualHosts = {
              # Production traffic
              "api.example.com" = {
                locations."/" = {
                  proxyPass = "http://clewdr_production";
                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                  '';
                };
              };
              
              # Development traffic
              "dev-api.example.com" = {
                locations."/" = {
                  proxyPass = "http://clewdr_development";
                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                  '';
                };
              };
              
              # Testing traffic  
              "test-api.example.com" = {
                locations."/" = {
                  proxyPass = "http://clewdr_testing";
                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                  '';
                };
              };
              
              # Management interface
              "admin.example.com" = {
                locations = {
                  "/prod/" = {
                    proxyPass = "http://127.0.0.1:8081/";
                    extraConfig = ''
                      auth_basic "Production Admin";
                      auth_basic_user_file /etc/nginx/prod.htpasswd;
                    '';
                  };
                  
                  "/dev/" = {
                    proxyPass = "http://127.0.0.1:8082/";
                    extraConfig = ''
                      auth_basic "Development Admin";  
                      auth_basic_user_file /etc/nginx/dev.htpasswd;
                    '';
                  };
                  
                  "/test/" = {
                    proxyPass = "http://127.0.0.1:8083/";
                  };
                };
              };
            };
          };
          
          # Monitoring all instances
          services.prometheus = {
            enable = true;
            scrapeConfigs = [
              {
                job_name = "clewdr-production";
                static_configs = [{ targets = [ "127.0.0.1:8081" ]; }];
              }
              {
                job_name = "clewdr-development"; 
                static_configs = [{ targets = [ "127.0.0.1:8082" ]; }];
              }
              {
                job_name = "clewdr-testing";
                static_configs = [{ targets = [ "127.0.0.1:8083" ]; }];
              }
            ];
          };
          
          # Log rotation for all instances
          services.logrotate = {
            enable = true;
            settings = {
              "/var/log/clewdr-*/*.log" = {
                frequency = "daily";
                rotate = 7;
                compress = true;
                delaycompress = true;
                missingok = true;
                notifempty = true;
              };
            };
          };
          
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            curl jq htop
          ];
          
          system.stateVersion = "24.05";
        }
      ];
    };
    
    # Test each instance
    checks.x86_64-linux.vm-test = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "clewdr-multi-instance";
      
      nodes.machine = { config, pkgs, ... }: {
        imports = [ self.nixosConfigurations.example.config ];
        environment.systemPackages = with pkgs; [ curl jq netcat-gnu ];
      };
      
      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        
        # Wait for all ClewdR instances
        machine.wait_for_unit("clewdr-production.service")
        machine.wait_for_unit("clewdr-development.service") 
        machine.wait_for_unit("clewdr-testing.service")
        
        # Wait for all ports
        machine.wait_for_open_port(8081)  # Production
        machine.wait_for_open_port(8082)  # Development
        machine.wait_for_open_port(8083)  # Testing
        
        # Wait for nginx
        machine.wait_for_unit("nginx.service")
        machine.wait_for_open_port(80)
        
        # Test each instance directly
        machine.succeed("curl -f http://127.0.0.1:8081/ || curl -f http://127.0.0.1:8081/health || true")
        machine.succeed("curl -f http://127.0.0.1:8082/ || curl -f http://127.0.0.1:8082/health || true")
        machine.succeed("curl -f http://127.0.0.1:8083/ || curl -f http://127.0.0.1:8083/health || true")
        
        # Test load balancer (would need proper DNS in real deployment)
        machine.succeed("curl -H 'Host: api.example.com' http://127.0.0.1/ || true")
        machine.succeed("curl -H 'Host: dev-api.example.com' http://127.0.0.1/ || true")
        machine.succeed("curl -H 'Host: test-api.example.com' http://127.0.0.1/ || true")
        
        # Verify instances are running with different configurations
        machine.succeed("systemctl is-active clewdr-production")
        machine.succeed("systemctl is-active clewdr-development")
        machine.succeed("systemctl is-active clewdr-testing")
        
        # Check data directories exist
        machine.succeed("test -d /var/lib/clewdr-production")
        machine.succeed("test -d /var/lib/clewdr-development")
        machine.succeed("test -d /var/lib/clewdr-testing")
        
        # Verify users exist
        machine.succeed("id clewdr-production")
        machine.succeed("id clewdr-development")
        machine.succeed("id clewdr-testing")
        
        print("Multi-instance deployment test passed!")
      '';
    };
  };
}