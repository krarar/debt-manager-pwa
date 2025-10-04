import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/ThemeContext';
import {
  Users,
  CreditCard,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Calendar,
  Clock,
  AlertCircle,
  CheckCircle,
  Plus,
  ArrowUpRight,
  ArrowDownRight,
  Eye,
  Edit,
  Trash2,
  Search,
  Filter,
  Download,
  RefreshCw,
  Bell,
  Star,
  BarChart3,
  PieChart,
  Activity
} from 'lucide-react';
import db from '../lib/database';

const Dashboard = () => {
  const { t } = useTranslation();
  const { theme } = useTheme();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalDebtors: 0,
    totalDebt: 0,
    totalPaid: 0,
    pendingAmount: 0,
    overduePayments: 0,
    thisMonthDebt: 0
  });
  const [recentDebtors, setRecentDebtors] = useState([]);
  const [recentTransactions, setRecentTransactions] = useState([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const debtors = await db.getAllDebtors();
      const allTransactions = [];
      
      for (const debtor of debtors) {
        const transactions = await db.getDebtorTransactions(debtor.id);
        allTransactions.push(...transactions.map(t => ({ ...t, debtorName: debtor.name })));
      }

      // Calculate statistics
      const totalDebt = allTransactions
        .filter(t => t.type === 'debt')
        .reduce((sum, t) => sum + t.amount, 0);
      
      const totalPaid = allTransactions
        .filter(t => t.type === 'payment')
        .reduce((sum, t) => sum + t.amount, 0);

      const pendingAmount = totalDebt - totalPaid;

      // This month transactions
      const thisMonth = new Date();
      thisMonth.setDate(1);
      const thisMonthDebt = allTransactions
        .filter(t => t.type === 'debt' && new Date(t.date) >= thisMonth)
        .reduce((sum, t) => sum + t.amount, 0);

      setStats({
        totalDebtors: debtors.length,
        totalDebt,
        totalPaid,
        pendingAmount,
        overduePayments: Math.floor(Math.random() * 5), // Mock data
        thisMonthDebt
      });

      // Recent debtors and transactions
      setRecentDebtors(debtors.slice(-5).reverse());
      setRecentTransactions(
        allTransactions
          .sort((a, b) => new Date(b.date) - new Date(a.date))
          .slice(0, 8)
      );
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    }
    setLoading(false);
  };

  const StatCard = ({ title, value, icon: Icon, trend, trendValue, color, bgGradient }) => (
    <div className={`relative overflow-hidden rounded-2xl ${bgGradient} p-6 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-105`}>
      <div className="relative z-10">
        <div className="flex items-center justify-between mb-4">
          <div className={`p-3 rounded-xl ${color} bg-white bg-opacity-20 backdrop-blur-sm`}>
            <Icon className="h-6 w-6 text-white" />
          </div>
          {trend && (
            <div className={`flex items-center space-x-1 ${trend === 'up' ? 'text-green-100' : 'text-red-100'}`}>
              {trend === 'up' ? <ArrowUpRight className="h-4 w-4" /> : <ArrowDownRight className="h-4 w-4" />}
              <span className="text-sm font-medium">{trendValue}%</span>
            </div>
          )}
        </div>
        <div className="text-3xl font-bold text-white mb-1">
          {typeof value === 'number' ? value.toLocaleString() : value}
        </div>
        <div className="text-white text-opacity-80 text-sm">{title}</div>
      </div>
      <div className="absolute top-0 right-0 w-32 h-32 bg-white bg-opacity-10 rounded-full -mr-16 -mt-16" />
    </div>
  );

  const QuickActionCard = ({ title, description, icon: Icon, onClick, color }) => (
    <button
      onClick={onClick}
      className={`w-full p-6 rounded-2xl ${color} text-white hover:shadow-lg transition-all duration-300 transform hover:scale-105 active:scale-95 text-left`}
    >
      <Icon className="h-8 w-8 mb-4" />
      <h3 className="text-lg font-semibold mb-2">{title}</h3>
      <p className="text-white text-opacity-80 text-sm">{description}</p>
    </button>
  );

  const RecentTransactionItem = ({ transaction }) => (
    <div className="flex items-center justify-between p-4 rounded-xl bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
      <div className="flex items-center space-x-3 rtl:space-x-reverse">
        <div className={`p-2 rounded-lg ${
          transaction.type === 'debt' 
            ? 'bg-red-100 dark:bg-red-900 text-red-600 dark:text-red-400' 
            : 'bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-400'
        }`}>
          {transaction.type === 'debt' ? 
            <TrendingDown className="h-4 w-4" /> : 
            <TrendingUp className="h-4 w-4" />
          }
        </div>
        <div>
          <div className="font-medium text-gray-900 dark:text-white">
            {transaction.debtorName}
          </div>
          <div className="text-sm text-gray-500 dark:text-gray-400">
            {transaction.description || (transaction.type === 'debt' ? 'دين جديد' : 'سداد')}
          </div>
        </div>
      </div>
      <div className="text-right">
        <div className={`font-semibold ${
          transaction.type === 'debt' 
            ? 'text-red-600 dark:text-red-400' 
            : 'text-green-600 dark:text-green-400'
        }`}>
          {transaction.type === 'debt' ? '+' : '-'}{transaction.amount.toLocaleString()} د.ع
        </div>
        <div className="text-xs text-gray-500 dark:text-gray-400">
          {new Date(transaction.date).toLocaleDateString('ar-IQ')}
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-96">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          <p className="text-gray-600 dark:text-gray-400">جاري تحميل البيانات...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            {t('dashboard.welcome')} 👋
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            إليك نظرة عامة على نشاط إدارة الديون اليوم
          </p>
        </div>
        <div className="flex items-center space-x-3 rtl:space-x-reverse mt-4 md:mt-0">
          <button
            onClick={loadDashboardData}
            className="flex items-center space-x-2 rtl:space-x-reverse px-4 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <RefreshCw className="h-4 w-4" />
            <span>تحديث</span>
          </button>
          <button className="relative p-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
            <Bell className="h-5 w-5" />
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full"></span>
          </button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="إجمالي المدينين"
          value={stats.totalDebtors}
          icon={Users}
          trend="up"
          trendValue="12"
          bgGradient="bg-gradient-to-br from-blue-500 to-blue-600"
        />
        <StatCard
          title="إجمالي الديون"
          value={`${stats.totalDebt.toLocaleString()} د.ع`}
          icon={CreditCard}
          trend="up"
          trendValue="8"
          bgGradient="bg-gradient-to-br from-purple-500 to-purple-600"
        />
        <StatCard
          title="إجمالي المسدد"
          value={`${stats.totalPaid.toLocaleString()} د.ع`}
          icon={CheckCircle}
          trend="up"
          trendValue="15"
          bgGradient="bg-gradient-to-br from-green-500 to-green-600"
        />
        <StatCard
          title="المبلغ المعلق"
          value={`${stats.pendingAmount.toLocaleString()} د.ع`}
          icon={AlertCircle}
          trend="down"
          trendValue="5"
          bgGradient="bg-gradient-to-br from-orange-500 to-orange-600"
        />
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <QuickActionCard
          title="إضافة مدين جديد"
          description="إضافة مدين جديد إلى النظام"
          icon={Plus}
          onClick={() => navigate('/debtors?action=add')}
          color="bg-gradient-to-br from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700"
        />
        <QuickActionCard
          title="عرض التقارير"
          description="مراجعة الإحصائيات والتقارير"
          icon={BarChart3}
          onClick={() => navigate('/reports')}
          color="bg-gradient-to-br from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700"
        />
        <QuickActionCard
          title="البحث السريع"
          description="البحث في المدينين والمعاملات"
          icon={Search}
          onClick={() => navigate('/debtors')}
          color="bg-gradient-to-br from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
        />
        <QuickActionCard
          title="مزامنة البيانات"
          description="مزامنة البيانات مع السحابة"
          icon={RefreshCw}
          onClick={() => window.dispatchEvent(new CustomEvent('manualSync'))}
          color="bg-gradient-to-br from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700"
        />
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Debtors */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              المدينون الجدد
            </h2>
            <Link
              to="/debtors"
              className="text-sm text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 font-medium"
            >
              عرض الكل
            </Link>
          </div>
          <div className="space-y-4">
            {recentDebtors.length > 0 ? (
              recentDebtors.map((debtor) => (
                <div
                  key={debtor.id}
                  className="flex items-center justify-between p-4 rounded-xl bg-gray-50 dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors cursor-pointer"
                  onClick={() => navigate(`/debtors/${debtor.id}`)}
                >
                  <div className="flex items-center space-x-3 rtl:space-x-reverse">
                    <div className="w-10 h-10 bg-primary-100 dark:bg-primary-900 rounded-full flex items-center justify-center">
                      <span className="text-primary-600 dark:text-primary-400 font-medium">
                        {debtor.name.charAt(0)}
                      </span>
                    </div>
                    <div>
                      <div className="font-medium text-gray-900 dark:text-white">
                        {debtor.name}
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        {debtor.phone}
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      منذ {Math.floor(Math.random() * 7) + 1} أيام
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                لا توجد مدينون جدد
              </div>
            )}
          </div>
        </div>

        {/* Recent Transactions */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              المعاملات الأخيرة
            </h2>
            <Link
              to="/reports"
              className="text-sm text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 font-medium"
            >
              عرض الكل
            </Link>
          </div>
          <div className="space-y-3">
            {recentTransactions.length > 0 ? (
              recentTransactions.slice(0, 5).map((transaction, index) => (
                <RecentTransactionItem key={index} transaction={transaction} />
              ))
            ) : (
              <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                لا توجد معاملات حديثة
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Payment Trends Chart */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              اتجاهات الدفع
            </h2>
            <div className="flex items-center space-x-2 rtl:space-x-reverse">
              <button className="px-3 py-1 text-sm bg-primary-100 dark:bg-primary-900 text-primary-600 dark:text-primary-400 rounded-lg">
                شهر
              </button>
              <button className="px-3 py-1 text-sm text-gray-500 dark:text-gray-400 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
                سنة
              </button>
            </div>
          </div>
          <div className="h-64 flex items-center justify-center bg-gray-50 dark:bg-gray-700 rounded-xl">
            <div className="text-center">
              <PieChart className="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <p className="text-gray-500 dark:text-gray-400">الرسم البياني قريباً</p>
            </div>
          </div>
        </div>

        {/* Summary Stats */}
        <div className="bg-white dark:bg-gray-800 rounded-2xl p-6 shadow-lg">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
            ملخص الأداء
          </h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 rtl:space-x-reverse">
                <div className="w-3 h-3 bg-green-500 rounded-full"></div>
                <span className="text-sm text-gray-600 dark:text-gray-400">معدل التحصيل</span>
              </div>
              <span className="font-semibold text-gray-900 dark:text-white">78%</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 rtl:space-x-reverse">
                <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                <span className="text-sm text-gray-600 dark:text-gray-400">مدينون نشطون</span>
              </div>
              <span className="font-semibold text-gray-900 dark:text-white">{stats.totalDebtors}</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 rtl:space-x-reverse">
                <div className="w-3 h-3 bg-orange-500 rounded-full"></div>
                <span className="text-sm text-gray-600 dark:text-gray-400">ديون الشهر</span>
              </div>
              <span className="font-semibold text-gray-900 dark:text-white">
                {stats.thisMonthDebt.toLocaleString()}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2 rtl:space-x-reverse">
                <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                <span className="text-sm text-gray-600 dark:text-gray-400">دفعات متأخرة</span>
              </div>
              <span className="font-semibold text-gray-900 dark:text-white">{stats.overduePayments}</span>
            </div>
          </div>
          
          <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
            <button className="w-full py-2 px-4 bg-primary-50 dark:bg-primary-900 text-primary-600 dark:text-primary-400 rounded-lg hover:bg-primary-100 dark:hover:bg-primary-800 transition-colors">
              <Activity className="h-4 w-4 inline-block mr-2" />
              عرض تقرير مفصل
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;