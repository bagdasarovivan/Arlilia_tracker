/* Arlilia tracker — service worker.
   Caches the static app shell so the UI opens instantly on repeat visits
   (and keeps working if the network briefly drops), while all real data
   calls (Supabase) always go straight to the network — never cached. Bump
   CACHE_NAME whenever the shell itself changes, so clients pick up the
   new version instead of being stuck on a stale cached copy. */
const CACHE_NAME = 'arlilia-shell-v3';
const SHELL_FILES = ['/', '/manifest.json', '/icon-192.png', '/icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(SHELL_FILES))
      .catch(() => {}) // offline-at-install shouldn't block activation
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  const isShellOrLib = url.origin === location.origin || url.hostname === 'cdnjs.cloudflare.com';
  if (!isShellOrLib) return; // Supabase (data + auth) always goes straight to the network

  // The app's HTML (the page itself, '/') changes often while this app is
  // actively being worked on — network-first so a reload always shows the
  // latest version, falling back to the cached copy only if offline.
  if (req.mode === 'navigate' || url.pathname === '/') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  // Everything else (icons, manifest, libs) changes rarely — stale-while-
  // revalidate: serve from cache instantly, refresh in the background.
  event.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy));
          }
          return res;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});
