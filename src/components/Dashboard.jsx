import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { useTheme } from '../contexts/ThemeContext';
import { useSearch } from '../contexts/SearchContext';
import { useNotification } from './NotificationSystem';
import { 
  DollarSign, 
  Users, 
  AlertTriangle, 
  TrendingUp,
  TrendingDown,
  Search,
  Calendar,
  Eye,
  FileText,
  Settings,
  Plus,
  ArrowRight,
  ArrowLeft,
  Clock,
  CheckCircle,
  XCircle,
  BarChart3,
  PieChart,
  Activity,
  CreditCard,
  Wallet,
  Target,
  Filter,
  Download,
  RefreshCw
} from 'lucide-react';

import db from '../lib/database';
import { formatCurrency, formatDate, formatRelativeTime } from '../i18n';

const Dashboard = () => {
  const { t, i18n } = useTranslation();
  const { isDark, accentColor } = useTheme();
  const { searchQuery, setSearchQuery } = useSearch();
  const { addNotification } = useNotification();
  
  const [stats, setStats] = useState({
    totalDebtors: 0,
    totalDebts: 0,
    totalPayments: 0,
    totalBalance: 0
  });
  const [recentTransactions, setRecentTransactions] = useState([]);
  const [overdueDebtors, setOverdueDebtors] = useState([]);
  const [filteredDebtors, setFilteredDebtors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [timeFilter, setTimeFilter] = useState('all');

  const isRTL = i18n.language === 'ar' || i18n.language === 'fa';

  useEffect(() => {
    loadDashboardData();
  }, []);

  // useEffect للبحث
  useEffect(() => {
    const performSearch = async () => {
      if (!searchQuery.trim()) {
        setFilteredDebtors([]);
        return;
      }

      try {
        const allDebtors = await db.getAllDebtors();
        const query = searchQuery.toLowerCase().trim();
        
        const filtered = allDebtors.filter(debtor => {
          const name = (debtor.name || '').toLowerCase();
          const phone = (debtor.phone || '').toLowerCase();
          const address = (debtor.address || '').toLowerCase();
          const notes = (debtor.notes || '').toLowerCase();
          
          return name.includes(query) ||
                 phone.includes(query) ||
                 address.includes(query) ||
                 notes.includes(query);
        });

        // إضافة رصيد كل مدين
        const enrichedFiltered = await Promise.all(
          filtered.map(async (debtor) => {
            const balance = await db.getDebtorBalance(debtor.id);
            return { ...debtor, balance };
          })
        );

        setFilteredDebtors(enrichedFiltered);
      } catch (error) {
        console.error('Search failed:', error);
        setFilteredDebtors([]);
      }
    };

    performSearch();
  }, [searchQuery]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      
      // Get statistics
      const statsData = await db.getDebtorStats();
      setStats(statsData);

      // Get recent transactions (last 10)
      const allTransactions = await db.getAllTransactions();
      const sortedTransactions = allTransactions
        .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
        .slice(0, 10);

      // Enrich transactions with debtor names
      const enrichedTransactions = await Promise.all(
        sortedTransactions.map(async (transaction) => {
          const debtor = await db.getDebtor(transaction.debtorId);
          return {
            ...transaction,
            debtorName: debtor?.name || 'Unknown'
          };
        })
      );

      setRecentTransactions(enrichedTransactions);

      // Get overdue debtors (those with positive balance and no activity in 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const allDebtors = await db.getAllDebtors();
      const overdueList = [];

      for (const debtor of allDebtors) {
        const balance = await db.getDebtorBalance(debtor.id);
        const lastUpdate = new Date(debtor.updatedAt);
        
        if (balance > 0 && lastUpdate < thirtyDaysAgo) {
          overdueList.push({
            ...debtor,
            balance
          });
        }
      }

      setOverdueDebtors(overdueList.slice(0, 5)); // Show top 5 overdue
      
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  // دالة لاختبار الإشعارات
  const testNotifications = () => {
    addNotification({
      type: 'success',
      title: 'تم بنجاح',
      message: 'تم إضافة مدين جديد بنجاح',
      persistent: true
    });

    setTimeout(() => {
      addNotification({
        type: 'warning',
        title: 'تحذير',
        message: 'يوجد دين مستحق منذ أكثر من 30 يوم',
        persistent: true
      });
    }, 1000);

    setTimeout(() => {
      addNotification({
        type: 'error',
        title: 'خطأ',
        message: 'فشل في حفظ البيانات',
        persistent: true
      });
    }, 2000);

    setTimeout(() => {
      addNotification({
        type: 'info',
        title: 'معلومات',
        message: 'تم تحديث النظام إلى الإصدار الجديد',
        persistent: true
      });
    }, 3000);
  };

  const handleSearch = async () => {
    if (!searchQuery.trim()) return;
    
    try {
      const debtors = await db.searchDebtors(searchQuery);
      const transactions = await db.searchTransactions(searchQuery);
      
      // Here you could show search results in a modal or navigate to results page
      console.log('Search results:', { debtors, transactions });
    } catch (error) {
      console.error('Search failed:', error);
    }
  };

  const StatCard = ({ title, value, icon: Icon, color, subtitle }) => (
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
                {value}
              </dd>
              {subtitle && (
                <dd className="text-sm text-gray-600">
                  {subtitle}
                </dd>
              )}
            </dl>
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
      {/* نتائج البحث */}
      {searchQuery && filteredDebtors.length > 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            نتائج البحث عن "{searchQuery}" ({filteredDebtors.length} نتيجة)
          </h3>
          <div className="grid gap-3">
            {filteredDebtors.slice(0, 5).map((debtor) => (
              <Link 
                key={debtor.id} 
                to={`/debtor/${debtor.id}`}
                className="flex items-center justify-between p-3 rounded-lg border border-gray-200 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              >
                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white">{debtor.name}</h4>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{debtor.phone}</p>
                </div>
                <div className="text-right">
                  <span className={`font-semibold ${debtor.balance > 0 ? 'text-red-600' : 'text-green-600'}`}>
                    {formatCurrency(debtor.balance, 'IQD', i18n.language)}
                  </span>
                </div>
              </Link>
            ))}
            {filteredDebtors.length > 5 && (
              <Link 
                to="/debtors" 
                className="text-center text-primary-600 dark:text-primary-400 hover:underline py-2"
              >
                عرض جميع النتائج ({filteredDebtors.length})
              </Link>
            )}
          </div>
        </div>
      )}

      {/* عرض رسالة في حالة عدم وجود نتائج */}
      {searchQuery && filteredDebtors.length === 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-8 text-center">
          <Search className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
            لا توجد نتائج للبحث
          </h3>
          <p className="text-gray-500 dark:text-gray-400">
            لم نجد أي نتائج تطابق "{searchQuery}"
          </p>
        </div>
      )}

      {/* عرض المحتوى العادي فقط عند عدم وجود بحث */}
      {!searchQuery && (
        <>
      {/* Page Header with Actions */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900 dark:text-white mb-2">
            {t('dashboard.title') || 'لوحة التحكم'}
          </h1>
          <p className="text-sm md:text-base text-gray-600 dark:text-gray-400">
            {formatDate(new Date(), i18n.language, { 
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            })}
          </p>
        </div>
        
        <div className="flex items-center space-x-4 rtl:space-x-reverse mt-4 lg:mt-0">
          <select
            value={timeFilter}
            onChange={(e) => setTimeFilter(e.target.value)}
            className="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="all">كل الوقت</option>
            <option value="today">اليوم</option>
            <option value="week">هذا الأسبوع</option>
            <option value="month">هذا الشهر</option>
          </select>
          
          <button className="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
            <RefreshCw className="w-5 h-5" />
          </button>
          
          <Link
            to="/debtors/new"
            className={`flex items-center space-x-2 rtl:space-x-reverse px-4 py-2 bg-${accentColor}-500 hover:bg-${accentColor}-600 text-white rounded-lg transition-colors shadow-sm`}
          >
            <Plus className="w-4 h-4" />
            <span>إضافة مدين</span>
          </Link>
        </div>
      </div>

      {/* Quick Search */}
      <div className="relative max-w-2xl">
        <div className="absolute inset-y-0 left-0 rtl:left-auto rtl:right-0 pl-3 rtl:pl-0 rtl:pr-3 flex items-center pointer-events-none">
          <Search className="h-5 w-5 text-gray-400" />
        </div>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
          placeholder={t('dashboard.quickSearch') || 'البحث السريع عن المدينين...'}
          className="w-full pl-10 rtl:pl-4 rtl:pr-10 pr-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-xl text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent shadow-sm"
        />
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all duration-300 group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm font-medium mb-1">إجمالي المدينين</p>
              <p className="text-3xl font-bold">{stats.totalDebtors}</p>
              <p className="text-blue-100 text-xs mt-1">
                <TrendingUp className="w-3 h-3 inline mr-1" />
                +2 هذا الشهر
              </p>
            </div>
            <div className="bg-white/20 rounded-full p-3 group-hover:scale-110 transition-transform duration-300">
              <Users className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all duration-300 group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm font-medium mb-1">إجمالي الديون</p>
              <p className="text-3xl font-bold">{formatCurrency(stats.totalDebts, i18n.language)}</p>
              <p className="text-green-100 text-xs mt-1">
                <TrendingUp className="w-3 h-3 inline mr-1" />
                +12% هذا الشهر
              </p>
            </div>
            <div className="bg-white/20 rounded-full p-3 group-hover:scale-110 transition-transform duration-300">
              <DollarSign className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all duration-300 group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-purple-100 text-sm font-medium mb-1">إجمالي المدفوعات</p>
              <p className="text-3xl font-bold">{formatCurrency(stats.totalPayments, i18n.language)}</p>
              <p className="text-purple-100 text-xs mt-1">
                <TrendingUp className="w-3 h-3 inline mr-1" />
                +8% هذا الشهر
              </p>
            </div>
            <div className="bg-white/20 rounded-full p-3 group-hover:scale-110 transition-transform duration-300">
              <Wallet className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-2xl p-6 text-white shadow-lg hover:shadow-xl transition-all duration-300 group">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-orange-100 text-sm font-medium mb-1">الرصيد المتبقي</p>
              <p className="text-3xl font-bold">{formatCurrency(stats.totalBalance, i18n.language)}</p>
              <p className="text-orange-100 text-xs mt-1">
                <TrendingDown className="w-3 h-3 inline mr-1" />
                -5% هذا الشهر
              </p>
            </div>
            <div className="bg-white/20 rounded-full p-3 group-hover:scale-110 transition-transform duration-300">
              <Target className="w-6 h-6" />
            </div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Transactions */}
        <div className="lg:col-span-2">
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700">
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white flex items-center">
                  <Activity className="w-5 h-5 mr-3 rtl:mr-0 rtl:ml-3 text-primary-500" />
                  المعاملات الأخيرة
                </h2>
                <Link
                  to="/reports"
                  className="text-primary-500 hover:text-primary-600 dark:text-primary-400 dark:hover:text-primary-300 text-sm font-medium flex items-center"
                >
                  عرض الكل
                  {isRTL ? <ArrowLeft className="w-4 h-4 ml-1" /> : <ArrowRight className="w-4 h-4 mr-1" />}
                </Link>
              </div>
            </div>
            <div className="p-6">
              {recentTransactions.length > 0 ? (
                <div className="space-y-4">
                  {recentTransactions.slice(0, 5).map((transaction, index) => (
                    <Link
                      key={transaction.id}
                      to={`/debtor/${transaction.debtorId}`}
                      className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700/50 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer group"
                    >
                      <div className="flex items-center space-x-4 rtl:space-x-reverse">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                          transaction.type === 'debt' 
                            ? 'bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400' 
                            : 'bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400'
                        }`}>
                          {transaction.type === 'debt' ? <TrendingUp className="w-5 h-5" /> : <TrendingDown className="w-5 h-5" />}
                        </div>
                        <div>
                          <p className="font-medium text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                            {transaction.debtorName}
                          </p>
                          <p className="text-sm text-gray-500 dark:text-gray-400">
                            {formatRelativeTime(transaction.createdAt, i18n.language)}
                          </p>
                        </div>
                      </div>
                      <div className="text-right rtl:text-left">
                        <p className={`font-semibold ${
                          transaction.type === 'debt' 
                            ? 'text-red-600 dark:text-red-400' 
                            : 'text-green-600 dark:text-green-400'
                        }`}>
                          {transaction.type === 'debt' ? '+' : '-'}{formatCurrency(transaction.amount, i18n.language)}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                          {transaction.product || 'معاملة عامة'}
                        </p>
                      </div>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8">
                  <Activity className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500 dark:text-gray-400">لا توجد معاملات حديثة</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Sidebar Content */}
        <div className="space-y-6">
          {/* Overdue Debtors */}
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700">
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white flex items-center">
                <AlertTriangle className="w-5 h-5 mr-3 rtl:mr-0 rtl:ml-3 text-orange-500" />
                ديون متأخرة
              </h2>
            </div>
            <div className="p-6">
              {overdueDebtors.length > 0 ? (
                <div className="space-y-3">
                  {overdueDebtors.slice(0, 3).map((debtor, index) => (
                    <Link
                      key={debtor.id}
                      to={`/debtor/${debtor.id}`}
                      className="block p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800 hover:bg-orange-100 dark:hover:bg-orange-900/30 transition-colors"
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-gray-900 dark:text-white">{debtor.name}</p>
                          <p className="text-sm text-orange-600 dark:text-orange-400">
                            {formatCurrency(debtor.balance, i18n.language)}
                          </p>
                        </div>
                        <Clock className="w-4 h-4 text-orange-500" />
                      </div>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="text-center py-4">
                  <CheckCircle className="w-8 h-8 text-green-500 mx-auto mb-2" />
                  <p className="text-sm text-gray-500 dark:text-gray-400">لا توجد ديون متأخرة</p>
                </div>
              )}
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700">
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white">إجراءات سريعة</h2>
            </div>
            <div className="p-6 space-y-3">
              <Link
                to="/debtors/new"
                className="flex items-center space-x-3 rtl:space-x-reverse p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800 hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors group"
              >
                <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center">
                  <Plus className="w-4 h-4 text-white" />
                </div>
                <span className="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
                  إضافة مدين جديد
                </span>
              </Link>

              <Link
                to="/reports"
                className="flex items-center space-x-3 rtl:space-x-reverse p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800 hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors group"
              >
                <div className="w-8 h-8 bg-green-500 rounded-lg flex items-center justify-center">
                  <BarChart3 className="w-4 h-4 text-white" />
                </div>
                <span className="font-medium text-gray-900 dark:text-white group-hover:text-green-600 dark:group-hover:text-green-400">
                  عرض التقارير
                </span>
              </Link>

              <Link
                to="/settings"
                className="flex items-center space-x-3 rtl:space-x-reverse p-3 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800 hover:bg-purple-100 dark:hover:bg-purple-900/30 transition-colors group"
              >
                <div className="w-8 h-8 bg-purple-500 rounded-lg flex items-center justify-center">
                  <Settings className="w-4 h-4 text-white" />
                </div>
                <span className="font-medium text-gray-900 dark:text-white group-hover:text-purple-600 dark:group-hover:text-purple-400">
                  الإعدادات
                </span>
              </Link>
            </div>
          </div>
        </div>
      </div>
        </>
      )}
    </div>
  );
};

export default Dashboard;