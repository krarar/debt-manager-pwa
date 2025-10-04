import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { 
  Calendar,
  Download,
  Printer,
  FileText,
  DollarSign,
  TrendingUp,
  Users,
  BarChart3
} from 'lucide-react';

import db from '../lib/database';
import exportImport from '../lib/exportImport';
import printManager from '../lib/printManager';
import { formatCurrency, formatDate } from '../i18n';
import { showNotification } from './NotificationSystem';

const Reports = () => {
  const { t, i18n } = useTranslation();
  const [dateRange, setDateRange] = useState({
    from: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    to: new Date().toISOString().split('T')[0]
  });
  const [reportData, setReportData] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    generateReport();
  }, []);

  const generateReport = async () => {
    try {
      setLoading(true);
      
      const startDate = new Date(dateRange.from);
      const endDate = new Date(dateRange.to);
      endDate.setHours(23, 59, 59, 999); // End of day

      // Get transactions in date range
      const transactions = await db.getTransactionsInDateRange(startDate, endDate);
      
      // Enrich with debtor names
      const enrichedTransactions = await Promise.all(
        transactions.map(async (transaction) => {
          const debtor = await db.getDebtor(transaction.debtorId);
          return {
            ...transaction,
            debtorName: debtor?.name || 'Unknown'
          };
        })
      );

      // Calculate summary
      let totalDebts = 0;
      let totalPayments = 0;
      const debtorActivity = new Set();

      enrichedTransactions.forEach(transaction => {
        debtorActivity.add(transaction.debtorId);
        
        if (transaction.type === 'debt') {
          totalDebts += transaction.amount;
        } else {
          totalPayments += transaction.amount;
        }
      });

      const netChange = totalDebts - totalPayments;
      
      // Get overall stats
      const stats = await db.getDebtorStats();

      const report = {
        title: t('reports.title'),
        dateRange: {
          from: formatDate(startDate, i18n.language),
          to: formatDate(endDate, i18n.language)
        },
        summary: {
          [t('reports.totalDebts')]: totalDebts,
          [t('reports.totalPayments')]: totalPayments,
          [t('reports.netChange')]: netChange,
          [t('reports.debtorCount')]: debtorActivity.size,
          [t('dashboard.totalDebtors')]: stats.totalDebtors,
          [t('dashboard.totalRemaining')]: stats.totalBalance
        },
        transactions: enrichedTransactions,
        generatedAt: new Date().toISOString()
      };

      setReportData(report);
      
    } catch (error) {
      console.error('Failed to generate report:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    } finally {
      setLoading(false);
    }
  };

  const handleExportCSV = async () => {
    try {
      await exportImport.exportReport(reportData, 'csv');
      showNotification({
        type: 'success',
        message: t('notifications.dataExported')
      });
    } catch (error) {
      console.error('Export failed:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const handleExportJSON = async () => {
    try {
      await exportImport.exportReport(reportData, 'json');
      showNotification({
        type: 'success',
        message: t('notifications.dataExported')
      });
    } catch (error) {
      console.error('Export failed:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const handlePrint = async () => {
    try {
      await printManager.printReport(reportData);
    } catch (error) {
      console.error('Print failed:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const SummaryCard = ({ title, value, icon: Icon, color }) => (
    <div className="card">
      <div className="card-content">
        <div className="flex items-center">
          <div className="flex-shrink-0">
            <Icon className={`h-8 w-8 ${color}`} />
          </div>
          <div className="ltr:ml-5 rtl:mr-5 w-0 flex-1">
            <dl>
              <dt className="text-sm font-medium text-gray-500 truncate">
                {title}
              </dt>
              <dd className="text-lg font-medium text-gray-900">
                {typeof value === 'number' ? 
                  formatCurrency(value, 'IQD', i18n.language) : 
                  value
                }
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="page-container">
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">{t('reports.title')}</h1>
        <p className="page-subtitle">
          {t('reports.description')}
        </p>
      </div>

      {/* Date Range Selection */}
      <div className="card mb-8">
        <div className="card-header">
          <h3 className="text-lg font-medium text-gray-900">
            {t('reports.dateRange')}
          </h3>
        </div>
        <div className="card-content">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('reports.from')}
              </label>
              <input
                type="date"
                value={dateRange.from}
                onChange={(e) => setDateRange(prev => ({ ...prev, from: e.target.value }))}
                className="input"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('reports.to')}
              </label>
              <input
                type="date"
                value={dateRange.to}
                onChange={(e) => setDateRange(prev => ({ ...prev, to: e.target.value }))}
                className="input"
              />
            </div>
            
            <div>
              <button
                onClick={generateReport}
                disabled={loading}
                className="btn btn-primary w-full flex items-center justify-center"
              >
                <BarChart3 className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                {loading ? t('common.loading') : t('reports.generate')}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Report Content */}
      {reportData && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <SummaryCard
              title={t('reports.totalDebts')}
              value={reportData.summary[t('reports.totalDebts')]}
              icon={TrendingUp}
              color="text-red-600"
            />
            <SummaryCard
              title={t('reports.totalPayments')}
              value={reportData.summary[t('reports.totalPayments')]}
              icon={DollarSign}
              color="text-green-600"
            />
            <SummaryCard
              title={t('reports.netChange')}
              value={reportData.summary[t('reports.netChange')]}
              icon={BarChart3}
              color={reportData.summary[t('reports.netChange')] >= 0 ? 'text-red-600' : 'text-green-600'}
            />
            <SummaryCard
              title={t('reports.debtorCount')}
              value={reportData.summary[t('reports.debtorCount')]}
              icon={Users}
              color="text-blue-600"
            />
          </div>

          {/* Export Actions */}
          <div className="flex flex-wrap gap-2 mb-6">
            <button
              onClick={handlePrint}
              className="btn btn-secondary flex items-center"
            >
              <Printer className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
              {t('reports.print')}
            </button>
            
            <button
              onClick={handleExportCSV}
              className="btn btn-ghost flex items-center"
            >
              <Download className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
              {t('reports.export')} CSV
            </button>
            
            <button
              onClick={handleExportJSON}
              className="btn btn-ghost flex items-center"
            >
              <Download className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
              {t('reports.export')} JSON
            </button>
          </div>

          {/* Transactions Table */}
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">
                {t('reports.details')} ({reportData.transactions.length} {t('debtor.transactions')})
              </h3>
            </div>
            <div className="card-content">
              {reportData.transactions.length === 0 ? (
                <div className="text-center py-8">
                  <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500">
                    {t('reports.noTransactions')}
                  </p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('common.date')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('debtors.name')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('transaction.type')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('transaction.amount')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('transaction.product')}
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          {t('transaction.notes')}
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {reportData.transactions.map((transaction) => (
                        <tr key={transaction.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {formatDate(transaction.createdAt, i18n.language)}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                            {transaction.debtorName}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                              transaction.type === 'debt' 
                                ? 'bg-red-100 text-red-800' 
                                : 'bg-green-100 text-green-800'
                            }`}>
                              {transaction.type === 'debt' ? t('transaction.types.debt') : t('transaction.types.payment')}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            <span className={transaction.type === 'debt' ? 'text-red-600' : 'text-green-600'}>
                              {formatCurrency(transaction.amount, transaction.currency || 'IQD', i18n.language)}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {transaction.product || '-'}
                          </td>
                          <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                            {transaction.notes || '-'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
};

export default Reports;