import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useNotification } from './NotificationSystem';
import { 
  ArrowLeft, 
  Phone, 
  MapPin, 
  Plus,
  DollarSign,
  Calendar,
  FileText,
  Printer,
  Download,
  Edit,
  Trash2
} from 'lucide-react';

import db from '../lib/database';
import printManager from '../lib/printManager';
import exportImport from '../lib/exportImport';
import { formatCurrency, formatDate, formatRelativeTime } from '../i18n';

const DebtorDetails = () => {
  const { t, i18n } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const { addNotification } = useNotification();
  
  const [debtor, setDebtor] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showAddTransaction, setShowAddTransaction] = useState(false);
  const [showEditDebtor, setShowEditDebtor] = useState(false);
  const [showEditTransaction, setShowEditTransaction] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState(null);

  useEffect(() => {
    if (id) {
      loadDebtorData();
    }
  }, [id]);

  const loadDebtorData = async () => {
    try {
      setLoading(true);
      
      const debtorData = await db.getDebtor(id);
      if (!debtorData) {
        navigate('/debtors');
        return;
      }
      
      const transactionsData = await db.getTransactionsByDebtor(id);
      const balanceData = await db.getDebtorBalance(id);
      
      setDebtor(debtorData);
      setTransactions(transactionsData.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
      setBalance(balanceData);
      
    } catch (error) {
      console.error('Failed to load debtor data:', error);
      addNotification({
        type: 'error',
        message: t('errors.general')
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteTransaction = async (transactionId) => {
    if (!confirm(t('transaction.confirmDelete'))) return;
    
    try {
      await db.deleteTransaction(transactionId);
      await loadDebtorData(); // Reload data
      
      addNotification({
        type: 'success',
        message: t('notifications.transactionDeleted')
      });
    } catch (error) {
      console.error('Failed to delete transaction:', error);
      addNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const handlePrintStatement = async () => {
    try {
      await printManager.printDebtorStatement(id);
    } catch (error) {
      console.error('Print failed:', error);
      addNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const handleExportData = async () => {
    try {
      await exportImport.exportDebtorData(id, 'json');
      addNotification({
        type: 'success',
        message: t('notifications.dataExported')
      });
    } catch (error) {
      console.error('Export failed:', error);
      addNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const TransactionCard = ({ transaction }) => (
    <div className="border border-gray-200 rounded-lg p-4 hover:shadow-sm transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <div className="flex items-center space-x-2 rtl:space-x-reverse mb-2">
            <span className={`px-2 py-1 rounded-full text-xs font-medium ${
              transaction.type === 'debt' 
                ? 'bg-red-100 text-red-800' 
                : 'bg-green-100 text-green-800'
            }`}>
              {transaction.type === 'debt' ? t('transaction.types.debt') : t('transaction.types.payment')}
            </span>
            
            <span className="text-xs text-gray-500">
              {formatDate(transaction.createdAt, i18n.language)}
            </span>
          </div>
          
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">{t('transaction.amount')}:</span>
              <span className={`font-medium ${
                transaction.type === 'debt' ? 'text-red-600' : 'text-green-600'
              }`}>
                {formatCurrency(transaction.amount, transaction.currency || 'IQD', i18n.language)}
              </span>
            </div>
            
            {transaction.product && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('transaction.product')}:</span>
                <span className="text-sm text-gray-900">{transaction.product}</span>
              </div>
            )}
            
            {transaction.paymentMethod && (
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">{t('transaction.paymentMethod')}:</span>
                <span className="text-sm text-gray-900">
                  {t(`transaction.paymentMethods.${transaction.paymentMethod}`, transaction.paymentMethod)}
                </span>
              </div>
            )}
            
            {transaction.notes && (
              <div className="mt-2">
                <span className="text-sm text-gray-600">{t('transaction.notes')}:</span>
                <p className="text-sm text-gray-900 mt-1">{transaction.notes}</p>
              </div>
            )}
          </div>
        </div>
        
        <div className="flex space-x-2 rtl:space-x-reverse ltr:ml-4 rtl:mr-4">
          <button
            onClick={() => {
              setEditingTransaction(transaction);
              setShowEditTransaction(true);
            }}
            className="p-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-md"
            title="تعديل"
          >
            <Edit className="h-4 w-4" />
          </button>
          
          <button
            onClick={() => handleDeleteTransaction(transaction.id)}
            className="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 rounded-md"
            title={t('forms.delete')}
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="page-container">
        <div className="flex items-center justify-center py-12">
          <div className="loading-spinner"></div>
          <span className="ltr:ml-2 rtl:mr-2">{t('common.loading')}</span>
        </div>
      </div>
    );
  }

  if (!debtor) {
    return (
      <div className="page-container">
        <div className="text-center py-12">
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {t('errors.notFound')}
          </h3>
          <Link to="/debtors" className="btn btn-primary">
            {t('common.back')}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      {/* Header */}
      <div className="page-header">
        <div className="flex items-center space-x-4 rtl:space-x-reverse mb-4">
          <button
            onClick={() => navigate('/debtors')}
            className="p-2 hover:bg-gray-100 rounded-md"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <div className="flex-1">
            <h1 className="page-title">{debtor.name}</h1>
            <p className="page-subtitle">
              {t('debtor.details')}
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setShowEditDebtor(true)}
            className="btn btn-secondary flex items-center"
          >
            <Edit className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            تعديل المدين
          </button>
          
          <button
            onClick={() => setShowAddTransaction(true)}
            className="btn btn-primary flex items-center"
          >
            <Plus className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            {t('debtor.addDebt')}
          </button>
          
          <button
            onClick={handlePrintStatement}
            className="btn btn-secondary flex items-center"
          >
            <Printer className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            {t('debtor.printReceipt')}
          </button>
          
          <button
            onClick={handleExportData}
            className="btn btn-ghost flex items-center"
          >
            <Download className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            {t('debtor.exportData')}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Debtor Information */}
        <div className="lg:col-span-1">
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">
                {t('debtor.personalInfo')}
              </h3>
            </div>
            <div className="card-content space-y-4">
              <div className="flex items-center">
                <Phone className="h-5 w-5 text-gray-400 ltr:mr-3 rtl:ml-3" />
                <span className="text-gray-900">{debtor.phone}</span>
              </div>
              
              {debtor.address && (
                <div className="flex items-center">
                  <MapPin className="h-5 w-5 text-gray-400 ltr:mr-3 rtl:ml-3" />
                  <span className="text-gray-900">{debtor.address}</span>
                </div>
              )}
              
              <div className="flex items-center">
                <Calendar className="h-5 w-5 text-gray-400 ltr:mr-3 rtl:ml-3" />
                <div>
                  <p className="text-sm text-gray-600">{t('debtor.createdAt')}</p>
                  <p className="text-gray-900">{formatDate(debtor.createdAt, i18n.language)}</p>
                </div>
              </div>
              
              <div className="flex items-center">
                <Calendar className="h-5 w-5 text-gray-400 ltr:mr-3 rtl:ml-3" />
                <div>
                  <p className="text-sm text-gray-600">{t('debtor.updatedAt')}</p>
                  <p className="text-gray-900">{formatRelativeTime(debtor.updatedAt, i18n.language)}</p>
                </div>
              </div>
              
              {debtor.notes && (
                <div>
                  <p className="text-sm text-gray-600 mb-1">{t('debtor.notes')}</p>
                  <p className="text-gray-900">{debtor.notes}</p>
                </div>
              )}
            </div>
          </div>

          {/* Balance Summary */}
          <div className="card mt-6">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">
                {t('debtor.totalBalance')}
              </h3>
            </div>
            <div className="card-content">
              <div className="text-center">
                <div className={`text-3xl font-bold mb-2 ${
                  balance > 0 ? 'text-red-600' : 
                  balance < 0 ? 'text-green-600' : 'text-gray-600'
                }`}>
                  {formatCurrency(Math.abs(balance), 'IQD', i18n.language)}
                </div>
                <p className="text-sm text-gray-600">
                  {balance > 0 && `${t('transaction.types.debt')} (${t('debtor.owes')})`}
                  {balance < 0 && `${t('transaction.types.payment')} (${t('debtor.overpaid')})`}
                  {balance === 0 && t('debtor.settled')}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Transactions */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="card-header">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-medium text-gray-900">
                  {t('debtor.transactions')} ({transactions.length})
                </h3>
                <button
                  onClick={() => setShowAddTransaction(true)}
                  className="btn btn-primary btn-sm flex items-center"
                >
                  <Plus className="h-4 w-4 ltr:mr-1 rtl:ml-1" />
                  {t('forms.add')}
                </button>
              </div>
            </div>
            <div className="card-content">
              {transactions.length === 0 ? (
                <div className="text-center py-8">
                  <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    {t('debtor.noTransactions')}
                  </h3>
                  <p className="text-gray-600 mb-4">
                    {t('debtor.addFirstTransaction')}
                  </p>
                  <button
                    onClick={() => setShowAddTransaction(true)}
                    className="btn btn-primary"
                  >
                    <Plus className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                    {t('debtor.addDebt')}
                  </button>
                </div>
              ) : (
                <div className="space-y-4">
                  {transactions.map((transaction) => (
                    <TransactionCard key={transaction.id} transaction={transaction} />
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Add Transaction Modal */}
      {showAddTransaction && (
        <AddTransactionModal
          debtorId={id}
          debtorName={debtor.name}
          onClose={() => setShowAddTransaction(false)}
          onSuccess={() => {
            setShowAddTransaction(false);
            loadDebtorData();
          }}
          addNotification={addNotification}
        />
      )}

      {/* Edit Debtor Modal */}
      {showEditDebtor && (
        <EditDebtorModal
          debtor={debtor}
          onClose={() => setShowEditDebtor(false)}
          onSuccess={() => {
            setShowEditDebtor(false);
            loadDebtorData();
          }}
        />
      )}

      {/* Edit Transaction Modal */}
      {showEditTransaction && (
        <EditTransactionModal
          transaction={editingTransaction}
          onClose={() => {
            setShowEditTransaction(false);
            setEditingTransaction(null);
          }}
          onSuccess={() => {
            setShowEditTransaction(false);
            setEditingTransaction(null);
            loadDebtorData();
          }}
          addNotification={addNotification}
        />
      )}
    </div>
  );
};

// Modal لتعديل بيانات المدين
const EditDebtorModal = ({ debtor, onClose, onSuccess }) => {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: debtor.name,
    phone: debtor.phone,
    address: debtor.address || '',
    notes: debtor.notes || ''
  });

  const handleSubmit = async () => {
    if (!formData.name.trim() || !formData.phone.trim()) {
      addNotification({
        type: 'warning',
        title: 'بيانات ناقصة',
        message: t('forms.fillRequired')
      });
      return;
    }

    try {
      setLoading(true);
      await db.updateDebtor(debtor.id, formData);
      addNotification({
        type: 'success',
        title: 'تم التحديث',
        message: 'تم تحديث بيانات المدين بنجاح'
      });
      onSuccess();
    } catch (error) {
      console.error('Failed to update debtor:', error);
      addNotification({
        type: 'error',
        title: 'خطأ في التحديث',
        message: t('errors.general')
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-medium">تعديل بيانات المدين</h3>
        </div>
        
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">الاسم *</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="input w-full"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">رقم الهاتف *</label>
            <input
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="input w-full"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">العنوان</label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="input w-full"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">ملاحظات</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input w-full"
              rows={3}
            />
          </div>
        </div>
        
        <div className="px-6 py-4 border-t border-gray-200 flex space-x-3 rtl:space-x-reverse">
          <button
            onClick={onClose}
            className="btn btn-secondary flex-1"
          >
            إلغاء
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="btn btn-primary flex-1"
          >
            {loading ? 'جاري الحفظ...' : 'حفظ التغييرات'}
          </button>
        </div>
      </div>
    </div>
  );
};

// Modal لتعديل المعاملة
const EditTransactionModal = ({ transaction, onClose, onSuccess, addNotification }) => {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    type: transaction.type,
    amount: transaction.amount,
    currency: transaction.currency || 'IQD',
    product: transaction.product || '',
    notes: transaction.notes || '',
    paymentMethod: transaction.paymentMethod || 'cash'
  });

  const handleSubmit = async () => {
    if (!formData.amount || formData.amount <= 0) {
      addNotification({
        type: 'warning',
        title: 'بيانات غير صحيحة',
        message: 'يرجى إدخال مبلغ صحيح'
      });
      return;
    }

    try {
      setLoading(true);
      await db.updateTransaction(transaction.id, formData);
      addNotification({
        type: 'success',
        title: 'تم التحديث',
        message: 'تم تحديث المعاملة بنجاح'
      });
      onSuccess();
    } catch (error) {
      console.error('Failed to update transaction:', error);
      addNotification({
        type: 'error',
        title: 'خطأ في التحديث',
        message: t('errors.general')
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-medium">تعديل المعاملة</h3>
        </div>
        
        <div className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">نوع المعاملة</label>
            <select
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
              className="input w-full"
            >
              <option value="debt">دين</option>
              <option value="payment">دفعة</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">المبلغ *</label>
            <input
              type="number"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: parseFloat(e.target.value) || 0 })}
              className="input w-full"
              min="0"
              step="0.01"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">العملة</label>
            <select
              value={formData.currency}
              onChange={(e) => setFormData({ ...formData, currency: e.target.value })}
              className="input w-full"
            >
              <option value="IQD">دينار عراقي (IQD)</option>
              <option value="USD">دولار أمريكي (USD)</option>
              <option value="EUR">يورو (EUR)</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">المنتج/الخدمة</label>
            <input
              type="text"
              value={formData.product}
              onChange={(e) => setFormData({ ...formData, product: e.target.value })}
              className="input w-full"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">ملاحظات</label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input w-full"
              rows={3}
            />
          </div>
        </div>
        
        <div className="px-6 py-4 border-t border-gray-200 flex space-x-3 rtl:space-x-reverse">
          <button
            onClick={onClose}
            className="btn btn-secondary flex-1"
          >
            إلغاء
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="btn btn-primary flex-1"
          >
            {loading ? 'جاري الحفظ...' : 'حفظ التغييرات'}
          </button>
        </div>
      </div>
    </div>
  );
};

// Add Transaction Modal Component
const AddTransactionModal = ({ debtorId, debtorName, onClose, onSuccess, addNotification }) => {
  const { t } = useTranslation();
  const [formData, setFormData] = useState({
    type: 'debt',
    amount: '',
    currency: 'IQD',
    product: '',
    notes: '',
    paymentMethod: 'cash',
    createdAt: new Date().toISOString().split('T')[0] // تاريخ اليوم افتراضياً
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.amount || parseFloat(formData.amount) <= 0) {
      addNotification({
        type: 'warning',
        title: 'بيانات غير صحيحة',
        message: t('forms.validate.positive')
      });
      return;
    }

    try {
      setLoading(true);
      
      await db.addTransaction({
        debtorId,
        type: formData.type,
        amount: parseFloat(formData.amount),
        currency: formData.currency,
        product: formData.product || null,
        notes: formData.notes || null,
        paymentMethod: formData.paymentMethod,
        createdAt: formData.createdAt ? new Date(formData.createdAt).toISOString() : new Date().toISOString()
      });

      addNotification({
        type: 'success',
        title: 'تمت الإضافة بنجاح',
        message: t('notifications.transactionAdded')
      });

      onSuccess();
    } catch (error) {
      console.error('Failed to add transaction:', error);
      addNotification({
        type: 'error',
        title: 'خطأ في الإضافة',
        message: t('errors.general')
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full max-h-screen overflow-y-auto">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            {t('debtor.addDebt')} - {debtorName}
          </h3>
        </div>
        
        <form onSubmit={handleSubmit} className="px-6 py-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.type')} *
            </label>
            <select
              value={formData.type}
              onChange={(e) => setFormData({ ...formData, type: e.target.value })}
              className="input"
              required
            >
              <option value="debt">{t('transaction.types.debt')}</option>
              <option value="payment">{t('transaction.types.payment')}</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.amount')} *
            </label>
            <input
              type="number"
              step="0.01"
              min="0"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              className="input"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.currency')}
            </label>
            <select
              value={formData.currency}
              onChange={(e) => setFormData({ ...formData, currency: e.target.value })}
              className="input"
            >
              <option value="IQD">دينار عراقي (IQD)</option>
              <option value="USD">دولار أمريكي (USD)</option>
              <option value="EUR">يورو (EUR)</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              تاريخ المعاملة
            </label>
            <input
              type="date"
              value={formData.createdAt}
              onChange={(e) => setFormData({ ...formData, createdAt: e.target.value })}
              className="input"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.product')}
            </label>
            <input
              type="text"
              value={formData.product}
              onChange={(e) => setFormData({ ...formData, product: e.target.value })}
              className="input"
              placeholder="بضائع متنوعة..."
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.paymentMethod')}
            </label>
            <select
              value={formData.paymentMethod}
              onChange={(e) => setFormData({ ...formData, paymentMethod: e.target.value })}
              className="input"
            >
              {Object.entries(t('transaction.paymentMethods', { returnObjects: true })).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('transaction.notes')}
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input"
              rows={3}
              placeholder="ملاحظات إضافية..."
            />
          </div>
        </form>
        
        <div className="px-6 py-4 border-t border-gray-200 flex space-x-3 rtl:space-x-reverse">
          <button
            type="button"
            onClick={onClose}
            className="btn btn-secondary flex-1"
          >
            {t('forms.cancel')}
          </button>
          <button
            onClick={handleSubmit}
            disabled={loading}
            className="btn btn-primary flex-1"
          >
            {loading ? t('common.loading') : t('forms.save')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default DebtorDetails;