# Game development infrastructure module
# Forgejo (git forge) + Dendrite (Matrix chat) for AI agent collaboration
{ config, lib, pkgs, ... }:

{
  # ==========================================================================
  # Forgejo — lightweight git forge (issues, PRs, code review)
  # ==========================================================================
  services.forgejo = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "0.0.0.0";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;
        ROOT_URL = "http://localhost:3000/";
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      # Minimal resource usage
      indexer = {
        REPO_INDEXER_ENABLED = false;
      };
      # API access for MCP servers
      api = {
        ENABLE_SWAGGER = false;
      };
      # Allow webhooks to localhost (for forgejo-webhook.py receiver)
      webhook = {
        ALLOWED_HOST_LIST = "127.0.0.1,localhost";
      };
    };
  };

  # ==========================================================================
  # Dendrite — lightweight Matrix homeserver for agent communication
  # ==========================================================================
  services.dendrite = {
    enable = true;
    httpPort = 8008;
    settings = {
      global = {
        server_name = "localhost";
        private_key = "/var/lib/dendrite/matrix_key.pem";
        disable_federation = true;  # Local only, no federation needed
      };
      client_api = {
        registration_disabled = true;  # We'll create accounts via CLI
        registration_shared_secret = "gamedev-local-secret";
      };
      # Note: Dendrite httpPort binds to 0.0.0.0 by default
      media_api = {
        max_file_size_bytes = 10485760;  # 10MB
        base_path = "/var/lib/dendrite/media";
      };
    };
  };

  # Allow Forgejo + Dendrite on Tailscale
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 3000 8008 ];

  # Generate Dendrite private key before first start
  # Run as root since dendrite user may not exist at first activation
  systemd.services.dendrite-keygen = {
    description = "Generate Dendrite Matrix private key";
    before = [ "dendrite.service" ];
    requiredBy = [ "dendrite.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/dendrite
      if [ ! -f /var/lib/dendrite/matrix_key.pem ]; then
        ${pkgs.dendrite}/bin/generate-keys --private-key /var/lib/dendrite/matrix_key.pem
      fi
      chmod 640 /var/lib/dendrite/matrix_key.pem
    '';
  };
}
