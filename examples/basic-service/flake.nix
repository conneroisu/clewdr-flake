{
  description = "Basic ClewdR service example";

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
          # Basic system configuration
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          
          networking.hostName = "clewdr-basic";
          networking.firewall.enable = true;
          
          # Enable ClewdR with minimal configuration
          services.clewdr = {
            enable = true;
            ip = "0.0.0.0";  # Listen on all interfaces
            port = 8484;
            
            settings = {
              password = "demo-password";
              admin_password = "demo-admin-password";
              check_update = false;
              auto_update = false;
            };
            
            # Demo environment variables
            environment = {
              ANTHROPIC_API_KEY = "sk-demo-key-replace-with-real-key";
              GOOGLE_AI_API_KEY = "demo-google-key-replace-with-real-key";
            };
            
            openFirewall = true;
          };
          
          # Basic system packages
          environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
            curl
            jq
          ];
          
          # Allow root login for demo
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          
          users.users.root.password = "demo";
          
          system.stateVersion = "24.05";
        }
      ];
    };
    
    # VM test for this example
    checks.x86_64-linux.vm-test = import ../../tests/nixos-test.nix {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      clewdrPackage = clewdr-flake.packages.x86_64-linux.clewdr;
      clewdrModule = clewdr-flake.nixosModules.clewdr;
    };
  };
}