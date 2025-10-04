import db from './database.js';
import { formatDate, formatCurrency } from '../i18n.js';

class ExportImportManager {
  constructor() {
    this.supportedFormats = ['json', 'csv'];
  }

  // EXPORT OPERATIONS

  // Export all data as JSON
  async exportAllDataAsJSON() {
    try {
      const data = await db.exportData();
      const blob = new Blob([JSON.stringify(data, null, 2)], { 
        type: 'application/json' 
      });
      
      this.downloadBlob(blob, `debt-manager-backup-${this.getDateString()}.json`);
      return { success: true, message: 'Data exported successfully' };
    } catch (error) {
      console.error('Export failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Export single debtor data
  async exportDebtorData(debtorId, format = 'json') {
    try {
      const debtor = await db.getDebtor(debtorId);
      if (!debtor) {
        throw new Error('Debtor not found');
      }

      const transactions = await db.getTransactionsByDebtor(debtorId);
      const balance = await db.getDebtorBalance(debtorId);

      const debtorData = {
        debtor,
        transactions,
        balance,
        exportedAt: new Date().toISOString()
      };

      if (format === 'json') {
        const blob = new Blob([JSON.stringify(debtorData, null, 2)], { 
          type: 'application/json' 
        });
        this.downloadBlob(blob, `debtor-${debtor.name}-${this.getDateString()}.json`);
      } else if (format === 'csv') {
        const csvContent = this.convertDebtorToCSV(debtor, transactions, balance);
        const blob = new Blob([csvContent], { 
          type: 'text/csv;charset=utf-8;' 
        });
        this.downloadBlob(blob, `debtor-${debtor.name}-${this.getDateString()}.csv`);
      }

      return { success: true, message: 'Debtor data exported successfully' };
    } catch (error) {
      console.error('Debtor export failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Export transactions as CSV
  async exportTransactionsAsCSV(startDate, endDate, debtorId = null) {
    try {
      let transactions;
      
      if (debtorId) {
        transactions = await db.getTransactionsByDebtor(debtorId);
      } else {
        transactions = await db.getAllTransactions();
      }

      // Filter by date range if provided
      if (startDate && endDate) {
        transactions = transactions.filter(t => {
          const transactionDate = new Date(t.createdAt);
          return transactionDate >= new Date(startDate) && transactionDate <= new Date(endDate);
        });
      }

      const csvContent = await this.convertTransactionsToCSV(transactions);
      const blob = new Blob([csvContent], { 
        type: 'text/csv;charset=utf-8;' 
      });
      
      const filename = debtorId 
        ? `transactions-debtor-${this.getDateString()}.csv`
        : `transactions-${this.getDateString()}.csv`;
      
      this.downloadBlob(blob, filename);
      return { success: true, message: 'Transactions exported successfully' };
    } catch (error) {
      console.error('Transactions export failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Export report data
  async exportReport(reportData, format = 'json') {
    try {
      if (format === 'json') {
        const blob = new Blob([JSON.stringify(reportData, null, 2)], { 
          type: 'application/json' 
        });
        this.downloadBlob(blob, `report-${this.getDateString()}.json`);
      } else if (format === 'csv') {
        const csvContent = this.convertReportToCSV(reportData);
        const blob = new Blob([csvContent], { 
          type: 'text/csv;charset=utf-8;' 
        });
        this.downloadBlob(blob, `report-${this.getDateString()}.csv`);
      }

      return { success: true, message: 'Report exported successfully' };
    } catch (error) {
      console.error('Report export failed:', error);
      return { success: false, message: error.message };
    }
  }

  // IMPORT OPERATIONS

  // Import JSON data
  async importDataFromJSON(file, options = { merge: false, validate: true }) {
    return new Promise((resolve) => {
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const data = JSON.parse(e.target.result);
          
          if (options.validate) {
            const validation = this.validateImportData(data);
            if (!validation.valid) {
              resolve({ success: false, message: validation.message });
              return;
            }
          }

          await db.importData(data, options);
          resolve({ success: true, message: 'Data imported successfully' });
        } catch (error) {
          console.error('Import failed:', error);
          resolve({ success: false, message: error.message });
        }
      };

      reader.onerror = () => {
        resolve({ success: false, message: 'Failed to read file' });
      };

      reader.readAsText(file);
    });
  }

  // Import CSV transactions
  async importTransactionsFromCSV(file, debtorId) {
    return new Promise((resolve) => {
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const csvText = e.target.result;
          const transactions = this.parseTransactionsCSV(csvText, debtorId);
          
          for (const transaction of transactions) {
            await db.addTransaction(transaction);
          }

          resolve({ 
            success: true, 
            message: `${transactions.length} transactions imported successfully` 
          });
        } catch (error) {
          console.error('CSV import failed:', error);
          resolve({ success: false, message: error.message });
        }
      };

      reader.onerror = () => {
        resolve({ success: false, message: 'Failed to read CSV file' });
      };

      reader.readAsText(file);
    });
  }

  // VALIDATION

  // Validate import data structure
  validateImportData(data) {
    if (!data || typeof data !== 'object') {
      return { valid: false, message: 'Invalid data format' };
    }

    // Check for required fields
    if (!data.debtors && !data.transactions && !data.settings) {
      return { valid: false, message: 'No valid data found' };
    }

    // Validate debtors
    if (data.debtors && Array.isArray(data.debtors)) {
      for (const debtor of data.debtors) {
        if (!debtor.id || !debtor.name) {
          return { valid: false, message: 'Invalid debtor data: missing id or name' };
        }
      }
    }

    // Validate transactions
    if (data.transactions && Array.isArray(data.transactions)) {
      for (const transaction of data.transactions) {
        if (!transaction.id || !transaction.debtorId || !transaction.type || transaction.amount === undefined) {
          return { valid: false, message: 'Invalid transaction data: missing required fields' };
        }
        
        if (!['debt', 'payment'].includes(transaction.type)) {
          return { valid: false, message: 'Invalid transaction type' };
        }
      }
    }

    return { valid: true, message: 'Data is valid' };
  }

  // CSV CONVERSION METHODS

  // Convert debtor data to CSV
  convertDebtorToCSV(debtor, transactions, balance) {
    const headers = [
      'Date', 'Type', 'Amount', 'Currency', 'Product', 'Notes', 'Payment Method'
    ];

    let csv = `Debtor: ${debtor.name}\n`;
    csv += `Phone: ${debtor.phone}\n`;
    csv += `Address: ${debtor.address || ''}\n`;
    csv += `Current Balance: ${balance}\n\n`;
    csv += headers.join(',') + '\n';

    transactions.forEach(transaction => {
      const row = [
        formatDate(transaction.createdAt),
        transaction.type,
        transaction.amount,
        transaction.currency || 'IQD',
        transaction.product || '',
        transaction.notes || '',
        transaction.paymentMethod || ''
      ];
      csv += row.map(field => `"${field}"`).join(',') + '\n';
    });

    return csv;
  }

  // Convert transactions to CSV
  async convertTransactionsToCSV(transactions) {
    const headers = [
      'ID', 'Debtor Name', 'Date', 'Type', 'Amount', 'Currency', 
      'Product', 'Notes', 'Payment Method'
    ];

    let csv = headers.join(',') + '\n';

    for (const transaction of transactions) {
      const debtor = await db.getDebtor(transaction.debtorId);
      const row = [
        transaction.id,
        debtor ? debtor.name : 'Unknown',
        formatDate(transaction.createdAt),
        transaction.type,
        transaction.amount,
        transaction.currency || 'IQD',
        transaction.product || '',
        transaction.notes || '',
        transaction.paymentMethod || ''
      ];
      csv += row.map(field => `"${field}"`).join(',') + '\n';
    }

    return csv;
  }

  // Convert report to CSV
  convertReportToCSV(reportData) {
    let csv = 'Report Summary\n\n';
    
    if (reportData.summary) {
      csv += 'Summary\n';
      Object.entries(reportData.summary).forEach(([key, value]) => {
        csv += `${key},${value}\n`;
      });
      csv += '\n';
    }

    if (reportData.transactions) {
      csv += 'Transactions\n';
      csv += 'Date,Type,Amount,Currency,Product,Notes\n';
      reportData.transactions.forEach(transaction => {
        const row = [
          formatDate(transaction.createdAt),
          transaction.type,
          transaction.amount,
          transaction.currency || 'IQD',
          transaction.product || '',
          transaction.notes || ''
        ];
        csv += row.map(field => `"${field}"`).join(',') + '\n';
      });
    }

    return csv;
  }

  // Parse CSV transactions
  parseTransactionsCSV(csvText, debtorId) {
    const lines = csvText.split('\n').filter(line => line.trim());
    const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
    const transactions = [];

    for (let i = 1; i < lines.length; i++) {
      const values = this.parseCSVLine(lines[i]);
      
      if (values.length >= 3) { // At least date, type, amount
        const transaction = {
          debtorId,
          type: values[1]?.toLowerCase() === 'payment' ? 'payment' : 'debt',
          amount: parseFloat(values[2]) || 0,
          currency: values[3] || 'IQD',
          product: values[4] || '',
          notes: values[5] || '',
          paymentMethod: values[6] || 'cash',
          createdAt: new Date(values[0] || Date.now()).toISOString()
        };

        if (transaction.amount > 0) {
          transactions.push(transaction);
        }
      }
    }

    return transactions;
  }

  // Parse CSV line handling quoted fields
  parseCSVLine(line) {
    const result = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];
      
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    
    result.push(current.trim());
    return result;
  }

  // UTILITY METHODS

  // Download blob as file
  downloadBlob(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  // Get formatted date string for filenames
  getDateString() {
    const now = new Date();
    return now.toISOString().split('T')[0];
  }

  // Get file extension
  getFileExtension(filename) {
    return filename.split('.').pop().toLowerCase();
  }

  // Check if file type is supported
  isSupportedFormat(filename) {
    const extension = this.getFileExtension(filename);
    return this.supportedFormats.includes(extension);
  }

  // Generate sample data for testing
  generateSampleData() {
    return {
      debtors: [
        {
          id: 'sample_debtor_1',
          name: 'أحمد محمد',
          phone: '07901234567',
          address: 'بغداد، العراق',
          notes: 'زبون منتظم',
          createdAt: new Date('2024-01-01').toISOString(),
          updatedAt: new Date('2024-01-15').toISOString()
        },
        {
          id: 'sample_debtor_2',
          name: 'فاطمة علي',
          phone: '07907654321',
          address: 'البصرة، العراق',
          notes: '',
          createdAt: new Date('2024-01-05').toISOString(),
          updatedAt: new Date('2024-01-20').toISOString()
        }
      ],
      transactions: [
        {
          id: 'sample_transaction_1',
          debtorId: 'sample_debtor_1',
          type: 'debt',
          amount: 100000,
          currency: 'IQD',
          product: 'بضائع متنوعة',
          notes: 'دفعة أولى',
          paymentMethod: 'cash',
          createdAt: new Date('2024-01-01').toISOString(),
          updatedAt: new Date('2024-01-01').toISOString()
        },
        {
          id: 'sample_transaction_2',
          debtorId: 'sample_debtor_1',
          type: 'payment',
          amount: 50000,
          currency: 'IQD',
          product: '',
          notes: 'دفعة جزئية',
          paymentMethod: 'cash',
          createdAt: new Date('2024-01-10').toISOString(),
          updatedAt: new Date('2024-01-10').toISOString()
        }
      ],
      settings: {
        language: 'ar',
        currency: 'IQD',
        dateFormat: 'dd/MM/yyyy',
        syncEnabled: false
      },
      exportedAt: new Date().toISOString(),
      version: 1
    };
  }
}

// Create singleton instance
const exportImport = new ExportImportManager();

export default exportImport;