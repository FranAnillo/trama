#!/bin/bash
cd "$(dirname "$0")" || exit 1
python3 - <<'PY'
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.request import urlopen
import webbrowser

root = Path("build/web")
url = "http://127.0.0.1:8783/"
if not (root / "offline.js").is_file():
    raise SystemExit("Primero prepara la versión web con bash tool/web.sh.")
try:
    server = ThreadingHTTPServer(("127.0.0.1", 8783), partial(SimpleHTTPRequestHandler, directory=str(root)))
except OSError:
    try:
        with urlopen(url + "manifest.json", timeout=2) as response:
            import json
            if json.load(response).get("short_name") != "Trama":
                raise ValueError("otro servicio")
    except Exception:
        raise SystemExit("El puerto 8783 está ocupado por otro servicio.")
    webbrowser.open(url)
else:
    print("Trama está disponible en", url, "· Control+C cierra el servidor.", flush=True)
    webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
PY
