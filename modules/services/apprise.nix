{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.apprise;
  globals = import ../../policy/globals.nix;
  secretHelpers = import ../../lib/secrets.nix { inherit lib; };

  # Declarative runtime config, read by apprise-notify at execution time.
  notifyConfig = {
    token_file = "/run/secrets/apprise/telegram_bot_token";
    chat_id = cfg.telegram.chatId;
    topics = cfg.telegram.topics;
  };
in
{
  options.services.apprise = {
    enable = lib.mkEnableOption "apprise notification infrastructure";

    secretFiles.host = secretHelpers.mkSecretFileOption "apprise-notifications";

    telegram = {
      chatId = lib.mkOption {
        type = lib.types.str;
        default = globals.notifications.telegram.chatId;
        description = "Telegram supergroup chat ID for notifications.";
      };

      topics = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = globals.notifications.telegram.topics;
        description = "Mapping of notification tiers to Telegram topic IDs within the supergroup.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (secretHelpers.mkRequiredSecretAssertion {
        inherit (cfg)
          enable
          ;
        file = cfg.secretFiles.host;
        feature = "services.apprise";
        label = "secretFiles.host";
      })
      {
        assertion = cfg.telegram.chatId != "REPLACE_GROUP_CHAT_ID" && cfg.telegram.chatId != "";
        message = "services.apprise.telegram.chatId must be set to a real Telegram supergroup chat ID.";
      }
      {
        assertion = cfg.telegram.topics != { };
        message = "services.apprise.telegram.topics must be configured with at least one tier.";
      }
    ];

    # JSON config consumed by apprise-notify at runtime.
    environment.etc."apprise/notify.json" = {
      mode = "0444";
      text = builtins.toJSON notifyConfig;
    };

    environment.systemPackages = [
      pkgs.apprise
      pkgs.jq
      (pkgs.writeShellScriptBin "apprise-notify" ''
        set -euo pipefail

        if [ "''${1:-}" = "-v" ]; then
          set -x
          shift
        fi

        tier="''${1:?Usage: apprise-notify [-v] <tier> [title] [type]}"
        title="''${2:-Apprise notification}"
        type="''${3:-info}"
        config="/etc/apprise/notify.json"

        token_file="$(jq -r .token_file "$config")"
        chat_id="$(jq -r .chat_id "$config")"
        topic="$(jq -r --arg t "$tier" '.topics[$t] // empty' "$config")"

        if [ -z "$topic" ]; then
          known="$(jq -r '.topics | keys | join(", ")' "$config")"
          printf "Unknown tier: %s\nKnown: %s\n" "$tier" "$known" >&2
          exit 1
        fi

        url="tgram://''${chat_id}:''${topic}"
        printf "[apprise-notify] tier=%s topic=%s url=%s\n" "$tier" "$topic" "$url" >&2

        export TITLE="$title"
        cat | timeout 30 apprise -v \
          -t "$TITLE" \
          -n "$type" \
          "tgram://$(cat "$token_file")/''${chat_id}:''${topic}"
      '')
    ];

    users.groups.apprise = { };

    sops.secrets."apprise/telegram_bot_token" = {
      sopsFile = cfg.secretFiles.host;
      key = "telegram_bot_token";
      path = "/run/secrets/apprise/telegram_bot_token";
      owner = "root";
      group = "apprise";
      mode = "0440";
    };
  };
}
