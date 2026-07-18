import json
import os
import sys
import time
import urllib.error
import urllib.request

API_KEY = os.environ.get("LATCHSHOT_API_KEY")
TARGET_URL = sys.argv[1] if len(sys.argv) > 1 else "https://example.com"
OUTPUT_PATH = sys.argv[2] if len(sys.argv) > 2 else "latchshot.png"

if not API_KEY:
    raise RuntimeError("Set LATCHSHOT_API_KEY to your trial or paid key.")


def render(payload, retries=2):
    body = json.dumps(payload).encode("utf-8")
    retryable = {429, 502, 503, 504}

    for attempt in range(retries + 1):
        request = urllib.request.Request(
            "https://latchshot.fly.dev/v1/render",
            data=body,
            headers={
                "Authorization": f"Bearer {API_KEY}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                headers = {name.lower(): value for name, value in response.headers.items()}
                return response.read(), headers
        except urllib.error.HTTPError as error:
            if attempt < retries and error.code in retryable:
                retry_after = error.headers.get("Retry-After")
                delay = min(int(retry_after), 10) if retry_after and retry_after.isdigit() else 0.5 * (2**attempt)
                error.close()
                time.sleep(delay)
                continue
            detail = error.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Latchshot {error.code}: {detail}") from error
        except urllib.error.URLError:
            if attempt >= retries:
                raise
            time.sleep(0.5 * (2**attempt))

    raise RuntimeError("Latchshot retry loop exhausted")


content, headers = render(
    {
        "url": TARGET_URL,
        "kind": "screenshot",
        "format": "png",
        "width": 1440,
        "height": 900,
    }
)

with open(OUTPUT_PATH, "wb") as output:
    output.write(content)

print(
    json.dumps(
        {
            "outputPath": OUTPUT_PATH,
            "bytes": len(content),
            "contentType": headers.get("content-type"),
            "renderMs": headers.get("x-latchshot-render-ms"),
            "remaining": headers.get("x-quota-remaining"),
        }
    )
)
