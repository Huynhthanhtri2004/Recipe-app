/* global importScripts, firebase */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Firebase config for web (from lib/firebase_options.dart)
firebase.initializeApp({
  apiKey: 'AIzaSyCf5Z6T3fQL_0OQX0Ar1fD-T7PYcilLzO8',
  appId: '1:632817783218:web:360c0b8f8c7a48cf6354ab',
  messagingSenderId: '632817783218',
  projectId: 'recipeapp-90db2',
  authDomain: 'recipeapp-90db2.firebaseapp.com',
  storageBucket: 'recipeapp-90db2.firebasestorage.app',
  measurementId: 'G-J9Q3XF50KY',
});

const messaging = firebase.messaging.isSupported() ? firebase.messaging() : null;

if (messaging) {
  messaging.onBackgroundMessage((payload) => {
    const notificationTitle = payload.notification?.title || 'Recipe App';
    const notificationOptions = {
      body: payload.notification?.body || '',
      icon: '/icons/Icon-192.png',
      data: payload.data || {},
    };
    self.registration.showNotification(notificationTitle, notificationOptions);
  });
}

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.click_action || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow(targetUrl);
    })
  );
});




