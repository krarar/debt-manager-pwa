// Service Worker Registration for PWA
import { registerSW } from 'virtual:pwa-register';

// Register service worker
const updateSW = registerSW({
  onNeedRefresh() {
    console.log('New content available, please refresh');
    // Show update available notification
    if ('serviceWorker' in navigator) {
      const event = new CustomEvent('swUpdate', {
        detail: { type: 'update-available' }
      });
      window.dispatchEvent(event);
    }
  },
  onOfflineReady() {
    console.log('App ready to work offline');
    // Show offline ready notification
    const event = new CustomEvent('swUpdate', {
      detail: { type: 'offline-ready' }
    });
    window.dispatchEvent(event);
  },
  onRegistered(r) {
    console.log('SW Registered: ' + r);
  },
  onRegisterError(error) {
    console.log('SW registration error', error);
  }
});

// Function to update SW manually
window.updateSW = updateSW;

export { updateSW };