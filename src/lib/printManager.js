import { formatDate, formatCurrency, formatNumber } from '../i18n.js';
import db from './database.js';

class PrintManager {
  constructor() {
    this.defaultSettings = {
      businessName: 'مدير الديون',
      businessPhone: '+964 XXX XXX XXXX',
      businessAddress: '',
      logo: '',
      headerText: 'فاتورة',
      footerText: 'شكراً لتعاملكم معنا',
      showLogo: true,
      showHeader: true,
      showFooter: true,
      paperSize: 'A4', // A4 or thermal
      fontSize: 'medium' // small, medium, large
    };
  }

  // Get print settings
  async getPrintSettings() {
    try {
      const settings = await db.getSetting('printSettings');
      return { ...this.defaultSettings, ...settings };
    } catch (error) {
      console.error('Failed to get print settings:', error);
      return this.defaultSettings;
    }
  }

  // Save print settings
  async savePrintSettings(settings) {
    try {
      const updatedSettings = { ...this.defaultSettings, ...settings };
      await db.setSetting('printSettings', updatedSettings);
      return { success: true, message: 'Print settings saved successfully' };
    } catch (error) {
      console.error('Failed to save print settings:', error);
      return { success: false, message: error.message };
    }
  }

  // Print debtor statement
  async printDebtorStatement(debtorId, options = {}) {
    try {
      const debtor = await db.getDebtor(debtorId);
      if (!debtor) {
        throw new Error('Debtor not found');
      }

      const transactions = await db.getTransactionsByDebtor(debtorId);
      const balance = await db.getDebtorBalance(debtorId);
      const settings = await this.getPrintSettings();

      const htmlContent = this.generateDebtorStatementHTML(debtor, transactions, balance, settings, options);
      
      if (options.preview) {
        this.openPrintPreview(htmlContent);
      } else {
        this.printHTML(htmlContent);
      }

      return { success: true, message: 'Statement printed successfully' };
    } catch (error) {
      console.error('Print failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Print receipt for transaction
  async printTransactionReceipt(transactionId, options = {}) {
    try {
      const transaction = await db.getTransaction(transactionId);
      if (!transaction) {
        throw new Error('Transaction not found');
      }

      const debtor = await db.getDebtor(transaction.debtorId);
      const settings = await this.getPrintSettings();

      const htmlContent = this.generateReceiptHTML(transaction, debtor, settings, options);
      
      if (options.preview) {
        this.openPrintPreview(htmlContent);
      } else {
        this.printHTML(htmlContent);
      }

      return { success: true, message: 'Receipt printed successfully' };
    } catch (error) {
      console.error('Print failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Print report
  async printReport(reportData, options = {}) {
    try {
      const settings = await this.getPrintSettings();
      const htmlContent = this.generateReportHTML(reportData, settings, options);
      
      if (options.preview) {
        this.openPrintPreview(htmlContent);
      } else {
        this.printHTML(htmlContent);
      }

      return { success: true, message: 'Report printed successfully' };
    } catch (error) {
      console.error('Print failed:', error);
      return { success: false, message: error.message };
    }
  }

  // Generate debtor statement HTML
  generateDebtorStatementHTML(debtor, transactions, balance, settings, options = {}) {
    const isRTL = document.documentElement.getAttribute('dir') === 'rtl';
    const language = document.documentElement.getAttribute('lang') || 'ar';
    
    // Sort transactions by date
    const sortedTransactions = [...transactions].sort((a, b) => 
      new Date(a.createdAt) - new Date(b.createdAt)
    );

    let html = `
      <!DOCTYPE html>
      <html dir="${isRTL ? 'rtl' : 'ltr'}" lang="${language}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>كشف حساب - ${debtor.name}</title>
        <style>
          ${this.getPrintCSS(settings, isRTL)}
        </style>
      </head>
      <body class="print-container">
    `;

    // Header
    if (settings.showHeader) {
      html += `
        <div class="print-header">
          ${settings.showLogo && settings.logo ? `<img src="${settings.logo}" alt="Logo" class="logo">` : ''}
          <h1>${settings.businessName}</h1>
          ${settings.businessPhone ? `<p>Tel: ${settings.businessPhone}</p>` : ''}
          ${settings.businessAddress ? `<p>${settings.businessAddress}</p>` : ''}
        </div>
      `;
    }

    // Document title
    html += `
      <div class="document-title">
        <h2>${settings.headerText || 'كشف حساب'}</h2>
        <p>التاريخ: ${formatDate(new Date(), language)}</p>
      </div>
    `;

    // Debtor information
    html += `
      <div class="debtor-info">
        <h3>بيانات العميل</h3>
        <table class="info-table">
          <tr><td><strong>الاسم:</strong></td><td>${debtor.name}</td></tr>
          <tr><td><strong>الهاتف:</strong></td><td>${debtor.phone}</td></tr>
          ${debtor.address ? `<tr><td><strong>العنوان:</strong></td><td>${debtor.address}</td></tr>` : ''}
          <tr><td><strong>الرصيد الحالي:</strong></td><td class="balance ${balance > 0 ? 'debt' : 'credit'}">${formatCurrency(Math.abs(balance), 'IQD', language)} ${balance > 0 ? '(مدين)' : balance < 0 ? '(دائن)' : ''}</td></tr>
        </table>
      </div>
    `;

    // Transactions table
    if (sortedTransactions.length > 0) {
      html += `
        <div class="transactions">
          <h3>سجل المعاملات</h3>
          <table class="transactions-table">
            <thead>
              <tr>
                <th>التاريخ</th>
                <th>النوع</th>
                <th>المبلغ</th>
                <th>المنتج</th>
                <th>ملاحظات</th>
                <th>الرصيد المتراكم</th>
              </tr>
            </thead>
            <tbody>
      `;

      let runningBalance = 0;
      sortedTransactions.forEach(transaction => {
        if (transaction.type === 'debt') {
          runningBalance += transaction.amount;
        } else {
          runningBalance -= transaction.amount;
        }

        html += `
          <tr>
            <td>${formatDate(transaction.createdAt, language)}</td>
            <td class="transaction-type ${transaction.type}">${transaction.type === 'debt' ? 'دين' : 'سداد'}</td>
            <td class="amount ${transaction.type}">${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</td>
            <td>${transaction.product || '-'}</td>
            <td>${transaction.notes || '-'}</td>
            <td class="balance ${runningBalance > 0 ? 'debt' : 'credit'}">${formatCurrency(Math.abs(runningBalance), 'IQD', language)}</td>
          </tr>
        `;
      });

      html += `
            </tbody>
          </table>
        </div>
      `;
    }

    // Summary
    const totalDebts = sortedTransactions
      .filter(t => t.type === 'debt')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const totalPayments = sortedTransactions
      .filter(t => t.type === 'payment')
      .reduce((sum, t) => sum + t.amount, 0);

    html += `
      <div class="summary">
        <h3>الملخص</h3>
        <table class="summary-table">
          <tr><td><strong>إجمالي الديون:</strong></td><td>${formatCurrency(totalDebts, 'IQD', language)}</td></tr>
          <tr><td><strong>إجمالي المدفوعات:</strong></td><td>${formatCurrency(totalPayments, 'IQD', language)}</td></tr>
          <tr class="total-row"><td><strong>الرصيد الحالي:</strong></td><td class="balance ${balance > 0 ? 'debt' : 'credit'}">${formatCurrency(Math.abs(balance), 'IQD', language)} ${balance > 0 ? '(مدين)' : balance < 0 ? '(دائن)' : ''}</td></tr>
        </table>
      </div>
    `;

    // Footer
    if (settings.showFooter) {
      html += `
        <div class="print-footer">
          <p>${settings.footerText}</p>
          <div class="signature-area">
            <div class="signature-box">
              <p>توقيع العميل</p>
              <div class="signature-line"></div>
            </div>
            <div class="signature-box">
              <p>توقيع المحاسب</p>
              <div class="signature-line"></div>
            </div>
          </div>
        </div>
      `;
    }

    html += `
      </body>
      </html>
    `;

    return html;
  }

  // Generate receipt HTML
  generateReceiptHTML(transaction, debtor, settings, options = {}) {
    const isRTL = document.documentElement.getAttribute('dir') === 'rtl';
    const language = document.documentElement.getAttribute('lang') || 'ar';
    const isThermal = options.thermal || settings.paperSize === 'thermal';

    let html = `
      <!DOCTYPE html>
      <html dir="${isRTL ? 'rtl' : 'ltr'}" lang="${language}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>إيصال - ${transaction.type === 'debt' ? 'دين' : 'سداد'}</title>
        <style>
          ${this.getPrintCSS(settings, isRTL, isThermal)}
        </style>
      </head>
      <body class="${isThermal ? 'thermal-receipt' : 'print-container'}">
    `;

    if (isThermal) {
      // Thermal receipt format (80mm)
      html += `
        <div class="thermal-header">
          <h1>${settings.businessName}</h1>
          ${settings.businessPhone ? `<p>${settings.businessPhone}</p>` : ''}
          <div class="thermal-line"></div>
        </div>

        <div class="receipt-info">
          <h2>${transaction.type === 'debt' ? 'فاتورة دين' : 'إيصال سداد'}</h2>
          <p>رقم الإيصال: ${transaction.id.slice(-8).toUpperCase()}</p>
          <p>التاريخ: ${formatDate(transaction.createdAt, language)}</p>
          <div class="thermal-line"></div>
        </div>

        <div class="customer-info">
          <p><strong>العميل:</strong> ${debtor.name}</p>
          <p><strong>الهاتف:</strong> ${debtor.phone}</p>
          <div class="thermal-line"></div>
        </div>

        <div class="transaction-details">
          <p><strong>النوع:</strong> ${transaction.type === 'debt' ? 'دين' : 'سداد'}</p>
          <p><strong>المبلغ:</strong> ${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</p>
          ${transaction.product ? `<p><strong>المنتج:</strong> ${transaction.product}</p>` : ''}
          ${transaction.paymentMethod ? `<p><strong>طريقة الدفع:</strong> ${transaction.paymentMethod}</p>` : ''}
          ${transaction.notes ? `<p><strong>ملاحظات:</strong> ${transaction.notes}</p>` : ''}
        </div>

        <div class="thermal-line"></div>
        <div class="thermal-total">
          <p><strong>المبلغ الإجمالي: ${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</strong></p>
        </div>

        <div class="thermal-footer">
          <div class="thermal-line"></div>
          <p style="text-align: center;">${settings.footerText}</p>
          <p style="text-align: center; font-size: 10pt;">شكراً لزيارتكم</p>
        </div>
      `;
    } else {
      // A4 receipt format
      html += `
        <div class="print-header">
          ${settings.showLogo && settings.logo ? `<img src="${settings.logo}" alt="Logo" class="logo">` : ''}
          <h1>${settings.businessName}</h1>
          ${settings.businessPhone ? `<p>Tel: ${settings.businessPhone}</p>` : ''}
        </div>

        <div class="document-title">
          <h2>${transaction.type === 'debt' ? 'فاتورة دين' : 'إيصال سداد'}</h2>
          <p>رقم الإيصال: ${transaction.id.slice(-8).toUpperCase()}</p>
          <p>التاريخ: ${formatDate(transaction.createdAt, language)}</p>
        </div>

        <div class="receipt-body">
          <div class="customer-section">
            <h3>بيانات العميل</h3>
            <table class="info-table">
              <tr><td><strong>الاسم:</strong></td><td>${debtor.name}</td></tr>
              <tr><td><strong>الهاتف:</strong></td><td>${debtor.phone}</td></tr>
              ${debtor.address ? `<tr><td><strong>العنوان:</strong></td><td>${debtor.address}</td></tr>` : ''}
            </table>
          </div>

          <div class="transaction-section">
            <h3>تفاصيل المعاملة</h3>
            <table class="info-table">
              <tr><td><strong>النوع:</strong></td><td>${transaction.type === 'debt' ? 'دين' : 'سداد'}</td></tr>
              <tr><td><strong>المبلغ:</strong></td><td class="amount">${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</td></tr>
              ${transaction.product ? `<tr><td><strong>المنتج:</strong></td><td>${transaction.product}</td></tr>` : ''}
              ${transaction.paymentMethod ? `<tr><td><strong>طريقة الدفع:</strong></td><td>${transaction.paymentMethod}</td></tr>` : ''}
              ${transaction.notes ? `<tr><td><strong>ملاحظات:</strong></td><td>${transaction.notes}</td></tr>` : ''}
            </table>
          </div>

          <div class="amount-section">
            <table class="amount-table">
              <tr class="total-row">
                <td><strong>المبلغ الإجمالي:</strong></td>
                <td class="total-amount">${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</td>
              </tr>
            </table>
          </div>

          <div class="signature-area">
            <div class="signature-box">
              <p>توقيع العميل</p>
              <div class="signature-line"></div>
            </div>
            <div class="signature-box">
              <p>توقيع المحاسب</p>
              <div class="signature-line"></div>
            </div>
          </div>
        </div>

        ${settings.showFooter ? `
          <div class="print-footer">
            <p>${settings.footerText}</p>
          </div>
        ` : ''}
      `;
    }

    html += `
      </body>
      </html>
    `;

    return html;
  }

  // Generate report HTML
  generateReportHTML(reportData, settings, options = {}) {
    const isRTL = document.documentElement.getAttribute('dir') === 'rtl';
    const language = document.documentElement.getAttribute('lang') || 'ar';

    let html = `
      <!DOCTYPE html>
      <html dir="${isRTL ? 'rtl' : 'ltr'}" lang="${language}">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>تقرير</title>
        <style>
          ${this.getPrintCSS(settings, isRTL)}
        </style>
      </head>
      <body class="print-container">
    `;

    // Header
    if (settings.showHeader) {
      html += `
        <div class="print-header">
          ${settings.showLogo && settings.logo ? `<img src="${settings.logo}" alt="Logo" class="logo">` : ''}
          <h1>${settings.businessName}</h1>
          ${settings.businessPhone ? `<p>Tel: ${settings.businessPhone}</p>` : ''}
        </div>
      `;
    }

    // Report title and date range
    html += `
      <div class="document-title">
        <h2>${reportData.title || 'تقرير مالي'}</h2>
        ${reportData.dateRange ? `<p>الفترة: ${reportData.dateRange.from} - ${reportData.dateRange.to}</p>` : ''}
        <p>تاريخ التقرير: ${formatDate(new Date(), language)}</p>
      </div>
    `;

    // Summary section
    if (reportData.summary) {
      html += `
        <div class="summary">
          <h3>الملخص العام</h3>
          <table class="summary-table">
      `;

      Object.entries(reportData.summary).forEach(([key, value]) => {
        html += `<tr><td><strong>${key}:</strong></td><td>${typeof value === 'number' ? formatCurrency(value, 'IQD', language) : value}</td></tr>`;
      });

      html += `
          </table>
        </div>
      `;
    }

    // Transactions table
    if (reportData.transactions && reportData.transactions.length > 0) {
      html += `
        <div class="transactions">
          <h3>تفاصيل المعاملات</h3>
          <table class="transactions-table">
            <thead>
              <tr>
                <th>التاريخ</th>
                <th>العميل</th>
                <th>النوع</th>
                <th>المبلغ</th>
                <th>المنتج</th>
                <th>ملاحظات</th>
              </tr>
            </thead>
            <tbody>
      `;

      reportData.transactions.forEach(transaction => {
        html += `
          <tr>
            <td>${formatDate(transaction.createdAt, language)}</td>
            <td>${transaction.debtorName || 'غير معروف'}</td>
            <td class="transaction-type ${transaction.type}">${transaction.type === 'debt' ? 'دين' : 'سداد'}</td>
            <td class="amount ${transaction.type}">${formatCurrency(transaction.amount, transaction.currency || 'IQD', language)}</td>
            <td>${transaction.product || '-'}</td>
            <td>${transaction.notes || '-'}</td>
          </tr>
        `;
      });

      html += `
            </tbody>
          </table>
        </div>
      `;
    }

    // Footer
    if (settings.showFooter) {
      html += `
        <div class="print-footer">
          <p>${settings.footerText}</p>
        </div>
      `;
    }

    html += `
      </body>
      </html>
    `;

    return html;
  }

  // Get print CSS styles
  getPrintCSS(settings, isRTL, isThermal = false) {
    const fontSize = settings.fontSize === 'small' ? '10pt' : 
                    settings.fontSize === 'large' ? '14pt' : '12pt';

    if (isThermal) {
      return `
        @page {
          size: 80mm auto;
          margin: 0;
        }
        
        body {
          font-family: 'Courier New', monospace;
          font-size: 10pt;
          line-height: 1.2;
          margin: 0;
          padding: 5mm;
          width: 70mm;
        }
        
        .thermal-header {
          text-align: center;
          margin-bottom: 10px;
        }
        
        .thermal-header h1 {
          font-size: 12pt;
          font-weight: bold;
          margin: 0;
        }
        
        .thermal-line {
          border-bottom: 1px dashed #000;
          margin: 5px 0;
        }
        
        .receipt-info, .customer-info, .transaction-details {
          margin: 10px 0;
        }
        
        .thermal-total {
          text-align: center;
          font-weight: bold;
          font-size: 12pt;
          margin: 10px 0;
        }
        
        .thermal-footer {
          text-align: center;
          margin-top: 15px;
          font-size: 9pt;
        }
        
        p {
          margin: 2px 0;
        }
        
        h2 {
          font-size: 11pt;
          margin: 5px 0;
        }
      `;
    }

    return `
      @page {
        size: A4;
        margin: 1cm;
      }
      
      body {
        font-family: ${isRTL ? "'Noto Sans Arabic', Arial" : "'Inter', system-ui"}, sans-serif;
        font-size: ${fontSize};
        line-height: 1.4;
        color: #000;
        margin: 0;
        padding: 0;
        direction: ${isRTL ? 'rtl' : 'ltr'};
      }
      
      .print-container {
        max-width: 210mm;
        margin: 0 auto;
        padding: 10mm;
      }
      
      .print-header {
        text-align: center;
        border-bottom: 2px solid #000;
        margin-bottom: 20px;
        padding-bottom: 10px;
      }
      
      .print-header h1 {
        font-size: 18pt;
        font-weight: bold;
        margin: 0 0 5px 0;
      }
      
      .print-header p {
        margin: 2px 0;
        font-size: 10pt;
      }
      
      .logo {
        max-height: 40px;
        margin-bottom: 10px;
      }
      
      .document-title {
        text-align: center;
        margin-bottom: 20px;
      }
      
      .document-title h2 {
        font-size: 16pt;
        font-weight: bold;
        margin: 0 0 10px 0;
      }
      
      .debtor-info, .summary, .transactions, .receipt-body {
        margin-bottom: 20px;
      }
      
      .debtor-info h3, .summary h3, .transactions h3 {
        font-size: 14pt;
        font-weight: bold;
        margin: 0 0 10px 0;
        border-bottom: 1px solid #ccc;
        padding-bottom: 5px;
      }
      
      .info-table, .summary-table, .transactions-table, .amount-table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 10px;
      }
      
      .info-table td, .summary-table td, .amount-table td {
        padding: 5px;
        border-bottom: 1px solid #eee;
      }
      
      .transactions-table th, .transactions-table td {
        border: 1px solid #ccc;
        padding: 5px;
        text-align: ${isRTL ? 'right' : 'left'};
      }
      
      .transactions-table th {
        background-color: #f5f5f5;
        font-weight: bold;
      }
      
      .transaction-type.debt {
        color: #dc3545;
      }
      
      .transaction-type.payment {
        color: #28a745;
      }
      
      .amount {
        text-align: ${isRTL ? 'left' : 'right'};
        font-weight: bold;
      }
      
      .amount.debt {
        color: #dc3545;
      }
      
      .amount.payment {
        color: #28a745;
      }
      
      .balance.debt {
        color: #dc3545;
        font-weight: bold;
      }
      
      .balance.credit {
        color: #28a745;
        font-weight: bold;
      }
      
      .total-row {
        border-top: 2px solid #000;
        font-weight: bold;
      }
      
      .total-amount {
        font-size: 14pt;
        font-weight: bold;
        text-align: ${isRTL ? 'left' : 'right'};
      }
      
      .signature-area {
        display: flex;
        justify-content: space-between;
        margin-top: 30px;
      }
      
      .signature-box {
        width: 45%;
        text-align: center;
      }
      
      .signature-line {
        border-bottom: 1px solid #000;
        margin-top: 30px;
        margin-bottom: 5px;
      }
      
      .print-footer {
        border-top: 1px solid #000;
        margin-top: 30px;
        padding-top: 10px;
        text-align: center;
        font-size: 10pt;
      }
      
      .customer-section, .transaction-section, .amount-section {
        margin-bottom: 20px;
      }
      
      .customer-section h3, .transaction-section h3 {
        font-size: 12pt;
        margin-bottom: 10px;
        border-bottom: 1px solid #ccc;
        padding-bottom: 3px;
      }
      
      @media print {
        body {
          -webkit-print-color-adjust: exact;
          print-color-adjust: exact;
        }
        
        .no-print {
          display: none !important;
        }
        
        .page-break {
          page-break-before: always;
        }
      }
    `;
  }

  // Print HTML content
  printHTML(htmlContent) {
    const printWindow = window.open('', '_blank');
    printWindow.document.write(htmlContent);
    printWindow.document.close();
    
    printWindow.onload = () => {
      printWindow.print();
      printWindow.close();
    };
  }

  // Open print preview
  openPrintPreview(htmlContent) {
    const previewWindow = window.open('', '_blank', 'width=800,height=600');
    previewWindow.document.write(htmlContent);
    previewWindow.document.close();
  }

  // Print current page
  printCurrentPage() {
    window.print();
  }
}

// Create singleton instance
const printManager = new PrintManager();

export default printManager;