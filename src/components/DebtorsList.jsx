import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { useTheme } from '../contexts/ThemeContext';
import { useSearch } from '../contexts/SearchContext';
import { useNotification } from './NotificationSystem';
import { 
  Plus, 
  Search, 
  Filter, 
  Eye, 
  Edit, 
  Trash2,
  Phone,
  MapPin,
  DollarSign,
  Users,
  Calendar,
  SortAsc,
  SortDesc,
  Grid,
  List,
  MoreVertical,
  UserPlus,
  Banknote,
  AlertCircle,
  CheckCircle,
  Clock,
  Star,
  Archive
} from 'lucide-react';

import db from '../lib/database';
import { formatCurrency, formatRelativeTime } from '../i18n';

const DebtorsList = () => {
  const { t, i18n } = useTranslation();
  const { isDark, accentColor } = useTheme();
  const { searchQuery } = useSearch(); // استخدام البحث العام
  const { addNotification } = useNotification();
  
  const [debtors, setDebtors] = useState([]);
  const [filteredDebtors, setFilteredDebtors] = useState([]);
  const [localSearchQuery, setLocalSearchQuery] = useState(''); // للبحث المحلي
  const [filter, setFilter] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [sortOrder, setSortOrder] = useState('asc');
  const [viewMode, setViewMode] = useState('grid');
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedDebtors, setSelectedDebtors] = useState([]);

  const isRTL = i18n.language === 'ar' || i18n.language === 'fa';

  useEffect(() => {
    loadDebtors();
  }, []);

  useEffect(() => {
    filterDebtors();
  }, [debtors, searchQuery, localSearchQuery, filter]);

  const loadDebtors = async () => {
    try {
      setLoading(true);
      const debtorsData = await db.getAllDebtors();
      
      // Enrich with balance information
      const enrichedDebtors = await Promise.all(
        debtorsData.map(async (debtor) => {
          const balance = await db.getDebtorBalance(debtor.id);
          return { ...debtor, balance };
        })
      );

      setDebtors(enrichedDebtors);
    } catch (error) {
      console.error('Failed to load debtors:', error);
    } finally {
      setLoading(false);
    }
  };

  const filterDebtors = () => {
    let filtered = [...debtors];

    // Apply search filter - بحث شامل (من البحث العام أو المحلي)
    const activeSearchQuery = searchQuery || localSearchQuery;
    if (activeSearchQuery && activeSearchQuery.trim()) {
      const query = activeSearchQuery.toLowerCase().trim();
      filtered = filtered.filter(debtor => {
        const name = (debtor.name || '').toLowerCase();
        const phone = (debtor.phone || '').toLowerCase();
        const address = (debtor.address || '').toLowerCase();
        const notes = (debtor.notes || '').toLowerCase();
        const balance = debtor.balance.toString();
        
        return name.includes(query) ||
               phone.includes(query) ||
               address.includes(query) ||
               notes.includes(query) ||
               balance.includes(query);
      });
    }

    // Apply category filter
    switch (filter) {
      case 'overdue':
        // Filter debtors with positive balance and no activity in 30 days
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        filtered = filtered.filter(debtor => 
          debtor.balance > 0 && new Date(debtor.updatedAt) < thirtyDaysAgo
        );
        break;
      case 'recent':
        // Filter debtors updated in the last 7 days
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        filtered = filtered.filter(debtor => 
          new Date(debtor.updatedAt) > sevenDaysAgo
        );
        break;
      case 'highAmount':
        // Filter debtors with balance > 500,000 IQD
        filtered = filtered.filter(debtor => debtor.balance > 500000);
        break;
      default:
        // 'all' - no additional filtering
        break;
    }

    // Sort by balance (highest first)
    filtered.sort((a, b) => b.balance - a.balance);

    setFilteredDebtors(filtered);
  };

  const handleEditDebtor = (debtor) => {
    // يمكن إضافة modal للتعديل هنا أو التوجه لصفحة تعديل
    console.log('Edit debtor:', debtor);
  };

  const handleDeleteDebtorFromCard = async (debtorId, e) => {
    e.preventDefault(); // منع انتقال Link
    e.stopPropagation();
    
    if (!confirm('هل أنت متأكد من حذف هذا المدين؟')) return;
    
    try {
      await db.deleteDebtor(debtorId);
      await loadDebtors(); // Reload the list
      addNotification({
        type: 'success',
        title: 'نجح الحذف',
        message: 'تم حذف المدين بنجاح'
      });
    } catch (error) {
      console.error('Failed to delete debtor:', error);
      addNotification({
        type: 'error', 
        title: 'خطأ في الحذف',
        message: 'فشل في حذف المدين'
      });
    }
  };

  const handleDeleteDebtor = async (debtorId) => {
    if (!confirm(t('debtor.confirmDelete'))) return;
    
    try {
      await db.deleteDebtor(debtorId);
      await loadDebtors(); // Reload the list
      addNotification({
        type: 'success',
        title: 'نجح الحذف',
        message: 'تم حذف المدين بنجاح'
      });
    } catch (error) {
      console.error('Failed to delete debtor:', error);
      addNotification({
        type: 'error',
        title: 'خطأ في الحذف', 
        message: t('errors.general')
      });
    }
  };

  const DebtorCard = ({ debtor }) => (
    <div className="card hover:shadow-md transition-shadow">
      <div className="card-content">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {debtor.name}
            </h3>
            
            <div className="space-y-1 text-sm text-gray-600">
              <div className="flex items-center">
                <Phone className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                {debtor.phone}
              </div>
              
              {debtor.address && (
                <div className="flex items-center">
                  <MapPin className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                  {debtor.address}
                </div>
              )}
              
              <div className="flex items-center">
                <DollarSign className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                <span className={`font-medium ${
                  debtor.balance > 0 ? 'text-red-600' : 
                  debtor.balance < 0 ? 'text-green-600' : 'text-gray-600'
                }`}>
                  {formatCurrency(Math.abs(debtor.balance), 'IQD', i18n.language)}
                  {debtor.balance > 0 && ` (${t('transaction.types.debt')})`}
                  {debtor.balance < 0 && ` (${t('transaction.types.payment')})`}
                </span>
              </div>
            </div>
            
            <p className="text-xs text-gray-400 mt-2">
              {t('debtor.lastUpdate')}: {formatRelativeTime(debtor.updatedAt, i18n.language)}
            </p>
          </div>
          
          <div className="flex space-x-2 rtl:space-x-reverse">
            <Link
              to={`/debtor/${debtor.id}`}
              className="p-2 text-primary-600 hover:text-primary-700 hover:bg-primary-50 rounded-md"
              title={t('debtors.view')}
            >
              <Eye className="h-4 w-4" />
            </Link>
            
            <button
              onClick={() => handleDeleteDebtor(debtor.id)}
              className="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 rounded-md"
              title={t('debtors.delete')}
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
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

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Page Header */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            {t('debtors.title') || 'المدينون'}
          </h1>
          <div className="flex items-center space-x-4 rtl:space-x-reverse text-sm text-gray-600 dark:text-gray-400">
            <span className="flex items-center">
              <Users className="w-4 h-4 mr-1 rtl:mr-0 rtl:ml-1" />
              {filteredDebtors.length} مدين
            </span>
            <span className="flex items-center">
              <DollarSign className="w-4 h-4 mr-1 rtl:mr-0 rtl:ml-1" />
              {formatCurrency(filteredDebtors.reduce((sum, d) => sum + d.balance, 0), i18n.language)}
            </span>
          </div>
        </div>
        
        <div className="flex items-center space-x-3 rtl:space-x-reverse mt-4 lg:mt-0">
          {/* View Mode Toggle */}
          <div className="flex bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-md transition-colors ${
                viewMode === 'grid'
                  ? 'bg-white dark:bg-gray-600 text-primary-600 dark:text-primary-400 shadow-sm'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
              }`}
            >
              <Grid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-md transition-colors ${
                viewMode === 'list'
                  ? 'bg-white dark:bg-gray-600 text-primary-600 dark:text-primary-400 shadow-sm'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
              }`}
            >
              <List className="w-4 h-4" />
            </button>
          </div>

          {/* Add Debtor Button */}
          <button
            onClick={() => setShowAddModal(true)}
            className={`flex items-center space-x-2 rtl:space-x-reverse px-4 py-2 bg-${accentColor}-500 hover:bg-${accentColor}-600 text-white rounded-lg transition-colors shadow-sm`}
          >
            <UserPlus className="w-4 h-4" />
            <span>إضافة مدين</span>
          </button>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0 lg:space-x-4 rtl:lg:space-x-reverse">
        {/* Search */}
        <div className="relative flex-1 max-w-lg">
          <div className="absolute inset-y-0 left-0 rtl:left-auto rtl:right-0 pl-3 rtl:pl-0 rtl:pr-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="text"
            value={localSearchQuery}
            onChange={(e) => setLocalSearchQuery(e.target.value)}
            placeholder="البحث عن المدينين..."
            className="w-full pl-10 rtl:pl-4 rtl:pr-10 pr-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-xl text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent shadow-sm"
          />
        </div>

        <div className="flex items-center space-x-3 rtl:space-x-reverse">
          {/* Filter */}
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="all">كل المدينين</option>
            <option value="active">نشط</option>
            <option value="overdue">متأخر</option>
            <option value="paid">مسدد</option>
          </select>

          {/* Sort */}
          <select
            value={`${sortBy}-${sortOrder}`}
            onChange={(e) => {
              const [field, order] = e.target.value.split('-');
              setSortBy(field);
              setSortOrder(order);
            }}
            className="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="name-asc">الاسم أ-ي</option>
            <option value="name-desc">الاسم ي-أ</option>
            <option value="balance-desc">الرصيد (الأعلى أولاً)</option>
            <option value="balance-asc">الرصيد (الأقل أولاً)</option>
            <option value="createdAt-desc">الأحدث أولاً</option>
            <option value="createdAt-asc">الأقدم أولاً</option>
          </select>
        </div>
      </div>

      {/* Content */}
      {filteredDebtors.length === 0 ? (
        <div className="text-center py-12">
          <Users className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
            {(searchQuery || localSearchQuery) ? 'لا توجد نتائج' : 'لا يوجد مدينون'}
          </h3>
          <p className="text-gray-500 dark:text-gray-400 mb-6">
            {(searchQuery || localSearchQuery) 
              ? 'جرب تعديل مصطلحات البحث أو إزالة الفلاتر' 
              : 'ابدأ بإضافة أول مدين لك'}
          </p>
          {!(searchQuery || localSearchQuery) && (
            <Link
              to="/debtors/new"
              className={`inline-flex items-center space-x-2 rtl:space-x-reverse px-4 py-2 bg-${accentColor}-500 hover:bg-${accentColor}-600 text-white rounded-lg transition-colors`}
            >
              <UserPlus className="w-4 h-4" />
              <span>إضافة مدين جديد</span>
            </Link>
          )}
        </div>
      ) : (
        <>
          {/* Debtors Grid/List */}
          {viewMode === 'grid' ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {filteredDebtors.map((debtor) => (
                <DebtorCard key={debtor.id} debtor={debtor} onEdit={handleEditDebtor} onDelete={handleDeleteDebtorFromCard} />
              ))}
            </div>
          ) : (
            <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 dark:bg-gray-700/50">
                    <tr>
                      <th className="px-6 py-4 text-right rtl:text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        المدين
                      </th>
                      <th className="px-6 py-4 text-right rtl:text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        الرصيد
                      </th>
                      <th className="px-6 py-4 text-right rtl:text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        آخر تحديث
                      </th>
                      <th className="px-6 py-4 text-right rtl:text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        الإجراءات
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                    {filteredDebtors.map((debtor) => (
                      <DebtorRow key={debtor.id} debtor={debtor} onEdit={handleEditDebtor} onDelete={handleDeleteDebtor} />
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}

      {/* Add Debtor Modal */}
      {showAddModal && (
        <AddDebtorModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            setShowAddModal(false);
            loadDebtors(); // Reload the debtors list
          }}
          addNotification={addNotification}
        />
      )}
    </div>
  );
};

// DebtorCard Component for Grid View
const DebtorCard = ({ debtor, onEdit, onDelete }) => {
  const { t, i18n } = useTranslation();
  const { accentColor } = useTheme();
  
  const getStatusColor = (balance) => {
    if (balance > 1000) return 'text-red-600 dark:text-red-400';
    if (balance > 0) return 'text-yellow-600 dark:text-yellow-400';
    return 'text-green-600 dark:text-green-400';
  };

  const getStatusIcon = (balance) => {
    if (balance > 1000) return AlertCircle;
    if (balance > 0) return Clock;
    return CheckCircle;
  };

  const StatusIcon = getStatusIcon(debtor.balance);

  return (
    <Link 
      to={`/debtor/${debtor.id}`}
      className="block bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-4 hover:shadow-xl hover:scale-105 transition-all duration-300 group cursor-pointer"
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3 rtl:space-x-reverse">
          <div className={`w-12 h-12 bg-${accentColor}-100 dark:bg-${accentColor}-900/30 rounded-full flex items-center justify-center`}>
            <Users className={`w-6 h-6 text-${accentColor}-600 dark:text-${accentColor}-400`} />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
              {debtor.name}
            </h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">{debtor.phone}</p>
          </div>
        </div>
        
        <div className="flex items-center space-x-1 rtl:space-x-reverse">
          <StatusIcon className={`w-5 h-5 ${getStatusColor(debtor.balance)}`} />
        </div>
      </div>

      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-sm text-gray-500 dark:text-gray-400">الرصيد</span>
          <span className={`font-semibold ${getStatusColor(debtor.balance)}`}>
            {formatCurrency(debtor.balance, i18n.language)}
          </span>
        </div>
        
        {debtor.address && (
          <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
            <MapPin className="w-4 h-4 mr-2 rtl:mr-0 rtl:ml-2" />
            <span className="truncate">{debtor.address}</span>
          </div>
        )}
        
        <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
          <Calendar className="w-4 h-4 mr-2 rtl:mr-0 rtl:ml-2" />
          <span>{formatRelativeTime(debtor.updatedAt, i18n.language)}</span>
        </div>
      </div>

      <div className="flex items-center justify-between mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
        <Link
          to={`/debtor/${debtor.id}`}
          className="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 text-sm font-medium flex items-center"
        >
          <Eye className="w-4 h-4 mr-1 rtl:mr-0 rtl:ml-1" />
          عرض التفاصيل
        </Link>
        
        <div className="flex items-center space-x-2 rtl:space-x-reverse">
          <button
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              onEdit(debtor);
            }}
            className="p-2 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"
            title="تعديل"
          >
            <Edit className="w-4 h-4" />
          </button>
          
          <button
            onClick={(e) => onDelete(debtor.id, e)}
            className="p-2 text-gray-500 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
            title="حذف"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </Link>
  );
};

// DebtorRow Component for List View
const DebtorRow = ({ debtor, onEdit, onDelete }) => {
  const { t, i18n } = useTranslation();
  
  const getStatusColor = (balance) => {
    if (balance > 1000) return 'text-red-600 dark:text-red-400';
    if (balance > 0) return 'text-yellow-600 dark:text-yellow-400';
    return 'text-green-600 dark:text-green-400';
  };

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
      <td className="px-6 py-4">
        <div className="flex items-center space-x-3 rtl:space-x-reverse">
          <div className="w-10 h-10 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center">
            <Users className="w-5 h-5 text-gray-500 dark:text-gray-400" />
          </div>
          <div>
            <div className="font-medium text-gray-900 dark:text-white">{debtor.name}</div>
            <div className="text-sm text-gray-500 dark:text-gray-400">{debtor.phone}</div>
          </div>
        </div>
      </td>
      
      <td className="px-6 py-4">
        <span className={`font-semibold ${getStatusColor(debtor.balance)}`}>
          {formatCurrency(debtor.balance, i18n.language)}
        </span>
      </td>
      
      <td className="px-6 py-4 text-sm text-gray-500 dark:text-gray-400">
        {formatRelativeTime(debtor.updatedAt, i18n.language)}
      </td>
      
      <td className="px-6 py-4">
        <div className="flex items-center space-x-2 rtl:space-x-reverse">
          <Link
            to={`/debtor/${debtor.id}`}
            className="p-2 text-gray-500 dark:text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 hover:bg-primary-50 dark:hover:bg-primary-900/30 rounded-lg transition-colors"
            title="عرض التفاصيل"
          >
            <Eye className="w-4 h-4" />
          </Link>
          
          <button
            onClick={() => onEdit(debtor)}
            className="p-2 text-gray-500 dark:text-gray-400 hover:text-blue-600 dark:hover:text-blue-400 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"
            title="تعديل"
          >
            <Edit className="w-4 h-4" />
          </button>
          
          <button
            onClick={() => onDelete(debtor.id)}
            className="p-2 text-gray-500 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
            title="حذف"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </td>
    </tr>
  );
};

// Add Debtor Modal Component
const AddDebtorModal = ({ onClose, onSuccess, addNotification }) => {
  const { t } = useTranslation();
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    address: '',
    notes: '',
    createdAt: new Date().toISOString().split('T')[0] // تاريخ اليوم افتراضياً
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.name.trim() || !formData.phone.trim()) {
      addNotification({
        type: 'warning',
        title: 'بيانات ناقصة',
        message: t('forms.validate.required')
      });
      return;
    }

    try {
      setLoading(true);
      // تحويل التاريخ إلى ISO string إذا تم تحديده
      const debtorData = {
        ...formData,
        createdAt: formData.createdAt ? new Date(formData.createdAt).toISOString() : new Date().toISOString()
      };
      await db.addDebtor(debtorData);
      addNotification({
        type: 'success',
        title: 'تمت الإضافة بنجاح',
        message: 'تم إضافة المدين الجديد بنجاح'
      });
      onSuccess();
    } catch (error) {
      console.error('Failed to add debtor:', error);
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
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            {t('debtors.addDebtor')}
          </h3>
        </div>
        
        <form onSubmit={handleSubmit} className="px-6 py-4 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('debtors.name')} *
            </label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="input"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('debtors.phone')} *
            </label>
            <input
              type="tel"
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
              className="input"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              تاريخ الإضافة
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
              {t('debtors.address')}
            </label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="input"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('debtor.notes')}
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              className="input"
              rows={3}
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

export default DebtorsList;