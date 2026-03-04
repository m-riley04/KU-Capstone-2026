'''
Backend notification client for polypod.

Polls the backend endpoint /notifications/{userId} and forwards
notifications through notify.notify so Flutter can render them.
'''

import json
import os
import time
from urllib import error, parse, request

from notify import notify


def fetch_notifications_from_backend(base_url, user_id, timeout_seconds=10):
    """
    Fetch notifications for a specific user from backend endpoint:
    GET /notifications/{userId}

    Returns:
        list: notification dictionaries (empty list when no content)
    Raises:
        RuntimeError: when request fails or payload is invalid
    """
    normalized_base = base_url.rstrip('/')
    encoded_user_id = parse.quote(str(user_id), safe='')
    url = f"{normalized_base}/notifications/{encoded_user_id}"

    req = request.Request(url=url, method='GET')

    try:
        with request.urlopen(req, timeout=timeout_seconds) as response:
            status = response.getcode()

            if status == 204:
                return []

            body = response.read().decode('utf-8')
            if not body.strip():
                return []

            payload = json.loads(body)

            if payload is None:
                return []

            if isinstance(payload, list):
                return payload

            if isinstance(payload, dict) and 'notifications' in payload and isinstance(payload['notifications'], list):
                return payload['notifications']

            raise RuntimeError(f"Unexpected notification response format from {url}")

    except error.HTTPError as exc:
        if exc.code == 204:
            return []

        message = exc.read().decode('utf-8', errors='ignore')
        raise RuntimeError(f"Backend returned HTTP {exc.code} for {url}: {message}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"Unable to reach backend at {url}: {exc.reason}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON returned by backend at {url}: {exc}") from exc


def pull_and_send_notifications(base_url, user_id, timeout_seconds=10):
    """
    Pull notifications from backend and forward each to Flutter.

    Returns:
        int: number of notifications forwarded for debuggin
    """
    notifications = fetch_notifications_from_backend(base_url, user_id, timeout_seconds)

    sent_count = 0
    for notification in notifications:
        if notify(notification):
            sent_count += 1

    return sent_count


def poll_backend_notifications(base_url, user_id, interval_seconds=15, timeout_seconds=10):
    """
    Continuously poll backend notifications for a user.
    """
    print(f"Starting notification poller for user {user_id} at {base_url}")
    print(f"Polling endpoint: {base_url.rstrip('/')}/notifications/{user_id}")

    while True:
        try:
            sent_count = pull_and_send_notifications(base_url, user_id, timeout_seconds)
            if sent_count > 0:
                #this is intended as a dummy check for making sure all the notifs actually appear on device w
                #multiuple notifs
                print(f"Forwarded {sent_count} notification(s) to Flutter")
        except Exception as exc:
            print(f"Polling error: {exc}")

        time.sleep(interval_seconds)


# idk where we wanna pull these config values from, so just use env vars for now
# with defaults that make sense for local development
if __name__ == '__main__':
    backend_url = os.getenv('POLYPOD_BACKEND_URL', 'http://localhost:3000')
    user_id = os.getenv('POLYPOD_USER_ID', '1')
    poll_interval = float(os.getenv('POLYPOD_NOTIFICATION_POLL_INTERVAL', '15'))
    timeout_seconds = float(os.getenv('POLYPOD_BACKEND_TIMEOUT_SECONDS', '10'))

    poll_backend_notifications(
        base_url=backend_url,
        user_id=user_id,
        interval_seconds=poll_interval,
        timeout_seconds=timeout_seconds,
    )
