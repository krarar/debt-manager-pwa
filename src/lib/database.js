// IndexedDB database manager for the debt management app
class DatabaseManager {
  constructor() {
    this.dbName = 'debts_db';
    this.version = 1;
    this.db = null;
  }

  // Initialize the database
  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version);

      request.onerror = () => {
        reject(new Error('Failed to open database'));
      };

      request.onsuccess = (event) => {
        this.db = event.target.result;
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        this.createStores(db);
      };
    });
  }

  // Create object stores
  createStores(db) {
    // Debtors store
    if (!db.objectStoreNames.contains('debtors')) {
      const debtorsStore = db.createObjectStore('debtors', { keyPath: 'id' });
      debtorsStore.createIndex('name', 'name', { unique: false });
      debtorsStore.createIndex('phone', 'phone', { unique: false });
      debtorsStore.createIndex('createdAt', 'createdAt', { unique: false });
      debtorsStore.createIndex('updatedAt', 'updatedAt', { unique: false });
    }

    // Transactions store
    if (!db.objectStoreNames.contains('transactions')) {
      const transactionsStore = db.createObjectStore('transactions', { keyPath: 'id' });
      transactionsStore.createIndex('debtorId', 'debtorId', { unique: false });
      transactionsStore.createIndex('type', 'type', { unique: false });
      transactionsStore.createIndex('createdAt', 'createdAt', { unique: false });
      transactionsStore.createIndex('amount', 'amount', { unique: false });
    }

    // Settings store
    if (!db.objectStoreNames.contains('settings')) {
      db.createObjectStore('settings', { keyPath: 'key' });
    }

    // Sync queue store
    if (!db.objectStoreNames.contains('sync_queue')) {
      const syncStore = db.createObjectStore('sync_queue', { keyPath: 'id' });
      syncStore.createIndex('queuedAt', 'queuedAt', { unique: false });
      syncStore.createIndex('opType', 'opType', { unique: false });
    }
  }

  // Generic method to perform transactions
  async performTransaction(storeName, mode, operation) {
    if (!this.db) {
      await this.init();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([storeName], mode);
      const store = transaction.objectStore(storeName);

      transaction.oncomplete = () => resolve();
      transaction.onerror = () => reject(transaction.error);

      const request = operation(store);
      if (request) {
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      }
    });
  }

  // DEBTORS CRUD operations
  async addDebtor(debtor) {
    const newDebtor = {
      id: this.generateId(),
      ...debtor,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await this.performTransaction('debtors', 'readwrite', (store) => {
      return store.add(newDebtor);
    });

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('CREATE_DEBTOR', newDebtor);
    
    return newDebtor;
  }

  async getDebtor(id) {
    return await this.performTransaction('debtors', 'readonly', (store) => {
      return store.get(id);
    });
  }

  async getAllDebtors() {
    return await this.performTransaction('debtors', 'readonly', (store) => {
      return store.getAll();
    });
  }

  async updateDebtor(id, updates) {
    const existingDebtor = await this.getDebtor(id);
    if (!existingDebtor) {
      throw new Error('Debtor not found');
    }

    const updatedDebtor = {
      ...existingDebtor,
      ...updates,
      updatedAt: new Date().toISOString()
    };

    await this.performTransaction('debtors', 'readwrite', (store) => {
      return store.put(updatedDebtor);
    });

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('UPDATE_DEBTOR', updatedDebtor);
    
    return updatedDebtor;
  }

  async deleteDebtor(id) {
    // First delete all transactions for this debtor
    const transactions = await this.getTransactionsByDebtor(id);
    for (const transaction of transactions) {
      await this.deleteTransaction(transaction.id);
    }

    // Then delete the debtor
    await this.performTransaction('debtors', 'readwrite', (store) => {
      return store.delete(id);
    });

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('DELETE_DEBTOR', { id });
  }

  // TRANSACTIONS CRUD operations
  async addTransaction(transaction) {
    const newTransaction = {
      id: this.generateId(),
      ...transaction,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    await this.performTransaction('transactions', 'readwrite', (store) => {
      return store.add(newTransaction);
    });

    // Update debtor's updatedAt timestamp
    await this.updateDebtor(transaction.debtorId, {});

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('CREATE_TRANSACTION', newTransaction);
    
    return newTransaction;
  }

  async getTransaction(id) {
    return await this.performTransaction('transactions', 'readonly', (store) => {
      return store.get(id);
    });
  }

  async getAllTransactions() {
    return await this.performTransaction('transactions', 'readonly', (store) => {
      return store.getAll();
    });
  }

  async getTransactionsByDebtor(debtorId) {
    return await this.performTransaction('transactions', 'readonly', (store) => {
      const index = store.index('debtorId');
      return index.getAll(debtorId);
    });
  }

  async updateTransaction(id, updates) {
    const existingTransaction = await this.getTransaction(id);
    if (!existingTransaction) {
      throw new Error('Transaction not found');
    }

    const updatedTransaction = {
      ...existingTransaction,
      ...updates,
      updatedAt: new Date().toISOString()
    };

    await this.performTransaction('transactions', 'readwrite', (store) => {
      return store.put(updatedTransaction);
    });

    // Update debtor's updatedAt timestamp
    await this.updateDebtor(existingTransaction.debtorId, {});

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('UPDATE_TRANSACTION', updatedTransaction);
    
    return updatedTransaction;
  }

  async deleteTransaction(id) {
    const transaction = await this.getTransaction(id);
    if (!transaction) {
      throw new Error('Transaction not found');
    }

    await this.performTransaction('transactions', 'readwrite', (store) => {
      return store.delete(id);
    });

    // Update debtor's updatedAt timestamp
    await this.updateDebtor(transaction.debtorId, {});

    // Add to sync queue if sync is enabled
    await this.addToSyncQueue('DELETE_TRANSACTION', { id });
  }

  // SETTINGS operations
  async getSetting(key) {
    const result = await this.performTransaction('settings', 'readonly', (store) => {
      return store.get(key);
    });
    return result?.value;
  }

  async setSetting(key, value) {
    const setting = { key, value };
    await this.performTransaction('settings', 'readwrite', (store) => {
      return store.put(setting);
    });
  }

  async getAllSettings() {
    const results = await this.performTransaction('settings', 'readonly', (store) => {
      return store.getAll();
    });
    
    const settings = {};
    results.forEach(item => {
      settings[item.key] = item.value;
    });
    
    return settings;
  }

  // SYNC QUEUE operations
  async addToSyncQueue(opType, payload) {
    const syncEnabled = await this.getSetting('syncEnabled');
    if (!syncEnabled) return;

    const queueItem = {
      id: this.generateId(),
      opType,
      payload,
      queuedAt: new Date().toISOString(),
      retries: 0
    };

    await this.performTransaction('sync_queue', 'readwrite', (store) => {
      return store.add(queueItem);
    });
  }

  async getSyncQueue() {
    return await this.performTransaction('sync_queue', 'readonly', (store) => {
      return store.getAll();
    });
  }

  async clearSyncQueue() {
    await this.performTransaction('sync_queue', 'readwrite', (store) => {
      return store.clear();
    });
  }

  async removeSyncQueueItem(id) {
    await this.performTransaction('sync_queue', 'readwrite', (store) => {
      return store.delete(id);
    });
  }

  // STATISTICS and AGGREGATIONS
  async getDebtorBalance(debtorId) {
    const transactions = await this.getTransactionsByDebtor(debtorId);
    
    let balance = 0;
    transactions.forEach(transaction => {
      if (transaction.type === 'debt') {
        balance += transaction.amount;
      } else if (transaction.type === 'payment') {
        balance -= transaction.amount;
      }
    });
    
    return balance;
  }

  async getDebtorStats() {
    const debtors = await this.getAllDebtors();
    const transactions = await this.getAllTransactions();
    
    let totalDebts = 0;
    let totalPayments = 0;
    let totalBalance = 0;
    
    const debtorBalances = {};
    
    // Calculate balances for each debtor
    transactions.forEach(transaction => {
      if (!debtorBalances[transaction.debtorId]) {
        debtorBalances[transaction.debtorId] = 0;
      }
      
      if (transaction.type === 'debt') {
        debtorBalances[transaction.debtorId] += transaction.amount;
        totalDebts += transaction.amount;
      } else if (transaction.type === 'payment') {
        debtorBalances[transaction.debtorId] -= transaction.amount;
        totalPayments += transaction.amount;
      }
    });
    
    // Calculate total balance
    Object.values(debtorBalances).forEach(balance => {
      totalBalance += Math.max(0, balance); // Only positive balances (remaining debts)
    });
    
    return {
      totalDebtors: debtors.length,
      totalDebts,
      totalPayments,
      totalBalance,
      debtorBalances
    };
  }

  async getTransactionsInDateRange(startDate, endDate) {
    const allTransactions = await this.getAllTransactions();
    
    return allTransactions.filter(transaction => {
      const transactionDate = new Date(transaction.createdAt);
      return transactionDate >= new Date(startDate) && transactionDate <= new Date(endDate);
    });
  }

  // UTILITY methods
  generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2, 9);
  }

  // BACKUP and RESTORE
  async exportData() {
    const [debtors, transactions, settings] = await Promise.all([
      this.getAllDebtors(),
      this.getAllTransactions(),
      this.getAllSettings()
    ]);

    return {
      debtors,
      transactions,
      settings,
      exportedAt: new Date().toISOString(),
      version: this.version
    };
  }

  async importData(data, options = { merge: false }) {
    if (!data || typeof data !== 'object') {
      throw new Error('Invalid import data');
    }

    const { debtors = [], transactions = [], settings = {} } = data;

    if (!options.merge) {
      // Clear existing data
      await this.clearAllData();
    }

    // Import settings
    for (const [key, value] of Object.entries(settings)) {
      await this.setSetting(key, value);
    }

    // Import debtors
    const debtorIdMap = new Map();
    for (const debtor of debtors) {
      const oldId = debtor.id;
      const newDebtor = {
        ...debtor,
        id: options.merge ? this.generateId() : debtor.id,
        updatedAt: new Date().toISOString()
      };
      
      await this.performTransaction('debtors', 'readwrite', (store) => {
        return store.put(newDebtor);
      });
      
      if (options.merge) {
        debtorIdMap.set(oldId, newDebtor.id);
      }
    }

    // Import transactions
    for (const transaction of transactions) {
      const newTransaction = {
        ...transaction,
        id: options.merge ? this.generateId() : transaction.id,
        debtorId: options.merge ? debtorIdMap.get(transaction.debtorId) || transaction.debtorId : transaction.debtorId,
        updatedAt: new Date().toISOString()
      };
      
      await this.performTransaction('transactions', 'readwrite', (store) => {
        return store.put(newTransaction);
      });
    }
  }

  async clearAllData() {
    const stores = ['debtors', 'transactions', 'settings', 'sync_queue'];
    
    for (const storeName of stores) {
      await this.performTransaction(storeName, 'readwrite', (store) => {
        return store.clear();
      });
    }
  }

  // SEARCH functionality
  async searchDebtors(query) {
    const debtors = await this.getAllDebtors();
    const lowercaseQuery = query.toLowerCase();
    
    return debtors.filter(debtor => 
      debtor.name.toLowerCase().includes(lowercaseQuery) ||
      debtor.phone.includes(query) ||
      (debtor.address && debtor.address.toLowerCase().includes(lowercaseQuery)) ||
      (debtor.notes && debtor.notes.toLowerCase().includes(lowercaseQuery))
    );
  }

  async searchTransactions(query) {
    const transactions = await this.getAllTransactions();
    const lowercaseQuery = query.toLowerCase();
    
    return transactions.filter(transaction =>
      (transaction.product && transaction.product.toLowerCase().includes(lowercaseQuery)) ||
      (transaction.notes && transaction.notes.toLowerCase().includes(lowercaseQuery)) ||
      transaction.amount.toString().includes(query)
    );
  }
}

// Create singleton instance
const db = new DatabaseManager();

export default db;