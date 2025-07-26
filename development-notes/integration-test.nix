{ pkgs ? import <nixpkgs> {} }:

let
  # Test that our module can be imported and basic options work
  testConfig = pkgs.nixos {
    imports = [ ./module.nix ];
    
    services.clewdr = {
      enable = true;
      package = pkgs.callPackage ./package.nix {};
      ip = "127.0.0.1";
      port = 8100;
      settings = {
        password = "test-pass";
        admin_password = "admin-pass";
      };
    };
    
    # Minimal system config
    boot.loader.grub.enable = false;
    fileSystems."/" = { device = "tmpfs"; fsType = "tmpfs"; };
    system.stateVersion = "23.11";
  };

in {
  # Test that the module evaluates correctly
  moduleTest = testConfig.config.services.clewdr.enable;
  
  # Test that the systemd service is created
  serviceTest = testConfig.config.systemd.services.clewdr.enable;
  
  # Test that the package is available
  packageTest = testConfig.config.services.clewdr.package.name or "clewdr";
}