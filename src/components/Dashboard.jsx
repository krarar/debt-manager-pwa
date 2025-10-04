import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { 
  DollarSign, 
  Users, 
  AlertTriangle, 
  TrendingUp,
  Search,
  Calendar,
  Eye,
  FileText,
  Settings
} from 'lucide-react';

import db from '../lib/database';
import { formatCurrency, formatDate, formatRelativeTime } from '../i18n';

const Dashboard = () => {
  const { t, i18n } = useTranslation();
  const [stats, setStats] = useState({
    totalDebtors: 0,
    totalDebts: 0,
    totalPayments: 0,
    totalBalance: 0
  });
  const [recentTransactions, setRecentTransactions] = useState([]);
  const [overdueDebtors, setOverdueDebtors] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [loading, setLoading] = useState(true);

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
    <div className="page-container">
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">{t('dashboard.title')}</h1>
        <p className="page-subtitle">
          {formatDate(new Date(), i18n.language, { 
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
          })}
        </p>
      </div>

      {/* Quick Search */}
      <div className="mb-8">
        <div className="max-w-lg mx-auto">
          <div className="relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
              placeholder={t('dashboard.quickSearch')}
              className="input pl-10 pr-4"
            />
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Search className="h-5 w-5 text-gray-400" />
            </div>
          </div>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          title={t('dashboard.totalDebtors')}
          value={stats.totalDebtors.toLocaleString()}
          icon={Users}
          color="text-blue-600"
        />
        <StatCard
          title={t('dashboard.totalDebts')}
          value={formatCurrency(stats.totalDebts, 'IQD', i18n.language)}
          icon={TrendingUp}
          color="text-red-600"
        />
        <StatCard
          title={t('dashboard.totalRemaining')}
          value={formatCurrency(stats.totalBalance, 'IQD', i18n.language)}
          icon={DollarSign}
          color="text-orange-600"
        />
        <StatCard
          title={t('dashboard.overdueDebts')}
          value={overdueDebtors.length.toLocaleString()}
          icon={AlertTriangle}
          color="text-red-600"
          subtitle={overdueDebtors.length > 0 ? t('dashboard.overdueDebts') : ''}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Activity */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900">
              {t('dashboard.recentActivity')}
            </h3>
          </div>
          <div className="card-content">
            {recentTransactions.length === 0 ? (
              <p className="text-gray-500 text-center py-4">
                {t('dashboard.noActivity')}
              </p>
            ) : (
              <div className="space-y-3">
                {recentTransactions.map((transaction) => (
                  <div key={transaction.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">
                        {transaction.debtorName}
                      </p>
                      <p className="text-xs text-gray-500">
                        {transaction.type === 'debt' ? t('transaction.types.debt') : t('transaction.types.payment')}
                        {transaction.product && ` - ${transaction.product}`}
                      </p>
                      <p className="text-xs text-gray-400">
                        {formatRelativeTime(transaction.createdAt, i18n.language)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className={`text-sm font-medium ${
                        transaction.type === 'debt' ? 'text-red-600' : 'text-green-600'
                      }`}>
                        {transaction.type === 'debt' ? '+' : '-'}
                        {formatCurrency(transaction.amount, transaction.currency || 'IQD', i18n.language)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
            
            {recentTransactions.length > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-200">
                <Link
                  to="/reports"
                  className="text-primary-600 hover:text-primary-700 text-sm font-medium flex items-center"
                >
                  <Eye className="h-4 w-4 ltr:mr-1 rtl:ml-1" />
                  {t('reports.title')}
                </Link>
              </div>
            )}
          </div>
        </div>

        {/* Overdue Debtors */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900">
              {t('dashboard.overdueDebts')}
            </h3>
          </div>
          <div className="card-content">
            {overdueDebtors.length === 0 ? (
              <div className="text-center py-4">
                <AlertTriangle className="h-12 w-12 text-green-500 mx-auto mb-2" />
                <p className="text-gray-500">
                  {t('debtors.noDebtors')}
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {overdueDebtors.map((debtor) => (
                  <div key={debtor.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-b-0">
                    <div className="flex-1">
                      <p className="text-sm font-medium text-gray-900">
                        {debtor.name}
                      </p>
                      <p className="text-xs text-gray-500">
                        {debtor.phone}
                      </p>
                      <p className="text-xs text-gray-400">
                        {t('debtor.lastUpdate')}: {formatRelativeTime(debtor.updatedAt, i18n.language)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium text-red-600">
                        {formatCurrency(debtor.balance, 'IQD', i18n.language)}
                      </p>
                      <Link
                        to={`/debtor/${debtor.id}`}
                        className="text-xs text-primary-600 hover:text-primary-700"
                      >
                        {t('debtors.view')}
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}
            
            {overdueDebtors.length > 0 && (
              <div className="mt-4 pt-4 border-t border-gray-200">
                <Link
                  to="/debtors"
                  className="text-primary-600 hover:text-primary-700 text-sm font-medium flex items-center"
                >
                  <Users className="h-4 w-4 ltr:mr-1 rtl:ml-1" />
                  {t('debtors.title')}
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
        <Link
          to="/debtors"
          className="btn btn-primary flex items-center justify-center py-3"
        >
          <Users className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
          {t('debtors.addDebtor')}
        </Link>
        
        <Link
          to="/reports"
          className="btn btn-secondary flex items-center justify-center py-3"
        >
          <FileText className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
          {t('reports.title')}
        </Link>
        
        <Link
          to="/settings"
          className="btn btn-ghost flex items-center justify-center py-3"
        >
          <Settings className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
          {t('settings.title')}
        </Link>
      </div>
    </div>
  );
};

export default Dashboard;