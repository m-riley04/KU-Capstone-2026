#!/usr/bin/env python3
"""
Periodically fetch notifications from the backend API and forward them to notify.py.

API endpoint format:
http://172.232.9.56:3000/notifications/<USER_ID>

USER_ID is loaded from notification_settings.json, which is written by the
Flutter settings page.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import time
from collections import deque
from datetime import datetime, timezone
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

from notify import notify

API_BASE = "http://172.232.9.56:3000/notifications"
SETTINGS_PATH = os.path.join(os.path.dirname(__file__), "notification_settings.json")
STATE_PATH = os.path.join(os.path.dirname(__file__), ".notification_poll_state.json")


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _load_user_id() -> str:
    if not os.path.exists(SETTINGS_PATH):
        return ""

    try:
        with open(SETTINGS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return ""

    user_id = data.get("user_id", "")
    return str(user_id).strip()


def _load_seen_tokens(limit: int = 200) -> deque[str]:
    if not os.path.exists(STATE_PATH):
        return deque(maxlen=limit)

    try:
        with open(STATE_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        tokens = data.get("seen_tokens", [])
        if not isinstance(tokens, list):
            tokens = []
        return deque((str(t) for t in tokens), maxlen=limit)
    except (OSError, json.JSONDecodeError):
        return deque(maxlen=limit)


def _save_seen_tokens(tokens: deque[str]) -> None:
    payload = {"seen_tokens": list(tokens)}
    with open(STATE_PATH, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def _build_url(user_id: str) -> str:
    return f"{API_BASE}/{user_id}"


def _fetch_notifications(url: str, timeout: float) -> list[dict[str, Any]]:
    with urlopen(url, timeout=timeout) as response:
        content_type = response.headers.get("Content-Type", "")
        raw = response.read().decode("utf-8")

    if "application/json" not in content_type and not raw.strip().startswith(("{", "[")):
        raise ValueError("API response is not JSON")

    parsed = json.loads(raw)

    if isinstance(parsed, list):
        return [item for item in parsed if isinstance(item, dict)]

    if isinstance(parsed, dict):
        if isinstance(parsed.get("notifications"), list):
            return [item for item in parsed["notifications"] if isinstance(item, dict)]
        return [parsed]

    return []


def _normalize_notification(raw_notif: dict[str, Any]) -> dict[str, Any] | None:
    if raw_notif.get("notifType") == "base" and isinstance(raw_notif.get("data"), dict):
        source = str(
            raw_notif.get("fromSource")
            or raw_notif.get("from_source")
            or raw_notif["data"].get("fromSource")
            or raw_notif["data"].get("from_source")
            or raw_notif.get("source")
            or "API"
        )
        data = raw_notif["data"]
        return {
            "notifType": "base",
            "fromSource": source,
            "data": {
                "timestamp": str(data.get("timestamp") or _utc_now_iso()),
                "media": str(data.get("media") or ""),
                "headline": str(data.get("headline") or data.get("title") or "Notification"),
                "info": str(data.get("info") or data.get("message") or ""),
                "seemore": str(
                    data.get("seemore")
                    or data.get("seeMore")
                    or data.get("see_more")
                    or data.get("url")
                    or ""
                ),
            },
        }

    if isinstance(raw_notif.get("notification"), dict):
        nested = raw_notif["notification"]
        if nested.get("notifType") == "base" and isinstance(nested.get("data"), dict):
            return _normalize_notification(nested)

    source = str(
        raw_notif.get("fromSource")
        or raw_notif.get("from_source")
        or raw_notif.get("source")
        or "API"
    )

    data = {
        "timestamp": str(raw_notif.get("timestamp") or _utc_now_iso()),
        "media": str(raw_notif.get("media") or ""),
        "headline": str(raw_notif.get("headline") or raw_notif.get("title") or "Notification"),
        "info": str(raw_notif.get("info") or raw_notif.get("message") or ""),
        "seemore": str(
            raw_notif.get("seemore")
            or raw_notif.get("seeMore")
            or raw_notif.get("see_more")
            or raw_notif.get("url")
            or ""
        ),
    }

    return {
        "notifType": "base",
        "fromSource": source,
        "data": data,
    }


def _token_for_notification(notification: dict[str, Any]) -> str:
    canonical = json.dumps(notification, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def run_poller(interval_seconds: float, timeout_seconds: float) -> None:
    seen_tokens = _load_seen_tokens()
    print(f"Notification API poller started. Interval: {interval_seconds}s")

    while True:
        user_id = _load_user_id()
        if not user_id:
            print("No user_id found in notification_settings.json. Waiting for settings update...")
            time.sleep(interval_seconds)
            continue

        url = _build_url(user_id)

        try:
            notifications = _fetch_notifications(url, timeout=timeout_seconds)
            new_count = 0

            for item in notifications:
                normalized = _normalize_notification(item)
                if normalized is None:
                    continue

                token = _token_for_notification(normalized)
                if token in seen_tokens:
                    continue

                if notify(normalized):
                    seen_tokens.append(token)
                    new_count += 1

            if new_count:
                _save_seen_tokens(seen_tokens)
                print(f"Sent {new_count} new notification(s) for user_id={user_id}")

        except HTTPError as exc:
            print(f"HTTP error while fetching notifications ({url}): {exc.code} {exc.reason}")
        except URLError as exc:
            print(f"Network error while fetching notifications ({url}): {exc.reason}")
        except json.JSONDecodeError as exc:
            print(f"Failed to decode API response JSON: {exc}")
        except Exception as exc:
            print(f"Unexpected poller error: {exc}")

        time.sleep(interval_seconds)


def main() -> None:
    parser = argparse.ArgumentParser(description="Poll notification API and forward to notify.py")
    parser.add_argument("--interval", type=float, default=5.0, help="Polling interval in seconds (default: 5)")
    parser.add_argument("--timeout", type=float, default=10.0, help="HTTP timeout in seconds (default: 10)")
    args = parser.parse_args()

    if args.interval <= 0:
        raise ValueError("--interval must be greater than 0")

    if args.timeout <= 0:
        raise ValueError("--timeout must be greater than 0")

    try:
        run_poller(interval_seconds=args.interval, timeout_seconds=args.timeout)
    except KeyboardInterrupt:
        print("\nNotification API poller stopped.")


if __name__ == "__main__":
    main()
