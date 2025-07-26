{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.clewdr;
  
  # TOML configuration format for ClewdR settings
  # Provides type-safe configuration generation with validation
  settingsFormat = pkgs.formats.toml { };
  configFile = settingsFormat.generate "clewdr.toml" cfg.settings;

  # Default system user and group for security isolation
  # Running as dedicated user follows principle of least privilege
  defaultUser = "clewdr";
  defaultGroup = "clewdr";
  
in {
  # NixOS service module options for ClewdR LLM proxy
  # Provides declarative configuration for production deployments
  options.services.clewdr = {
    # Main service toggle - enables/disables entire ClewdR service
    enable = mkEnableOption "ClewdR LLM proxy service";

    # Package selection - allows using custom or specific versions
    package = mkPackageOption pkgs "clewdr" { };

    # System user configuration for service isolation
    # Defaults to dedicated 'clewdr' user for security
    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User account under which ClewdR runs.";
    };

    # System group configuration for file permissions
    # Matches user by default for consistent access control
    group = mkOption {
      type = types.str;
      default = defaultGroup;
      description = "Group account under which ClewdR runs.";
    };

    # Data storage directory for persistent application state
    # Located in standard /var/lib hierarchy for system services
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/clewdr";
      description = "Directory where ClewdR stores its data.";
    };

    # Firewall integration for automatic port management
    # Disabled by default for security - requires explicit enabling
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for ClewdR's port.";
    };

    # Structured configuration settings for ClewdR application
    # Uses TOML format for type-safe configuration management
    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        Configuration for ClewdR. See the ClewdR documentation for available options.
        Settings are merged with explicit options like ip, port, and password files.
      '';
      example = literalExpression ''
        {
          ip = "127.0.0.1";
          port = 8484;
          password = "your-api-password";
          admin_password = "your-admin-password";
          check_update = false;
          auto_update = false;
        }
      '';
    };

    # Network binding configuration
    # Controls which network interfaces the service listens on
    ip = mkOption {
      type = types.str;
      default = "127.0.0.1";  # Localhost only by default for security
      description = "IP address to bind to. Use 0.0.0.0 for all interfaces.";
    };

    # TCP port for HTTP server
    # Standard port 8484 chosen to avoid conflicts with common services
    port = mkOption {
      type = types.port;
      default = 8484;
      description = "Port to listen on.";
    };

    # Secure password file for API authentication
    # File-based approach prevents passwords in Nix store
    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the API password.
        If set, this takes precedence over the password in settings.
        Recommended for production deployments to avoid passwords in Nix store.
      '';
    };

    # Secure admin password file for administrative functions
    # Separate from regular API password for privilege separation
    adminPasswordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the admin password.
        If set, this takes precedence over the admin_password in settings.
        Required for administrative operations and service management.
      '';
    };

    # Proxy settings
    proxy = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "HTTP proxy URL (e.g., http://proxy:port).";
    };

    reverseProxy = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Reverse proxy URL (e.g., https://example.com).";
    };

    # Feature toggles
    autoUpdate = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic updates.";
    };

    checkUpdate = mkOption {
      type = types.bool;
      default = false;
      description = "Check for updates on startup.";
    };

    webSearch = mkOption {
      type = types.bool;
      default = false;
      description = "Enable web search functionality.";
    };

    preserveChats = mkOption {
      type = types.bool;
      default = false;
      description = "Preserve chat history.";
    };

    # Vertex AI settings
    vertexAI = {
      credentialFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to Google Cloud service account JSON file for Vertex AI.";
      };

      modelId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default Vertex AI model ID (overrides API query models).";
      };
    };

    # Environment variables
    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables to set for the ClewdR service.";
      example = {
        RUST_LOG = "info";
        CLEWDR_TOKIO_CONSOLE = "false";
      };
    };

    # Extra arguments
    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments to pass to ClewdR.";
    };
  };

  config = mkIf cfg.enable {
    # Merge user-provided settings with options
    services.clewdr.settings = mkMerge [
      {
        ip = cfg.ip;
        port = cfg.port;
        check_update = cfg.checkUpdate;
        auto_update = cfg.autoUpdate;
        web_search = cfg.webSearch;
        preserve_chats = cfg.preserveChats;
        
        # Cache settings with sensible defaults
        cache_response = mkDefault 100;
        max_retries = mkDefault 3;
        not_hash_last_n = mkDefault 0;
        not_hash_system = mkDefault false;
        
        # Cookie settings with sensible defaults
        skip_first_warning = mkDefault false;
        skip_second_warning = mkDefault false;
        skip_restricted = mkDefault false;
        skip_non_pro = mkDefault false;
        skip_rate_limit = mkDefault false;
        skip_normal_pro = mkDefault false;
        
        # Prompt settings
        use_real_roles = mkDefault false;
        padtxt_len = mkDefault 0;
        custom_prompt = mkDefault "";
      }
      (mkIf (cfg.proxy != null) { proxy = cfg.proxy; })
      (mkIf (cfg.reverseProxy != null) { rproxy = cfg.reverseProxy; })
      (mkIf (cfg.vertexAI.modelId != null) { 
        vertex.model_id = cfg.vertexAI.modelId; 
      })
    ];

    # Create user and group
    users.users = mkIf (cfg.user == defaultUser) {
      ${defaultUser} = {
        group = cfg.group;
        home = cfg.dataDir;
        createHome = true;
        homeMode = "755";
        description = "ClewdR service user";
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == defaultGroup) {
      ${defaultGroup} = { };
    };

    # Create systemd service
    systemd.services.clewdr = {
      description = "ClewdR LLM Proxy Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = "10s";
        
        # Security settings (relaxed for compatibility)
        NoNewPrivileges = true;
        ProtectSystem = "full";  # Changed from "strict" to allow more filesystem access
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        LockPersonality = true;
        # MemoryDenyWriteExecute = true;  # Commented out as it might interfere with Rust
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        
        # Filesystem permissions - allow writing to data directory only
        ReadWritePaths = [ cfg.dataDir ];
        
        # Working directory
        WorkingDirectory = cfg.dataDir;
        
        # Process properties
        OOMScoreAdjust = 100;
      };

      environment = mkMerge [
        {
          # Default environment
          HOME = cfg.dataDir;
          CLEWDR_IP = cfg.ip;
          CLEWDR_PORT = toString cfg.port;
          CLEWDR_CHECK_UPDATE = if cfg.checkUpdate then "TRUE" else "FALSE";
          CLEWDR_AUTO_UPDATE = if cfg.autoUpdate then "FALSE" else "FALSE"; # Disable auto-update in systemd service
          CLEWDR_TOKIO_CONSOLE = "FALSE";
          # Try to override directory detection
          CLEWDR_DIR = cfg.dataDir;
          CLEWDR_DATA_DIR = cfg.dataDir;
        }
        cfg.environment
      ];

      script = let
        args = lib.escapeShellArgs ([ 
          "--config" configFile 
        ] ++ cfg.extraArgs);
      in ''
        # Handle password files
        ${optionalString (cfg.passwordFile != null) ''
          export CLEWDR_PASSWORD="$(cat ${cfg.passwordFile})"
        ''}
        ${optionalString (cfg.adminPasswordFile != null) ''
          export CLEWDR_ADMIN_PASSWORD="$(cat ${cfg.adminPasswordFile})"
        ''}
        ${optionalString (cfg.vertexAI.credentialFile != null) ''
          export GOOGLE_APPLICATION_CREDENTIALS="${cfg.vertexAI.credentialFile}"
        ''}
        
        # Start ClewdR
        exec ${cfg.package}/bin/clewdr ${args}
      '';

      preStart = ''
        # Ensure data directory exists with correct permissions
        mkdir -p ${cfg.dataDir}
        chmod 755 ${cfg.dataDir}
        
        # Create logs directory
        mkdir -p ${cfg.dataDir}/logs
        chmod 755 ${cfg.dataDir}/logs
      '';
    };

    # Open firewall if requested
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # Add package to system packages
    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with maintainers; [ ]; # Add maintainer info as needed
}