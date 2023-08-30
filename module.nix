{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.services.backup;

  mkService = name: job: {
    serviceConfig.ProtectSystem = mkForce "full";
  };

  mkBackupJob = name: job: {
    preHook = job.preHook;
    postHook = job.postHook;
    paths = job.paths;
    exclude = job.exclude;
    persistentTimer = cfg.persistentTimer;
    startAt = cfg.startAt;
    environment.BORG_RSH = cfg.borgRSH;
    encryption.passCommand = cfg.passCommand;
    encryption.mode = cfg.encryptionMode;
    archiveBaseName = "${cfg.archiveBaseName}-${name}";
    repo = "${cfg.repo}/${name}";
    prune.prefix = "${cfg.archiveBaseName}-${name}";
    prune.keep = cfg.prune.keep;
  };

  jobOptions = {...}: {
    options = {
      preHook = mkOption {
        type = types.str;
        default = "";
      };
      postHook = mkOption {
        type = types.str;
        default = "";
      };
      paths = mkOption {
        type = with types; listOf str;
        default = [];
      };
      exclude = mkOption {
        type = with types; listOf str;
        default = [];
      };
    };
  };
in {
  imports = [];

  options.services.backup = {
    enable = mkEnableOption "";

    persistentTimer = mkOption {
      type = types.bool;
      default = true;
    };

    archiveBaseName = mkOption {
      type = types.str;
    };

    startAt = mkOption {
      type = types.str;
      default = "daily";
    };

    borgRSH = mkOption {
      type = types.str;
    };

    passCommand = mkOption {
      type = types.str;
    };

    encryptionMode = mkOption {
      type = types.str;
    };

    repo = mkOption {
      type = types.str;
    };

    prune.keep = mkOption {
      type = types.attrs;
    };

    jobs = mkOption {
      type = types.attrsOf (types.submodule jobOptions);
      default = {};
    };
  };
  config = mkIf cfg.enable {
    services.borgbackup.jobs = mapAttrs' (n: v: nameValuePair n (mkBackupJob n v)) cfg.jobs;

    systemd.services = mapAttrs' (n: v:
      nameValuePair "borgbackup-job-${n}" {
        serviceConfig = {
          ProtectSystem = mkForce "full";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
        };
      })
    cfg.jobs;

    systemd.timers = mkIf config.networking.useNetworkd (
      mapAttrs'
      (n: v:
        nameValuePair "borgbackup-job-${n}" {
          after = ["systemd-networkd-wait-online.service"];
          wants = ["systemd-networkd-wait-online.service"];
        })
      cfg.jobs
    );
  };
}
