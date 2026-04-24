// Kill-switch: old Flutter service worker gets replaced by this empty SW
// which deletes all caches and unregisters itself, then reloads the page.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const cacheName of await caches.keys()) {
      await caches.delete(cacheName);
    }
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    for (const client of clients) {
      try { client.navigate(client.url); } catch (e) {}
    }
  })());
});
self.addEventListener('fetch', (e) => { /* no-op: pass-through to network */ });
