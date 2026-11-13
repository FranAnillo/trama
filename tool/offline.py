"""Genera el service worker para una compilación JS con recursos locales."""
from pathlib import Path
import hashlib
import json

root = Path("build/web")
files = sorted(p for p in root.rglob("*") if p.is_file()
               and "content" not in p.relative_to(root).parts and not p.name.startswith(".") and p.name not in {"offline.js", "diseno.html", "revision-docente.html"} and p.suffix not in {".symbols", ".map"}
               and not any(s in p.name for s in ("skwasm", "wimp")))
h = hashlib.sha256(b'trama-shell-v2-redirect-safe')
for path in files:
    h.update(path.relative_to(root).as_posix().encode())
    h.update(hashlib.sha256(path.read_bytes()).digest())
worker = """
const prefix = 'trama-shell-' + new URL(self.registration.scope).pathname + '-';
const cacheName = prefix + VERSION;
const files = FILES.map(p => new URL(p, self.registration.scope).href);
self.addEventListener('install', event => {
  event.waitUntil(caches.open(cacheName).then(cache => cache.addAll(files)));
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith(prefix) && key !== cacheName) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (!url.href.startsWith(self.registration.scope)) return;
  const key = url.pathname === new URL(self.registration.scope).pathname
    ? new URL('index.html', self.registration.scope).href : url.origin + url.pathname;
  if (files.includes(key)) event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    const saved = await cache.match(key);
    if (!saved) return fetch(event.request);
    // Static hosts can redirect /index.html to /. A redirected cached
    // response is rejected for a navigation whose redirect mode is manual.
    if (event.request.mode === 'navigate' && saved.redirected) {
      return new Response(saved.body, {
        status: saved.status, statusText: saved.statusText, headers: saved.headers
      });
    }
    return saved;
  })());
});
"""
(root / "offline.js").write_text(worker.replace("VERSION", json.dumps(h.hexdigest()[:16]))
    .replace("FILES", json.dumps([p.relative_to(root).as_posix() for p in files])))
print(f"Paquete offline: {len(files)} archivos, {sum(p.stat().st_size for p in files)/1024**2:.1f} MiB.")
