{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.jibri;

  # Copied from the jitsi-videobridge.nix file.
  toHOCON = x: if isAttrs x && x ? __hocon_envvar then ("\${" + x.__hocon_envvar + "}")
    else if isAttrs x then "{${ concatStringsSep "," (mapAttrsToList (k: v: ''"${k}":${toHOCON v}'') x) }}"
    else if isList x then "[${ concatMapStringsSep "," toHOCON x }]"
    else builtins.toJSON x;

  # We're passing passwords in environment variables that have names generated
  # from an attribute name, which may not be a valid bash identifier.
  toVarName = s: "XMPP_PASSWORD_" + stringAsChars (c: if builtins.match "[A-Za-z0-9]" c != null then c else "_") s;

  defaultJibriConfig = {
    id = "";
    single-use-mode = false;

    api = {
      http.external-api-port = 2222;
      http.internal-api-port = 3333;

      xmpp.environments = flip mapAttrsToList cfg.xmppEnvironments (name: env: {
        inherit name;

        xmpp-server-hosts = env.xmppServerHosts;
        xmpp-domain = env.xmppDomain;
        control-muc = {
          domain = env.control.muc.domain;
          room-name = env.control.muc.roomName;
          nickname = env.control.muc.nickname;
        };

        control-login = {
          domain = env.control.login.domain;
          username = env.control.login.username;
          password.__hocon_envvar = toVarName "${name}_control";
        };

        call-login = {
          domain = env.call.login.domain;
          username = env.call.login.username;
          password.__hocon_envvar = toVarName "${name}_call";
        };

        strip-from-room-domain = env.stripFromRoomDomain;
        usage-timeout = env.usageTimeout;
        trust-all-xmpp-certs = env.disableCertificateVerification;
      });
    };

    recording = {
      recordings-directory = "/tmp/recordings";
      finalize-script = "/path/to/finalize"; # TODO(puck): replace with actual noop default
    };

    streaming.rtmp-allow-list = [ ".*" ];

    chrome.flags = [
      "--use-fake-ui-for-media-stream" "--start-maximized" "--kiosk" "--enabled"
      "--disable-infobars" "--autoplay-policy=no-user-gesture-required"
    ];

    stats.enable-stats-d = true;
    webhook.subscribers = [];

    jwt-info = {};

    call-status-checks = {
      no-media-timout = "30 seconds";
      all-muted-timeout = "10 minutes";
      default-call-empty-timout = "30 seconds";
    };
  };
  # Allow overriding leaves of the default config despite types.attrs not doing any merging.
  jibriConfig = recursiveUpdate defaultJibriConfig cfg.config;
  configFile = pkgs.writeText "jibri.conf" (toHOCON { jibri = jibriConfig; });
in
{
  options.services.jibri = with types; {
    enable = mkEnableOption "Jitsi BRoadcasting Infrastructure";
    config = mkOption {
      type = attrs;
      default = { };
      description = ''
        Jibri configuration.

        See <link xlink:href="https://github.com/jitsi/jibri/blob/master/src/main/resources/reference.conf" />
        for default configuration with comments.
      '';
    };

    xmppEnvironments = mkOption {
      description = ''
        XMPP servers to connect to.
      '';
      default = { };
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          xmppServerHosts = mkOption {
            type = listOf str;
            example = [ "xmpp.example.org" ];
            description = ''
              Hostnames of the XMPP servers to connect to.
            '';
          };
          xmppDomain = mkOption {
            type = str;
            example = "xmpp.example.org";
            description = ''
              The base XMPP domain.
            '';
          };
          control.muc.domain = mkOption {
            type = str;
            description = ''
              The domain part of the MUC to connect to for control.
            '';
          };
          control.muc.roomName = mkOption {
            type = str;
            default = "JibriBrewery";
            description = ''
              The room name of the MUC to connect to for control.
            '';
          };
          control.muc.nickname = mkOption {
            type = str;
            default = "jibri";
            description = ''
              The nickname for this Jibri instance in the MUC.
            '';
          };
          control.login.domain = mkOption {
            type = str;
            description = ''
              The domain part of the JID for this Jibri instance.
            '';
          };
          control.login.username = mkOption {
            type = str;
            default = "jvb";
            description = ''
              User part of the JID.
            '';
          };
          control.login.passwordFile = mkOption {
            type = str;
            example = "/run/keys/jibri-xmpp1";
            description = ''
              File containing the password for the user.
            '';
          };

          call.login.domain = mkOption {
            type = str;
            example = "recorder.xmpp.example.org";
            description = ''
              The domain part of the JID for the recorder.
            '';
          };
          call.login.username = mkOption {
            type = str;
            default = "recorder";
            description = ''
              User part of the JID for the recorder.
            '';
          };
          call.login.passwordFile = mkOption {
            type = str;
            example = "/run/keys/jibri-recorder-xmpp1";
            description = ''
              File containing the password for the user.
            '';
          };
          disableCertificateVerification = mkOption {
            type = bool;
            default = false;
            description = ''
              Whether to skip validation of the server's certificate.
            '';
          };

          stripFromRoomDomain = mkOption {
            type = str;
            default = "0";
            example = "conference.";
            description = ''
              The prefix to strip from the room's JID domain to derive the call URL.
            '';
          };
          usageTimeout = mkOption {
            type = str;
            default = "0";
            example = "1 hour";
            description = ''
              The duration that the Jibri session can be.
              A value of zero means indefinitely.
            '';
          };
        };

        config = let
          nick = mkDefault (builtins.replaceStrings [ "." ] [ "-" ] (
            config.networking.hostName + optionalString (config.networking.domain != null) ".${config.networking.domain}"
          ));
        in {
          call.login.username = nick;
          control.muc.nickname = nick;
        };
      }));
    };
  };

  config = mkIf cfg.enable {
    users.groups.jibri = {};
    users.users.jibri = {
      group = "jibri";
      home = "/var/lib/jibri";
      extraGroups = [ "jitsi-meet" "adm" "audio" "video" "plugdev" ];
    };

    systemd.services.jibri-xorg = {
      description = "Jitsi Xorg Process";

      after = [ "network.target" ];
      wantedBy = [ "jibri.service" "jibri-icewm.service" ];

      preStart = ''
        cp --no-preserve=mode,ownership ${pkgs.jibri}/etc/jitsi/jibri/* /var/lib/jibri
        mv /var/lib/jibri/{,.}asoundrc
      '';

      environment.DISPLAY = ":0";
      serviceConfig = {
        Type = "simple";

        User = "jibri";
        Group = "jibri";
        KillMode = "process";
        Restart = "on-failure";
        RestartPreventExitStatus = 255;

        StateDirectory = "jibri";

        ExecStart = "${pkgs.xorg.xorgserver}/bin/Xorg -nocursor -noreset +extension RANDR +extension RENDER -config ${pkgs.jibri}/etc/jitsi/jibri/xorg-video-dummy.conf -logfile /dev/null :0";
      };
    };

    systemd.services.jibri-icewm = {
      description = "Jitsi Window Manager";

      requires = [ "jibri-xorg.service" ];
      after = [ "jibri-xorg.service" ];
      wantedBy = [ "jibri.service" ];

      environment.DISPLAY = ":0";
      serviceConfig = {
        Type = "simple";

        User = "jibri";
        Group = "jibri";
        Restart = "on-failure";
        RestartPreventExitStatus = 255;

        StateDirectory = "jibri";

        ExecStart = "${pkgs.icewm}/bin/icewm-session";
      };
    };

    systemd.services.jibri= {
      description = "Jibri Process";

      requires = [ "jibri-icewm.service" "jibri-xorg.service" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.chromedriver pkgs.chromium pkgs.ffmpeg-full ];

      script = (concatStrings (mapAttrsToList (name: env: ''
        export ${toVarName "${name}_control"}=$(cat ${env.control.login.passwordFile})
        export ${toVarName "${name}_call"}=$(cat ${env.call.login.passwordFile})
      '') cfg.xmppEnvironments))
      + ''
        ${pkgs.jre_headless}/bin/java -Djava.util.logging.config.file=${./logging.properties-journal} -Dconfig.file=${configFile} -jar ${pkgs.jibri}/share/jibri/jibri.jar --config /var/lib/jibri/jibri.json
      '';


      environment.HOME = "/var/lib/jibri";

      serviceConfig = {
        Type = "simple";

        User = "jibri";
        Group = "jibri";
        Restart = "always";
        RestartPreventExitStatus = 255;

        StateDirectory = "jibri";
      };
    };

    # Configure Chromium to not show the "Chrome is being controlled by automatic test software" message.
    environment.etc."chromium/policies/managed/managed_policies.json".text = builtins.toJSON { CommandLineFlagSecurityWarningsEnabled = false; };

    boot = {
      extraModprobeConfig = ''
        options snd-aloop enable=1,1,1,1,1,1,1,1
      '';
      kernelModules = [ "snd-aloop" ];
    };
  };

  meta.maintainers = with lib.maintainers; [ ];
}
