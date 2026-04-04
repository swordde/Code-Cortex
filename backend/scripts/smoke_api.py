import json
import urllib.error
import urllib.request
from datetime import datetime

BASE = "http://localhost:8080"


def req(method, path, data=None):
    url = BASE + path
    body = None
    headers = {}
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"

    request = urllib.request.Request(url, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            text = response.read().decode()
            payload = json.loads(text) if text else None
            return response.status, payload
    except urllib.error.HTTPError as error:
        text = error.read().decode()
        try:
            payload = json.loads(text) if text else None
        except json.JSONDecodeError:
            payload = text
        return error.code, payload


def main():
    results = []

    status, payload = req(
        "POST",
        "/api/notifications/ingest",
        {
            "content": "smoke pass urgent ping",
            "app_name": "WhatsApp",
            "app_package": "com.whatsapp",
            "sender_name": "QA Bot",
        },
    )
    notification_id = payload.get("id") if isinstance(payload, dict) else None
    results.append(("Dashboard ingest", status == 201, status))

    status, payload = req("GET", "/api/notifications")
    results.append(("Dashboard list notifications", status == 200 and isinstance(payload, list), status))

    if notification_id:
        status, _ = req("PUT", f"/api/notifications/{notification_id}/read")
        results.append(("Dashboard mark read", status == 200, status))

        status, _ = req("PUT", f"/api/notifications/{notification_id}/action")
        results.append(("Dashboard mark action", status == 200, status))

    status, payload = req("GET", "/api/modes")
    results.append(("Custom mode load modes", status == 200 and isinstance(payload, list), status))

    mode_name = "smoke_mode_" + datetime.now().strftime("%H%M%S")
    status, payload = req(
        "POST",
        "/api/modes",
        {
            "name": mode_name,
            "app_caps": [],
            "keywords": [],
            "contact_ids": [],
            "cortex_level": "off",
            "schedule_start": "",
            "schedule_end": "",
            "schedule_days": [],
        },
    )
    mode_id = payload.get("id") if isinstance(payload, dict) else None
    results.append(("Custom mode create mode", status == 201 and bool(mode_id), status))

    if mode_id:
        status, _ = req("PUT", f"/api/modes/{mode_id}/activate")
        results.append(("Custom mode activate mode", status == 200, status))

    status, payload = req(
        "POST",
        "/api/rules",
        {
            "type": "keyword",
            "keywords": ["smoke-keyword"],
            "priority": "HIGH",
            "order": 0,
            "enabled": True,
        },
    )
    rule_id = payload.get("id") if isinstance(payload, dict) else None
    results.append(("Custom mode create rule", status == 201 and bool(rule_id), status))

    if rule_id:
        status, _ = req("DELETE", f"/api/rules/{rule_id}")
        results.append(("Custom mode delete rule", status == 204, status))

    status, payload = req("GET", "/api/cortex/config")
    results.append(("Cortex get config", status == 200 and isinstance(payload, dict), status))

    status, _ = req("PUT", "/api/cortex/config", {"enabled": True, "auto_reply": True, "scope": "global"})
    results.append(("Cortex update config", status == 200, status))

    status, payload = req("POST", "/api/cortex/replies", {"body": "smoke reply", "tone": "casual", "is_default": False})
    reply_id = payload.get("id") if isinstance(payload, dict) else None
    results.append(("Cortex create reply", status == 201 and bool(reply_id), status))

    status, payload = req("GET", "/api/cortex/replies")
    results.append(("Cortex list replies", status == 200 and isinstance(payload, list), status))

    if reply_id:
        status, _ = req("DELETE", f"/api/cortex/replies/{reply_id}")
        results.append(("Cortex delete reply", status == 204, status))

    status, payload = req("GET", "/api/cortex/scheduled")
    results.append(("Cortex list scheduled", status == 200 and isinstance(payload, list), status))

    status, payload = req("GET", "/api/cortex/activity")
    results.append(("Cortex list activity", status == 200 and isinstance(payload, list), status))

    status, payload = req("GET", "/api/profile")
    results.append(("Profile get profile", status == 200 and isinstance(payload, dict), status))

    status, _ = req(
        "PUT",
        "/api/profile",
        {
            "display_name": "Smoke User",
            "avatar_path": "",
            "notif_permission": True,
            "theme_mode": "system",
            "linked_accounts": ["com.whatsapp"],
        },
    )
    results.append(("Profile update profile", status == 200, status))

    if mode_id:
        status, _ = req("DELETE", f"/api/modes/{mode_id}")
        results.append(("Cleanup smoke mode", status == 204, status))

    print("--- Smoke API Results ---")
    for name, ok, status in results:
        print(f"{'PASS' if ok else 'FAIL'} | {name} | HTTP {status}")

    failed = [r for r in results if not r[1]]
    print(f"SUMMARY: {len(results) - len(failed)}/{len(results)} passed")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
