import json
import urllib.request
import urllib.error
from datetime import datetime, timedelta

BASE = "http://localhost:8080"


def req(method, path, data=None):
    body = None
    headers = {}
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(BASE + path, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            text = response.read().decode()
            payload = json.loads(text) if text else None
            return response.status, payload
    except urllib.error.HTTPError as error:
        text = error.read().decode()
        payload = json.loads(text) if text else text
        return error.code, payload


def main():
    checks = []

    status, mode = req("POST", "/api/modes", {
        "name": f"custom_{datetime.now().strftime('%H%M%S')}",
        "app_caps": [{"app_package": "com.whatsapp", "max_priority": "HIGH"}],
        "keywords": ["urgent"],
        "contact_ids": ["Mom"],
        "cortex_level": "off",
        "schedule_start": "",
        "schedule_end": "",
        "schedule_days": []
    })
    checks.append(("create mode", status == 201, status, mode))

    mode_id = mode.get("id") if isinstance(mode, dict) else ""

    status, rule_contact = req("POST", "/api/rules", {
        "type": "contact", "contact_id": "Mom", "priority": "HIGH", "order": 0, "enabled": True
    })
    checks.append(("create contact rule", status == 201, status, rule_contact))

    status, rule_keyword = req("POST", "/api/rules", {
        "type": "keyword", "keywords": ["urgent"], "priority": "EMERGENCY", "order": 0, "enabled": True
    })
    checks.append(("create keyword rule", status == 201, status, rule_keyword))

    status, updated = req("PUT", f"/api/modes/{mode_id}", {
        "name": mode.get("name", "custom"),
        "is_active": False,
        "is_preset": False,
        "app_caps": [{"app_package": "com.whatsapp", "max_priority": "HIGH"}, {"app_package": "com.google.android.gm", "max_priority": "HIGH"}],
        "keywords": ["urgent", "asap"],
        "contact_ids": ["Mom", "Boss"],
        "cortex_level": "off",
        "schedule_start": "",
        "schedule_end": "",
        "schedule_days": []
    })
    checks.append(("update mode with apps/contacts/keywords", status == 200, status, updated))

    status, fetched_modes = req("GET", "/api/modes")
    persisted = False
    if isinstance(fetched_modes, list):
        for m in fetched_modes:
            if m.get("id") == mode_id:
                persisted = len(m.get("app_caps", [])) >= 2 and len(m.get("keywords", [])) >= 2 and len(m.get("contact_ids", [])) >= 2
                break
    checks.append(("mode persistence", persisted, status, fetched_modes))

    status, _ = req("PUT", "/api/cortex/config", {"enabled": True, "auto_reply": True, "scope": "global"})
    checks.append(("enable auto reply", status == 200, status, None))

    status, cfg = req("GET", "/api/cortex/config")
    cfg_ok = isinstance(cfg, dict) and cfg.get("auto_reply") is True and cfg.get("enabled") is True
    checks.append(("auto reply persisted", cfg_ok, status, cfg))

    status, reply = req("POST", "/api/cortex/replies", {"body": "I will reply later", "tone": "casual", "is_default": False})
    checks.append(("create reply", status == 201, status, reply))

    schedule_at = (datetime.utcnow() + timedelta(minutes=10)).isoformat() + "Z"
    status, scheduled = req("POST", "/api/cortex/scheduled", {
        "notification_id": "manual",
        "draft_body": "Ping me in 10 mins",
        "scheduled_at": schedule_at
    })
    checks.append(("create scheduled message", status == 201, status, scheduled))

    status, scheduled_list = req("GET", "/api/cortex/scheduled")
    has_scheduled = isinstance(scheduled_list, list) and len(scheduled_list) > 0
    checks.append(("list scheduled messages", has_scheduled, status, scheduled_list))

    for name, ok, st, _ in checks:
        print(f"{'PASS' if ok else 'FAIL'} | {name} | HTTP {st}")

    fails = [c for c in checks if not c[1]]
    print(f"SUMMARY: {len(checks)-len(fails)}/{len(checks)} passed")
    if fails:
        for item in fails:
            print("FAILED_DETAIL:", item[0], item[3])


if __name__ == "__main__":
    main()
