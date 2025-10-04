import { initializeApp } from 'firebase/app';
import { getDatabase, ref, set, get, push, remove, onValue, serverTimestamp } from 'firebase/database';
import db from './database.js';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyDrZmZwSOVhonbLWGrHnctkV4tUcT7UNZM",
  authDomain: "legal-department-dbd28.firebaseapp.com",
  databaseURL: "https://legal-department-dbd28-default-rtdb.firebaseio.com",
  projectId: "legal-department-dbd28",
  storageBucket: "legal-department-dbd28.firebasestorage.app",
  messagingSenderId: "452600951683",
  appId: "1:452600951683:web:2929d22d53a309d947fcb6"
};

class FirebaseSyncManager {
  constructor() {
    this.app = null;
    this.database = null;
    this.userId = null;
    this.isInitialized = false;
    this.isOnline = navigator.onLine;
    this.syncInProgress = false;
    
    // Listen for online/offline events
    window.addEventListener('online', () => {
      this.isOnline = true;
      this.autoSync();
    });
    
    window.addEventListener('offline', () => {
      this.isOnline = false;
    });
  }

  // Initialize Firebase
  async init() {
    try {
      this.app = initializeApp(firebaseConfig);
      this.database = getDatabase(this.app);
      this.userId = await this.getUserId();
      this.isInitialized = true;
      
      // Auto-sync if enabled
      const syncOnStartup = await db.getSetting('syncOnStartup');
      if (syncOnStartup && this.isOnline) {
        this.autoSync();
      }
      
      return true;
    } catch (error) {
      console.error('Failed to initialize Firebase:', error);
      return false;
    }
  }

  // Get or generate anonymous user ID
  async getUserId() {
    let userId = await db.getSetting('firebaseUserId');
    if (!userId) {
      userId = 'anon_' + Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
      await db.setSetting('firebaseUserId', userId);
    }
    return userId;
  }

  // Get Firebase references
  getUserRef() {
    return ref(this.database, `users/${this.userId}`);
  }

  getDebtorsRef() {
    return ref(this.database, `users/${this.userId}/debtors`);
  }

  getTransactionsRef() {
    return ref(this.database, `users/${this.userId}/transactions`);
  }

  getSettingsRef() {
    return ref(this.database, `users/${this.userId}/settings`);
  }

  getLastSyncRef() {
    return ref(this.database, `users/${this.userId}/lastSyncAt`);
  }

  // SYNC OPERATIONS

  // Full synchronization (bidirectional)
  async performSync() {
    if (!this.isInitialized || !this.isOnline || this.syncInProgress) {
      return { success: false, message: 'Sync not available' };
    }

    this.syncInProgress = true;
    
    try {
      // 1. Process local sync queue (upload changes)
      await this.processLocalSyncQueue();
      
      // 2. Download remote changes
      await this.downloadRemoteChanges();
      
      // 3. Update last sync timestamp
      const now = Date.now();
      await set(this.getLastSyncRef(), now);
      await db.setSetting('lastSyncAt', now);
      
      // 4. Clear sync queue
      await db.clearSyncQueue();
      
      this.syncInProgress = false;
      return { success: true, message: 'Sync completed successfully' };
      
    } catch (error) {
      this.syncInProgress = false;
      console.error('Sync failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Process local sync queue
  async processLocalSyncQueue() {
    const syncQueue = await db.getSyncQueue();
    
    for (const item of syncQueue) {
      try {
        await this.processQueueItem(item);
        await db.removeSyncQueueItem(item.id);
      } catch (error) {
        console.error('Failed to process sync queue item:', item, error);
        // Increment retry count or remove after max retries
        if (item.retries >= 3) {
          await db.removeSyncQueueItem(item.id);
        }
      }
    }
  }

  // Process individual queue item
  async processQueueItem(item) {
    const { opType, payload } = item;
    
    switch (opType) {
      case 'CREATE_DEBTOR':
        await this.uploadDebtor(payload);
        break;
      case 'UPDATE_DEBTOR':
        await this.uploadDebtor(payload);
        break;
      case 'DELETE_DEBTOR':
        await this.deleteRemoteDebtor(payload.id);
        break;
      case 'CREATE_TRANSACTION':
        await this.uploadTransaction(payload);
        break;
      case 'UPDATE_TRANSACTION':
        await this.uploadTransaction(payload);
        break;
      case 'DELETE_TRANSACTION':
        await this.deleteRemoteTransaction(payload.id);
        break;
    }
  }

  // Upload debtor to Firebase
  async uploadDebtor(debtor) {
    const debtorRef = ref(this.database, `users/${this.userId}/debtors/${debtor.id}`);
    await set(debtorRef, {
      ...debtor,
      syncedAt: serverTimestamp()
    });
  }

  // Upload transaction to Firebase
  async uploadTransaction(transaction) {
    const transactionRef = ref(this.database, `users/${this.userId}/transactions/${transaction.id}`);
    await set(transactionRef, {
      ...transaction,
      syncedAt: serverTimestamp()
    });
  }

  // Delete remote debtor
  async deleteRemoteDebtor(debtorId) {
    const debtorRef = ref(this.database, `users/${this.userId}/debtors/${debtorId}`);
    await remove(debtorRef);
    
    // Also delete all transactions for this debtor
    const transactionsSnapshot = await get(this.getTransactionsRef());
    if (transactionsSnapshot.exists()) {
      const transactions = transactionsSnapshot.val();
      for (const [transactionId, transaction] of Object.entries(transactions)) {
        if (transaction.debtorId === debtorId) {
          const transactionRef = ref(this.database, `users/${this.userId}/transactions/${transactionId}`);
          await remove(transactionRef);
        }
      }
    }
  }

  // Delete remote transaction
  async deleteRemoteTransaction(transactionId) {
    const transactionRef = ref(this.database, `users/${this.userId}/transactions/${transactionId}`);
    await remove(transactionRef);
  }

  // Download changes from Firebase
  async downloadRemoteChanges() {
    const lastLocalSync = await db.getSetting('lastSyncAt') || 0;
    
    // Download debtors
    const debtorsSnapshot = await get(this.getDebtorsRef());
    if (debtorsSnapshot.exists()) {
      const remoteDebtors = debtorsSnapshot.val();
      await this.mergeRemoteDebtors(remoteDebtors, lastLocalSync);
    }
    
    // Download transactions
    const transactionsSnapshot = await get(this.getTransactionsRef());
    if (transactionsSnapshot.exists()) {
      const remoteTransactions = transactionsSnapshot.val();
      await this.mergeRemoteTransactions(remoteTransactions, lastLocalSync);
    }
  }

  // Merge remote debtors with local data
  async mergeRemoteDebtors(remoteDebtors, lastLocalSync) {
    for (const [id, remoteDebtor] of Object.entries(remoteDebtors)) {
      const localDebtor = await db.getDebtor(id);
      
      if (!localDebtor) {
        // New debtor from remote
        await db.performTransaction('debtors', 'readwrite', (store) => {
          return store.add({
            ...remoteDebtor,
            syncedAt: undefined // Remove Firebase-specific fields
          });
        });
      } else {
        // Conflict resolution: use the most recently updated
        const remoteUpdatedAt = new Date(remoteDebtor.updatedAt);
        const localUpdatedAt = new Date(localDebtor.updatedAt);
        
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.performTransaction('debtors', 'readwrite', (store) => {
            return store.put({
              ...remoteDebtor,
              syncedAt: undefined
            });
          });
        }
      }
    }
  }

  // Merge remote transactions with local data
  async mergeRemoteTransactions(remoteTransactions, lastLocalSync) {
    for (const [id, remoteTransaction] of Object.entries(remoteTransactions)) {
      const localTransaction = await db.getTransaction(id);
      
      if (!localTransaction) {
        // New transaction from remote
        await db.performTransaction('transactions', 'readwrite', (store) => {
          return store.add({
            ...remoteTransaction,
            syncedAt: undefined
          });
        });
      } else {
        // Conflict resolution: use the most recently updated
        const remoteUpdatedAt = new Date(remoteTransaction.updatedAt);
        const localUpdatedAt = new Date(localTransaction.updatedAt);
        
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.performTransaction('transactions', 'readwrite', (store) => {
            return store.put({
              ...remoteTransaction,
              syncedAt: undefined
            });
          });
        }
      }
    }
  }

  // BACKUP OPERATIONS

  // Full backup to Firebase
  async backupToFirebase() {
    if (!this.isInitialized || !this.isOnline) {
      throw new Error('Backup not available');
    }

    const data = await db.exportData();
    const backupRef = ref(this.database, `users/${this.userId}/backups/${Date.now()}`);
    
    await set(backupRef, {
      ...data,
      createdAt: serverTimestamp()
    });
  }

  // Restore from Firebase backup
  async restoreFromFirebase(backupId) {
    if (!this.isInitialized || !this.isOnline) {
      throw new Error('Restore not available');
    }

    const backupRef = ref(this.database, `users/${this.userId}/backups/${backupId}`);
    const snapshot = await get(backupRef);
    
    if (!snapshot.exists()) {
      throw new Error('Backup not found');
    }

    const backupData = snapshot.val();
    await db.importData(backupData, { merge: false });
  }

  // Get available backups
  async getAvailableBackups() {
    if (!this.isInitialized || !this.isOnline) {
      return [];
    }

    const backupsRef = ref(this.database, `users/${this.userId}/backups`);
    const snapshot = await get(backupsRef);
    
    if (!snapshot.exists()) {
      return [];
    }

    const backups = snapshot.val();
    return Object.entries(backups).map(([id, backup]) => ({
      id,
      ...backup
    }));
  }

  // AUTO SYNC

  // Auto-sync when online
  async autoSync() {
    const syncEnabled = await db.getSetting('syncEnabled');
    if (syncEnabled && this.isOnline && !this.syncInProgress) {
      setTimeout(() => this.performSync(), 1000); // Delay to avoid rapid syncs
    }
  }

  // SETTINGS SYNC

  // Sync settings to Firebase
  async syncSettings() {
    if (!this.isInitialized || !this.isOnline) {
      return;
    }

    const settings = await db.getAllSettings();
    const settingsRef = this.getSettingsRef();
    
    await set(settingsRef, {
      ...settings,
      syncedAt: serverTimestamp()
    });
  }

  // Download settings from Firebase
  async downloadSettings() {
    if (!this.isInitialized || !this.isOnline) {
      return;
    }

    const settingsSnapshot = await get(this.getSettingsRef());
    if (settingsSnapshot.exists()) {
      const remoteSettings = settingsSnapshot.val();
      
      for (const [key, value] of Object.entries(remoteSettings)) {
        if (key !== 'syncedAt') {
          await db.setSetting(key, value);
        }
      }
    }
  }

  // Get sync status
  async getSyncStatus() {
    const lastSyncAt = await db.getSetting('lastSyncAt');
    const syncEnabled = await db.getSetting('syncEnabled');
    const queueLength = (await db.getSyncQueue()).length;
    
    return {
      lastSyncAt,
      syncEnabled,
      isOnline: this.isOnline,
      syncInProgress: this.syncInProgress,
      queueLength,
      isInitialized: this.isInitialized
    };
  }
}

// Create singleton instance
const firebaseSync = new FirebaseSyncManager();

export default firebaseSync;