"""Bounded, on-demand throughput estimate against Cloudflare."""
import http.client
import json
import re
import statistics
import subprocess
import sys
import time


def emit(**data):
    print(json.dumps(data), flush=True)


def nmcli_rows(*args):
    output = subprocess.check_output(
        ["nmcli", "-t", "-f", *args], text=True,
        stderr=subprocess.DEVNULL, timeout=2,
    )
    return [
        [re.sub(r"\\(.)", r"\1", field) for field in re.split(r"(?<!\\):", line)]
        for line in output.splitlines()
    ]


def connection(include_devices=False):
    try:
        rows = [row for row in nmcli_rows("UUID,TYPE,DEVICE,NAME", "connection", "show", "--active")
                if len(row) == 4 and row[1] != "loopback"]
        result = {}
        if rows:
            physical = next((row for row in rows if row[1] in ("802-3-ethernet", "802-11-wireless")), rows[0])
            result = {"key": "|".join(sorted(row[0] for row in rows)), "name": physical[3]}
        if include_devices:
            active = {row[2] for row in rows if row[1] == "802-3-ethernet"}
            result["ethernet"] = [
                {"device": device, "active": device in active}
                for device, kind in nmcli_rows("DEVICE,TYPE", "device", "status")
                if kind == "ethernet"
            ]
        return result
    except (OSError, subprocess.SubprocessError):
        return {}


def request(client, size, upload=False):
    path = "/__up" if upload else f"/__down?bytes={size}"
    body = bytes(size) if upload else None
    started = time.monotonic()
    client.request("POST" if upload else "GET", path, body, {"Cache-Control": "no-cache"})
    with client.getresponse() as response:
        if response.status != 200:
            raise ValueError("unexpected HTTP response")
        headers_at = time.monotonic()
        received = 0
        while chunk := response.read(65536):
            received += len(chunk)
            if received > (65536 if upload else size) or time.monotonic() - started > 15:
                raise ValueError("transfer exceeded its limit")
    if not upload and received != size:
        raise ValueError("incomplete transfer")
    return headers_at - started, time.monotonic() - started


def measure(client, sizes, upload=False):
    for size in sizes:
        _, elapsed = request(client, size, upload)
        if elapsed >= 0.7:
            break
    return size * 8 / elapsed / 1_000_000


def main():
    if sys.argv[1:] == ["connection"]:
        emit(**connection(include_devices=True))
        return
    before = connection()
    client = http.client.HTTPSConnection("speed.cloudflare.com", timeout=8)
    try:
        emit(stage="latency")
        client.connect()
        latency = statistics.median(request(client, 0)[0] for _ in range(3)) * 1000
        emit(stage="download")
        download = measure(client, (1_000_000, 5_000_000, 20_000_000))
        emit(stage="upload")
        upload = measure(client, (250_000, 1_000_000, 5_000_000), upload=True)
        if before.get("key") != connection().get("key"):
            emit(error="Подключение изменилось. Повтори замер.")
        else:
            emit(latency=latency, download=download, upload=upload, connection=before)
    except (OSError, http.client.HTTPException, ValueError):
        emit(error="Не удалось выполнить замер. Проверь подключение.")
    finally:
        client.close()


if __name__ == "__main__":
    main()
