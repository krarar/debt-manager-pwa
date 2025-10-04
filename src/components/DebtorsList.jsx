import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
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
  Users
} from 'lucide-react';

import db from '../lib/database';
import { formatCurrency, formatRelativeTime } from '../i18n';

const DebtorsList = () => {
  const { t, i18n } = useTranslation();
  const [debtors, setDebtors] = useState([]);
  const [filteredDebtors, setFilteredDebtors] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  useEffect(() => {
    loadDebtors();
  }, []);

  useEffect(() => {
    filterDebtors();
  }, [debtors, searchQuery, filter]);

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

    // Apply search filter
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(debtor =>
        debtor.name.toLowerCase().includes(query) ||
        debtor.phone.includes(query) ||
        (debtor.address && debtor.address.toLowerCase().includes(query))
      );
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

  const handleDeleteDebtor = async (debtorId) => {
    if (!confirm(t('debtor.confirmDelete'))) return;
    
    try {
      await db.deleteDebtor(debtorId);
      await loadDebtors(); // Reload the list
    } catch (error) {
      console.error('Failed to delete debtor:', error);
      alert(t('errors.general'));
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
    <div className="page-container">
      {/* Page Header */}
      <div className="page-header">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="page-title">{t('debtors.title')}</h1>
            <p className="page-subtitle">
              {filteredDebtors.length} {t('debtors.title')}
            </p>
          </div>
          
          <button
            onClick={() => setShowAddModal(true)}
            className="btn btn-primary flex items-center"
          >
            <Plus className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
            {t('debtors.addDebtor')}
          </button>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="mb-6 space-y-4">
        {/* Search */}
        <div className="relative max-w-md">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder={t('debtors.searchPlaceholder')}
            className="input pl-10 pr-4"
          />
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-gray-400" />
          </div>
        </div>

        {/* Filters */}
        <div className="flex space-x-2 rtl:space-x-reverse">
          <Filter className="h-5 w-5 text-gray-400 mt-2" />
          {[
            { key: 'all', label: t('debtors.filters.all') },
            { key: 'overdue', label: t('debtors.filters.overdue') },
            { key: 'recent', label: t('debtors.filters.recent') },
            { key: 'highAmount', label: t('debtors.filters.highAmount') }
          ].map((filterOption) => (
            <button
              key={filterOption.key}
              onClick={() => setFilter(filterOption.key)}
              className={`px-3 py-1 rounded-full text-sm font-medium transition-colors ${
                filter === filterOption.key
                  ? 'bg-primary-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              {filterOption.label}
            </button>
          ))}
        </div>
      </div>

      {/* Debtors List */}
      {filteredDebtors.length === 0 ? (
        <div className="text-center py-12">
          <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {searchQuery || filter !== 'all' ? t('debtors.noDebtors') : t('debtors.addFirstDebtor')}
          </h3>
          {!searchQuery && filter === 'all' && (
            <button
              onClick={() => setShowAddModal(true)}
              className="btn btn-primary mt-4"
            >
              <Plus className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
              {t('debtors.addDebtor')}
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredDebtors.map((debtor) => (
            <DebtorCard key={debtor.id} debtor={debtor} />
          ))}
        </div>
      )}

      {/* Add Debtor Modal */}
      {showAddModal && (
        <AddDebtorModal
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            setShowAddModal(false);
            loadDebtors();
          }}
        />
      )}
    </div>
  );
};

// Add Debtor Modal Component
const AddDebtorModal = ({ onClose, onSuccess }) => {
  const { t } = useTranslation();
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    address: '',
    notes: ''
  });
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.name.trim() || !formData.phone.trim()) {
      alert(t('forms.validate.required'));
      return;
    }

    try {
      setLoading(true);
      await db.addDebtor(formData);
      onSuccess();
    } catch (error) {
      console.error('Failed to add debtor:', error);
      alert(t('errors.general'));
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