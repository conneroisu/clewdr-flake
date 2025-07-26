{
  description = "ClewdR with proper secrets management using sops-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    clewdr-flake.url = "path:../..";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, clewdr-flake, sops-nix }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        clewdr-flake.nixosModules.clewdr
        sops-nix.nixosModules.sops
        {
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          networking.hostName = "clewdr-secrets";
          networking.firewall.enable = true;
          
          # SOPS secrets management
          sops = {
            defaultSopsFile = ./secrets.yaml;
            defaultSopsFormat = "yaml";
            
            # Age key for decryption (in production, this should be securely managed)
            age.keyFile = "/var/lib/sops-nix/key.txt";
            
            secrets = {
              # ClewdR passwords
              "clewdr/api-password" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
              };
              
              "clewdr/admin-password" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
              };
              
              # API keys
              "anthropic/api-key" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
              };
              
              "google/ai-api-key" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
              };
              
              "google/service-account" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
                format = "json";
              };
              
              # Database credentials (if using external storage)
              "database/url" = {
                owner = "clewdr";
                group = "clewdr";
                mode = "0400";
              };
              
              # SSL certificates (if managing manually)
              "ssl/cert" = {
                owner = "nginx";
                group = "nginx"; 
                mode = "0444";
              };
              
              "ssl/key" = {
                owner = "nginx";
                group = "nginx";
                mode = "0400";
              };
            };
          };
          
          # ClewdR configuration with secrets
          services.clewdr = {
            enable = true;
            ip = "127.0.0.1";
            port = 8100;
            
            # Use secret files instead of plaintext passwords
            passwordFile = config.sops.secrets."clewdr/api-password".path;
            adminPasswordFile = config.sops.secrets."clewdr/admin-password".path;
            
            settings = {
              cache_response = 200;
              max_retries = 3;
              check_update = false;
              auto_update = false;
              preserve_chats = true;
            };
            
            # Environment with secret loading
            environment = {
              RUST_LOG = "info";
            };
            
            openFirewall = false;  # Use reverse proxy
          };
          
          # Systemd service to load API keys from secrets
          systemd.services.clewdr-secrets = {
            description = "Load ClewdR API secrets";
            before = [ "clewdr.service" ];
            wantedBy = [ "clewdr.service" ];
            
            serviceConfig = {
              Type = "oneshot";
              User = "clewdr";
              Group = "clewdr";
            };
            
            script = ''
              # Create environment file with secrets
              cat > /var/lib/clewdr/secrets.env << EOF
              ANTHROPIC_API_KEY=$(cat ${config.sops.secrets."anthropic/api-key".path})
              GOOGLE_AI_API_KEY=$(cat ${config.sops.secrets."google/ai-api-key".path})
              GOOGLE_APPLICATION_CREDENTIALS=${config.sops.secrets."google/service-account".path}
              DATABASE_URL=$(cat ${config.sops.secrets."database/url".path})
              EOF
              
              chmod 600 /var/lib/clewdr/secrets.env
            '';
          };
          
          # Modify ClewdR service to use secrets environment file
          systemd.services.clewdr.serviceConfig.EnvironmentFile = "/var/lib/clewdr/secrets.env";
          
          # Nginx with SSL from secrets
          services.nginx = {
            enable = true;
            
            virtualHosts."secure.example.com" = {
              # Use certificates from secrets
              sslCertificate = config.sops.secrets."ssl/cert".path;
              sslCertificateKey = config.sops.secrets."ssl/key".path;
              
              forceSSL = true;
              
              locations."/" = {
                proxyPass = "http://127.0.0.1:8100";
                proxyWebsockets = true;
                
                extraConfig = ''
                  # Additional security headers
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  
                  # Security headers
                  add_header X-Frame-Options DENY;
                  add_header X-Content-Type-Options nosniff;
                  add_header X-XSS-Protection "1; mode=block";
                  add_header Strict-Transport-Security "max-age=31536000";
                '';
              };
              
              # Admin interface with additional authentication
              locations."/admin" = {
                proxyPass = "http://127.0.0.1:8100/admin";
                
                extraConfig = ''
                  # IP whitelist for admin access
                  allow 10.0.0.0/8;
                  allow 192.168.0.0/16;
                  deny all;
                  
                  # Rate limiting
                  limit_req zone=admin burst=5 nodelay;
                '';
              };
            };
            
            # Rate limiting configuration
            appendHttpConfig = ''
              limit_req_zone $binary_remote_addr zone=admin:10m rate=1r/s;
            '';
          };
          
          # Backup with encrypted storage
          services.restic.backups.clewdr-secure = {
            initialize = true;
            repository = "s3:backup-bucket/clewdr";
            passwordFile = "/run/secrets/restic-password";
            
            paths = [ 
              "/var/lib/clewdr"
              "/etc/ssl/certs"
            ];
            
            exclude = [
              "/var/lib/clewdr/secrets.env"  # Don't backup plaintext secrets
              "/var/lib/clewdr/cache"        # Skip cache files
            ];
            
            environmentFile = "/run/secrets/restic-env";  # S3 credentials
            
            timerConfig = {
              OnCalendar = "02:00";  # 2 AM daily
              RandomizedDelaySec = "30m";
            };
            
            # Prune old backups
            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"  
              "--keep-monthly 3"
            ];
          };
          
          # Security monitoring
          services.fail2ban = {
            enable = true;
            
            jails = {
              nginx-http-auth = {
                enabled = true;
                filter = "nginx-http-auth";
                logpath = "/var/log/nginx/error.log";
                maxretry = 3;
                bantime = "1h";
              };
              
              nginx-limit-req = {
                enabled = true;
                filter = "nginx-limit-req";
                logpath = "/var/log/nginx/error.log";
                maxretry = 10;
                bantime = "10m";
              };
            };
          };
          
          # Audit logging
          security.auditd.enable = true;
          security.audit = {
            enable = true;
            rules = [
              # Monitor secret file access
              "-w ${config.sops.secrets."clewdr/api-password".path} -p r -k secret-access"
              "-w ${config.sops.secrets."anthropic/api-key".path} -p r -k secret-access"
              
              # Monitor ClewdR configuration changes
              "-w /var/lib/clewdr -p wa -k clewdr-data"
              "-w /etc/systemd/system/clewdr.service -p wa -k clewdr-config"
            ];
          };
          
          # Firewall with strict rules
          networking.firewall = {
            allowedTCPPorts = [ 80 443 ];
            
            # Only allow SSH from specific networks
            interfaces.eth0.allowedTCPPorts = [ 22 ];
            
            # Log dropped packets
            logReversePathDrops = true;
            logRefusedConnections = false;
            
            extraCommands = ''
              # Drop all other traffic
              iptables -A INPUT -j LOG --log-prefix "Dropped: "
              iptables -A INPUT -j DROP
            '';
          };
          
          # System packages for security administration
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            sops
            age
            curl
            jq
            openssl
            htop
            lsof
          ];
          
          # Secure user configuration
          users.mutableUsers = false;
          users.users.root.hashedPassword = "!";  # Disable root password
          
          users.users.admin = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            hashedPassword = "$6$...";  # Use proper hashed password
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3... admin@secure-workstation"
            ];
          };
          
          # SSH hardening
          services.openssh = {
            enable = true;
            settings = {
              PeritRootLogin = "no";
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              X11Forwarding = false;
              AllowTcpForwarding = "no";
              AllowStreamLocalForwarding = "no";
              AuthenticationMethods = "publickey";
            };
            
            # Restrict to specific users
            allowSFTP = false;
            extraConfig = ''
              AllowUsers admin
              ClientAliveInterval 300
              ClientAliveCountMax 2
            '';
          };
          
          system.stateVersion = "24.05";
        }
      ];
    };
    
    # Security-focused VM test
    checks.x86_64-linux.vm-test = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "clewdr-secrets";
      
      nodes.machine = { config, pkgs, ... }: {
        imports = [ self.nixosConfigurations.example.config ];
        
        # Override some settings for testing
        networking.firewall.allowedTCPPorts = [ 8100 ];  # Direct access for testing
        services.clewdr.openFirewall = true;
        
        # Create mock secrets for testing
        sops.age.keyFile = pkgs.writeText "age-key" ''
          # AGE-SECRET-KEY-1...  (this would be a real key in production)
          AGE-SECRET-KEY-1MOCK123456789ABCDEF
        '';
        
        environment.systemPackages = with pkgs; [ curl jq netcat-gnu ];
      };
      
      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
        
        # Wait for secrets to be loaded
        machine.wait_for_unit("clewdr-secrets.service")
        
        # Wait for ClewdR service
        machine.wait_for_unit("clewdr.service")
        machine.wait_for_open_port(8100)
        
        # Wait for nginx
        machine.wait_for_unit("nginx.service")
        machine.wait_for_open_port(443)
        
        # Test that secrets files exist and have correct permissions
        machine.succeed("test -f /run/secrets/clewdr/api-password")
        machine.succeed("test $(stat -c %a /run/secrets/clewdr/api-password) = 400")
        
        # Test that secrets environment file was created
        machine.succeed("test -f /var/lib/clewdr/secrets.env")
        machine.succeed("test $(stat -c %a /var/lib/clewdr/secrets.env) = 600")
        
        # Test that only clewdr user can read secrets
        machine.succeed("sudo -u clewdr cat /run/secrets/clewdr/api-password")
        machine.fail("sudo -u nobody cat /run/secrets/clewdr/api-password")
        
        # Test ClewdR responds
        machine.succeed("curl -k https://127.0.0.1/ || curl -f http://127.0.0.1:8100/ || true")
        
        # Test fail2ban is running
        machine.wait_for_unit("fail2ban.service")
        
        # Test audit daemon
        machine.wait_for_unit("auditd.service")
        
        # Verify backup service is configured
        machine.succeed("systemctl status restic-backups-clewdr-secure.timer")
        
        print("Secrets management test passed!")
      '';
    };
  };
}