{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.withings-mcp;
in
{
  options.services.withings-mcp = {
    enable = lib.mkEnableOption "Withings MCP server";

    user = lib.mkOption {
      type = lib.types.str;
      default = "withings-mcp";
      description = "User that runs the Withings MCP service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "withings-mcp";
      description = "Group that runs the Withings MCP service.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/withings-mcp";
      description = "Directory containing releases, current symlink, and env file.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.stateDir}/env";
      description = "Environment file containing Withings, Supabase, and runtime secrets.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.stateDir;
      createHome = false;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir}/releases 0750 ${cfg.user} ${cfg.group} - -"
      "f ${cfg.environmentFile} 0640 root ${cfg.group} - -"
    ];

    systemd.services.withings-mcp = {
      description = "Withings MCP server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "${cfg.stateDir}/current/index.js";

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.stateDir}/current";
        EnvironmentFile = cfg.environmentFile;
        Environment = "NODE_ENV=production";
        ExecStart = "${pkgs.bun}/bin/bun ${cfg.stateDir}/current/index.js";
        Restart = "always";
        RestartSec = "5s";
        KillSignal = "SIGINT";
        TimeoutStopSec = "30s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = cfg.stateDir;
        CapabilityBoundingSet = "";
        LockPersonality = true;
      };
    };
  };
}
