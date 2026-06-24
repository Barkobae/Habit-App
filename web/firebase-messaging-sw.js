importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
   apiKey: "AIzaSyC6QAotrhep-3wX3cEfhZxX4rpOKlW_eio",
  authDomain: "habitapp-2e623.firebaseapp.com",
  projectId: "habitapp-2e623",
  storageBucket: "habitapp-2e623.firebasestorage.app",
  messagingSenderId: "628790831583",
  appId: "1:628790831583:web:fce90d72855df6c227bc6a",
  measurementId: "G-YVK7FCP1PR"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png"
  });
});