const CACHE_NAME = 'zqtong-v3';
const urlsToCache = ['/','/index.html','/policy.html','/office.html','/license.html','/ip.html','/software.html','/admin.html','/newco.html','/supabase-client.js','/data-sources.json','/manifest.json'];

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(urlsToCache)));
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => Promise.all(
      cacheNames.map(c => c !== CACHE_NAME ? caches.delete(c) : null)
    )).then(() => {
      self.clients.matchAll().then(clients => {
        clients.forEach(client => client.postMessage({type: 'UPDATE_READY'}));
      });
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  const respond = (req) => fetch(req).then(resp => {
    let clone = resp.clone();
    caches.open(CACHE_NAME).then(c => c.put(req, clone));
    return resp;
  }).catch(() => caches.match(req));
  event.respondWith(respond(event.request));
});
