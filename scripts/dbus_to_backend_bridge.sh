#!/usr/bin/env bash
set -euo pipefail

BACKEND_HOST="${BACKEND_HOST:-localhost}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
IGNORE_APPS_REGEX="${IGNORE_APPS_REGEX:-^(Cortex|Code Cortex|Popup Tester)$}"
QUEUE_FILE="${DBUS_BRIDGE_QUEUE_FILE:-/tmp/code_cortex_dbus_bridge_queue.ndjson}"

if ! command -v dbus-monitor >/dev/null 2>&1; then
  echo "dbus_to_backend_bridge.sh: dbus-monitor is required" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "dbus_to_backend_bridge.sh: curl is required" >&2
  exit 1
fi

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/ }"
  value="${value//$'\n'/ }"
  printf '%s' "$value"
}

send_to_backend() {
  local app="$1"
  local summary="$2"
  local body="$3"
  local priority="$4"

  # Normalize browser-origin web app notifications so WhatsApp triggers reliably.
  local merged_lc
  merged_lc="$(printf '%s %s %s' "$app" "$summary" "$body" | tr '[:upper:]' '[:lower:]')"
  if [[ "$merged_lc" == *"whatsapp"* ]]; then
    app="WhatsApp Web"
    if [[ "$priority" != "EMERGENCY" ]]; then
      priority="HIGH"
    fi
  elif [[ "$merged_lc" == *"discord"* ]]; then
    app="Discord Web"
  fi

  if [[ -n "$IGNORE_APPS_REGEX" ]] && [[ "$app" =~ $IGNORE_APPS_REGEX ]]; then
    return
  fi

  local sender="$app"
  local content="$summary"
  if [[ -n "$body" ]]; then
    if [[ -n "$content" ]]; then
      content+=" - $body"
    else
      content="$body"
    fi
  fi

  [[ -z "$content" ]] && return

  local app_package
  app_package="$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9._-' )"
  [[ -z "$app_package" ]] && app_package="desktop.notify"

  local payload
  payload="{\"content\":\"$(json_escape "$content")\",\"app_name\":\"$(json_escape "$app")\",\"app_package\":\"$(json_escape "$app_package")\",\"sender_name\":\"$(json_escape "$sender")\",\"priority\":\"$(json_escape "$priority")\"}"

  flush_queue

  if ! post_payload "$payload"; then
    enqueue_payload "$payload"
  fi
}

post_payload() {
  local payload="$1"
  curl -sS -f -m 3 -X POST "http://${BACKEND_HOST}:${BACKEND_PORT}/api/notifications/ingest" \
    -H "Content-Type: application/json" \
    -d "$payload" >/dev/null
}

enqueue_payload() {
  local payload="$1"
  printf '%s\n' "$payload" >> "$QUEUE_FILE"
}

flush_queue() {
  if [[ ! -s "$QUEUE_FILE" ]]; then
    return 0
  fi

  local -a queued
  mapfile -t queued < "$QUEUE_FILE" || return 0
  : > "$QUEUE_FILE"

  local i
  for (( i=0; i<${#queued[@]}; i++ )); do
    if ! post_payload "${queued[$i]}"; then
      local j
      for (( j=i; j<${#queued[@]}; j++ )); do
        printf '%s\n' "${queued[$j]}" >> "$QUEUE_FILE"
      done
      return
    fi
  done

}

trim_string_line() {
  local line="$1"
  line="${line#*string \"}"
  line="${line%\"}"
  line="${line//\\\"/\"}"
  printf '%s' "$line"
}

trim_variant_string_line() {
  local line="$1"
  line="${line#*variant             string \"}"
  line="${line%\"}"
  line="${line//\\\"/\"}"
  printf '%s' "$line"
}

in_notify=0
in_portal=0
string_idx=0
app=""
summary=""
body=""
priority="MEDIUM"
notify_expect_desktop_entry=0
portal_string_idx=0
portal_app=""
portal_title=""
portal_body=""
portal_expect_title=0
portal_expect_body=0

flush_portal_event() {
  if [[ "$in_portal" -eq 1 ]]; then
    local app_name="$portal_app"
    [[ -z "$app_name" ]] && app_name="Browser"

    local merged_lc
    merged_lc="$(printf '%s %s' "$portal_title" "$portal_body" | tr '[:upper:]' '[:lower:]')"
    if [[ "$merged_lc" == *"whatsapp"* ]]; then
      app_name="WhatsApp Web"
    elif [[ "$merged_lc" == *"discord"* ]]; then
      app_name="Discord Web"
    fi

    send_to_backend "$app_name" "$portal_title" "$portal_body" "MEDIUM"
  fi
  in_portal=0
  portal_string_idx=0
  portal_app=""
  portal_title=""
  portal_body=""
  portal_expect_title=0
  portal_expect_body=0
}

while IFS= read -r line; do
  if [[ "$line" == method\ call\ time=* ]]; then
    if [[ "$in_portal" -eq 1 ]] && [[ "$line" != *"member=AddNotification"* ]]; then
      flush_portal_event
    fi
  fi

  if [[ "$line" == *"member=Notify"* ]]; then
    if [[ "$in_portal" -eq 1 ]]; then
      flush_portal_event
    fi
    in_notify=1
    string_idx=0
    app=""
    summary=""
    body=""
    priority="MEDIUM"
    notify_expect_desktop_entry=0
    continue
  fi

  if [[ "$line" == *"member=AddNotification"* ]]; then
    flush_portal_event
    in_portal=1
    portal_string_idx=0
    portal_app=""
    portal_title=""
    portal_body=""
    portal_expect_title=0
    portal_expect_body=0
    continue
  fi

  if [[ "$in_notify" -eq 1 ]]; then
    if [[ "$line" == *"string \"desktop-entry\""* ]]; then
      notify_expect_desktop_entry=1
      continue
    fi

    if [[ "$notify_expect_desktop_entry" -eq 1 ]] && [[ "$line" == *"variant             string \""* ]]; then
      value="$(trim_variant_string_line "$line")"
      case "$value" in
        org.mozilla.firefox|firefox|Firefox) app="Firefox" ;;
        io.gitlab.librewolf-community|librewolf|LibreWolf) app="LibreWolf" ;;
        com.discordapp.Discord|discord|Discord) app="Discord" ;;
        org.chromium.Chromium|chromium|Chromium|google-chrome|Google-chrome|Google-Chrome) app="Browser" ;;
      esac
      notify_expect_desktop_entry=0
      continue
    fi

    if [[ "$line" == *"string \""* ]]; then
      value="$(trim_string_line "$line")"
      string_idx=$((string_idx + 1))
      case "$string_idx" in
        1) app="$value" ;;
        3) summary="$value" ;;
        4) body="$value" ;;
      esac
      continue
    fi

    if [[ "$line" == *"byte "* ]]; then
      byte_value="${line##*byte }"
      byte_value="${byte_value%%[^0-9]*}"
      if [[ -n "$byte_value" ]]; then
        if (( byte_value >= 2 )); then
          priority="EMERGENCY"
        elif (( byte_value == 0 )); then
          priority="LOW"
        else
          priority="MEDIUM"
        fi
      fi
      continue
    fi

    if [[ "$line" =~ (^|[[:space:]])int32[[:space:]] ]] && [[ "$string_idx" -ge 4 ]]; then
      [[ -z "$app" ]] && app="Browser"
      send_to_backend "$app" "$summary" "$body" "$priority"
      in_notify=0
    fi
    continue
  fi

  if [[ "$in_portal" -eq 1 ]]; then
    if [[ "$line" =~ ^[[:space:]]*\]$ ]]; then
      flush_portal_event
      continue
    fi

    if [[ "$line" == *"string \""* ]]; then
      value="$(trim_string_line "$line")"
      if [[ "$portal_expect_title" -eq 1 ]]; then
        portal_title="$value"
        portal_expect_title=0
        continue
      fi
      if [[ "$portal_expect_body" -eq 1 ]]; then
        portal_body="$value"
        portal_expect_body=0
        continue
      fi

      portal_string_idx=$((portal_string_idx + 1))
      if [[ "$portal_string_idx" -eq 1 ]]; then
        # AddNotification first string is notification id, not app id.
        portal_app="Browser"
      fi

      if [[ "$value" == "title" ]]; then
        portal_expect_title=1
      elif [[ "$value" == "body" ]]; then
        portal_expect_body=1
      fi
      continue
    fi

    if [[ "$line" == *"variant             string \""* ]]; then
      value="$(trim_variant_string_line "$line")"
      if [[ "$portal_expect_title" -eq 1 ]]; then
        portal_title="$value"
        portal_expect_title=0
      elif [[ "$portal_expect_body" -eq 1 ]]; then
        portal_body="$value"
        portal_expect_body=0
      fi
      continue
    fi

    if [[ "$line" == *"member=Notify"* ]]; then
      flush_portal_event
    fi
  fi
done < <(dbus-monitor --session \
  "type='method_call',interface='org.freedesktop.Notifications',member='Notify'" \
  "type='method_call',interface='org.freedesktop.portal.Notification',member='AddNotification'" \
  2>/dev/null)

flush_portal_event
