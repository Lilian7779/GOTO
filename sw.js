const CACHE_NAME = 'zqtong-v2';
const STATIC_ASSETS = [
  '/',
  'index.html',
  'policy.html',
  'service.html',
  'ip.html',
  'software.html',
  'office.html',
  'license.html',
  'guide.html',
  'newco.html',
  'admin.html',
  'supabase-client.js',
  'manifest.json'
];

// Install: precache all static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(STATIC_ASSETS).catch(err => {
        console.warn('Precache failed for some assets:', err);
      });
    })
  );
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
      );
    })
  );
  self.clients.claim();
});

// Fetch: network-first for all static assets (includes supabase-client.js)
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const isHTML = event.request.headers.get('accept') && event.request.headers.get('accept').includes('text/html');

  // Network first for HTML
  if (isHTML) {
    event.respondWith(
      fetch(event.request)
        .then(response => {
          const cloned = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, cloned));
          return response;
        })
        .catch(() => caches.match(event.request))
    );
  } else {
    // Network first for all static assets (JS, CSS, JSON, images, etc.)
    event.respondWith(
      fetch(event.request)
        .then(response => {
          if (response.ok && event.request.method === 'GET') {
            const cloned = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, cloned));
          }
          return response;
        })
        .catch(() => caches.match(event.request))
    );
  }
});
