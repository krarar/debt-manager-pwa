import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/ThemeContext';
import { 
  Globe, 
  DollarSign, 
  Calendar,
  RefreshCw,
  Download,
  Upload,
  Printer,
  RotateCcw,
  Save,
  CheckCircle,
  XCircle,
  Sun,
  Moon,
  Monitor,
  Palette,
  Type,
  Volume2,
  Smartphone
} from 'lucide-react';

import db from '../lib/database';
import firebaseSync from '../lib/firebase';
import exportImport from '../lib/exportImport';
import { changeLanguage, languages } from '../i18n';
import { showNotification } from './NotificationSystem';

const Settings = () => {
  const { t, i18n } = useTranslation();
  const { 
    theme, 
    accentColor, 
    fontSize, 
    animations,
    setTheme,
    setAccentColor,
    setFontSize,
    setAnimations,
    toggleTheme,
    isDark 
  } = useTheme();
  
  const [settings, setSettings] = useState({
    language: 'ar',
    direction: 'auto',
    currency: 'IQD',
    dateFormat: 'dd/MM/yyyy',
    syncEnabled: false,
    syncOnStartup: false
  });
  const [syncStatus, setSyncStatus] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadSettings();
    loadSyncStatus();
  }, []);

  const loadSettings = async () => {
    try {
      const savedSettings = await db.getAllSettings();
      setSettings(prev => ({ ...prev, ...savedSettings }));
    } catch (error) {
      console.error('Failed to load settings:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadSyncStatus = async () => {
    try {
      const status = await firebaseSync.getSyncStatus();
      setSyncStatus(status);
    } catch (error) {
      console.error('Failed to load sync status:', error);
    }
  };

  const handleSaveSettings = async () => {
    try {
      setSaving(true);
      
      // Save each setting
      for (const [key, value] of Object.entries(settings)) {
        await db.setSetting(key, value);
      }

      // Apply language change if needed
      if (settings.language !== i18n.language) {
        changeLanguage(settings.language);
      }

      showNotification({
        type: 'success',
        title: t('common.success'),
        message: t('notifications.settingsSaved')
      });

    } catch (error) {
      console.error('Failed to save settings:', error);
      showNotification({
        type: 'error',
        title: t('common.error'),
        message: t('errors.general')
      });
    } finally {
      setSaving(false);
    }
  };

  const handleSyncNow = async () => {
    try {
      const result = await firebaseSync.performSync();
      
      if (result.success) {
        showNotification({
          type: 'success',
          message: t('settings.syncSettings.syncSuccess')
        });
      } else {
        showNotification({
          type: 'error',
          message: t('settings.syncSettings.syncError')
        });
      }
      
      await loadSyncStatus();
    } catch (error) {
      console.error('Sync failed:', error);
      showNotification({
        type: 'error',
        message: t('settings.syncSettings.syncError')
      });
    }
  };

  const handleExportData = async () => {
    try {
      await exportImport.exportAllDataAsJSON();
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

  const handleImportData = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    try {
      const result = await exportImport.importDataFromJSON(file, { merge: false });
      
      if (result.success) {
        showNotification({
          type: 'success',
          message: t('notifications.dataImported')
        });
        // Reload settings after import
        await loadSettings();
      } else {
        showNotification({
          type: 'error',
          message: result.message
        });
      }
    } catch (error) {
      console.error('Import failed:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    }

    // Reset file input
    event.target.value = '';
  };

  const handleFactoryReset = async () => {
    const confirmText = prompt(t('settings.resetSettings.confirmText'));
    
    if (confirmText !== 'DELETE' && confirmText !== 'حذف') {
      return;
    }

    if (!confirm(t('settings.resetSettings.confirm'))) {
      return;
    }

    try {
      await db.clearAllData();
      localStorage.clear();
      
      showNotification({
        type: 'success',
        message: t('settings.resetSettings.success')
      });

      // Reload the page
      setTimeout(() => {
        window.location.reload();
      }, 2000);
      
    } catch (error) {
      console.error('Factory reset failed:', error);
      showNotification({
        type: 'error',
        message: t('errors.general')
      });
    }
  };

  const SettingSection = ({ title, icon: Icon, children }) => (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 mb-4">
      <div className="p-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center">
          <Icon className="h-4 w-4 md:h-5 md:w-5 text-primary-600 dark:text-primary-400 ltr:mr-2 rtl:ml-2 md:ltr:mr-3 md:rtl:ml-3" />
          <h3 className="text-base md:text-lg font-medium text-gray-900 dark:text-white">{title}</h3>
        </div>
      </div>
      <div className="p-4 space-y-3">
        {children}
      </div>
    </div>
  );

  const SettingItem = ({ label, description, children }) => (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between py-2 gap-2">
      <div className="flex-1 min-w-0">
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
          {label}
        </label>
        {description && (
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{description}</p>
        )}
      </div>
      <div className="flex-shrink-0">
        {children}
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
    <div className="p-3 md:p-6 max-w-4xl mx-auto">
      {/* Page Header */}
      <div className="mb-6">
        <h1 className="text-xl md:text-2xl font-bold text-gray-900 dark:text-white mb-2">
          {t('settings.title')}
        </h1>
        <p className="text-sm text-gray-600 dark:text-gray-400">
          {t('settings.description')}
        </p>
      </div>

      {/* Language & Localization */}
      <SettingSection title={t('settings.language')} icon={Globe}>
        <SettingItem label={t('settings.language')}>
          <select
            value={settings.language}
            onChange={(e) => setSettings(prev => ({ ...prev, language: e.target.value }))}
            className="w-full sm:w-32 px-3 py-2 text-sm bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            {Object.entries(languages).map(([code, config]) => (
              <option key={code} value={code}>
                {config.name}
              </option>
            ))}
          </select>
        </SettingItem>

        <SettingItem label={t('settings.direction')}>
          <select
            value={settings.direction}
            onChange={(e) => setSettings(prev => ({ ...prev, direction: e.target.value }))}
            className="w-full sm:w-32 px-3 py-2 text-sm bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="auto">{t('settings.directions.auto')}</option>
            <option value="rtl">{t('settings.directions.rtl')}</option>
            <option value="ltr">{t('settings.directions.ltr')}</option>
          </select>
        </SettingItem>

        <SettingItem label={t('settings.currency')}>
          <select
            value={settings.currency}
            onChange={(e) => setSettings(prev => ({ ...prev, currency: e.target.value }))}
            className="input w-40"
          >
            {Object.entries(t('settings.currencies', { returnObjects: true })).map(([code, name]) => (
              <option key={code} value={code}>
                {name} ({code})
              </option>
            ))}
          </select>
        </SettingItem>

        <SettingItem label={t('settings.dateFormat')}>
          <select
            value={settings.dateFormat}
            onChange={(e) => setSettings(prev => ({ ...prev, dateFormat: e.target.value }))}
            className="input w-40"
          >
            {Object.entries(t('settings.dateFormats', { returnObjects: true })).map(([format, label]) => (
              <option key={format} value={format}>
                {label}
              </option>
            ))}
          </select>
        </SettingItem>
      </SettingSection>

      {/* Theme & Appearance */}
      <SettingSection title="المظهر والثيم" icon={Palette}>
        <SettingItem label="الوضع" description="اختر بين الوضع الفاتح والمظلم">
          <div className="flex items-center space-x-3 rtl:space-x-reverse">
            <button
              onClick={() => setTheme('light')}
              className={`flex items-center space-x-2 rtl:space-x-reverse px-3 py-2 rounded-lg border transition-colors ${
                theme === 'light'
                  ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400'
                  : 'border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <Sun className="w-4 h-4" />
              <span className="text-sm">فاتح</span>
            </button>
            
            <button
              onClick={() => setTheme('dark')}
              className={`flex items-center space-x-2 rtl:space-x-reverse px-3 py-2 rounded-lg border transition-colors ${
                theme === 'dark'
                  ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400'
                  : 'border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <Moon className="w-4 h-4" />
              <span className="text-sm">مظلم</span>
            </button>
            
            <button
              onClick={() => {
                const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
                setTheme(systemTheme);
              }}
              className="flex items-center space-x-2 rtl:space-x-reverse px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              <Monitor className="w-4 h-4" />
              <span className="text-sm">النظام</span>
            </button>
          </div>
        </SettingItem>

        <SettingItem label="اللون الأساسي" description="اختر لونك المفضل للتطبيق">
          <div className="grid grid-cols-4 gap-2">
            {[
              { name: 'blue', color: 'bg-blue-500', label: 'أزرق' },
              { name: 'green', color: 'bg-green-500', label: 'أخضر' },
              { name: 'purple', color: 'bg-purple-500', label: 'بنفسجي' },
              { name: 'pink', color: 'bg-pink-500', label: 'وردي' },
              { name: 'orange', color: 'bg-orange-500', label: 'برتقالي' },
              { name: 'red', color: 'bg-red-500', label: 'أحمر' },
              { name: 'teal', color: 'bg-teal-500', label: 'أخضر مائي' },
              { name: 'indigo', color: 'bg-indigo-500', label: 'نيلي' }
            ].map((colorOption) => (
              <button
                key={colorOption.name}
                onClick={() => setAccentColor(colorOption.name)}
                className={`flex flex-col items-center p-2 rounded-lg border transition-all ${
                  accentColor === colorOption.name
                    ? 'border-2 border-gray-800 dark:border-gray-200 shadow-md'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
                title={colorOption.label}
              >
                <div className={`w-6 h-6 ${colorOption.color} rounded-full mb-1`}></div>
                <span className="text-xs text-gray-600 dark:text-gray-400">{colorOption.label}</span>
              </button>
            ))}
          </div>
        </SettingItem>

        <SettingItem label="حجم الخط" description="اضبط حجم النص حسب تفضيلك">
          <div className="flex items-center space-x-2 rtl:space-x-reverse">
            {[
              { size: 'small', label: 'صغير' },
              { size: 'medium', label: 'متوسط' },
              { size: 'large', label: 'كبير' },
              { size: 'xlarge', label: 'كبير جداً' }
            ].map((sizeOption) => (
              <button
                key={sizeOption.size}
                onClick={() => setFontSize(sizeOption.size)}
                className={`px-3 py-2 rounded-lg border transition-colors ${
                  fontSize === sizeOption.size
                    ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400'
                    : 'border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
                }`}
              >
                <span className={`text-${sizeOption.size === 'small' ? 'xs' : sizeOption.size === 'medium' ? 'sm' : sizeOption.size === 'large' ? 'base' : 'lg'}`}>
                  {sizeOption.label}
                </span>
              </button>
            ))}
          </div>
        </SettingItem>

        <SettingItem label="الحركات والتأثيرات" description="تفعيل أو إلغاء الحركات البصرية">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={animations}
              onChange={(e) => setAnimations(e.target.checked)}
              className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
            />
            <span className="ml-2 rtl:ml-0 rtl:mr-2 text-sm text-gray-700 dark:text-gray-300">
              تفعيل الحركات
            </span>
          </label>
        </SettingItem>

        <SettingItem label="استعراض سريع للثيم">
          <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-900 dark:text-white">عينة من التصميم</span>
              <div className={`w-3 h-3 rounded-full bg-${accentColor}-500`}></div>
            </div>
            <p className="text-xs text-gray-600 dark:text-gray-400 mb-3">
              هذا مثال على كيف ستبدو النصوص والألوان في التطبيق مع الثيم الحالي.
            </p>
            <div className="flex space-x-2 rtl:space-x-reverse">
              <button className={`px-3 py-1 bg-${accentColor}-500 text-white rounded text-xs`}>
                زر أساسي
              </button>
              <button className="px-3 py-1 bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded text-xs">
                زر ثانوي
              </button>
            </div>
          </div>
        </SettingItem>
      </SettingSection>

      {/* Synchronization */}
      <SettingSection title={t('settings.sync')} icon={RefreshCw}>
        <SettingItem 
          label={t('settings.syncSettings.enable')}
          description={t('settings.syncSettings.description')}
        >
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={settings.syncEnabled}
              onChange={(e) => setSettings(prev => ({ ...prev, syncEnabled: e.target.checked }))}
              className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
            />
          </label>
        </SettingItem>

        {settings.syncEnabled && (
          <>
            <SettingItem label={t('settings.syncSettings.syncOnStartup')}>
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={settings.syncOnStartup}
                  onChange={(e) => setSettings(prev => ({ ...prev, syncOnStartup: e.target.checked }))}
                  className="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                />
              </label>
            </SettingItem>

            <SettingItem 
              label={t('settings.syncSettings.lastSync')}
              description={syncStatus.lastSyncAt ? 
                new Date(syncStatus.lastSyncAt).toLocaleString() : 
                t('settings.syncSettings.never')
              }
            >
              <button
                onClick={handleSyncNow}
                disabled={syncStatus.syncInProgress}
                className="btn btn-secondary flex items-center"
              >
                <RefreshCw className={`h-4 w-4 ltr:mr-2 rtl:ml-2 ${syncStatus.syncInProgress ? 'animate-spin' : ''}`} />
                {syncStatus.syncInProgress ? t('settings.syncSettings.syncing') : t('settings.syncSettings.syncNow')}
              </button>
            </SettingItem>

            <div className="flex items-center space-x-2 rtl:space-x-reverse text-sm">
              {syncStatus.isOnline ? (
                <>
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  <span className="text-green-600">{t('common.online')}</span>
                </>
              ) : (
                <>
                  <XCircle className="h-4 w-4 text-red-500" />
                  <span className="text-red-600">{t('common.offline')}</span>
                </>
              )}
              {syncStatus.queueLength > 0 && (
                <span className="text-gray-600">
                  ({syncStatus.queueLength} {t('settings.syncSettings.pending')})
                </span>
              )}
            </div>
          </>
        )}
      </SettingSection>

      {/* Backup & Export */}
      <SettingSection title={t('settings.backup')} icon={Download}>
        <SettingItem 
          label={t('settings.backupSettings.export')}
          description={t('settings.backupSettings.exportDescription')}
        >
          <button
            onClick={handleExportData}
            className="btn btn-secondary flex items-center"
          >
            <Download className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            {t('settings.backupSettings.exportAll')}
          </button>
        </SettingItem>

        <SettingItem 
          label={t('settings.backupSettings.import')}
          description={t('settings.backupSettings.importDescription')}
        >
          <label className="btn btn-secondary flex items-center cursor-pointer">
            <Upload className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
            {t('settings.backupSettings.import')}
            <input
              type="file"
              accept=".json"
              onChange={handleImportData}
              className="hidden"
            />
          </label>
        </SettingItem>
      </SettingSection>

      {/* Printing Settings */}
      <SettingSection title={t('settings.printing')} icon={Printer}>
        <SettingItem label={t('settings.printSettings.businessName')}>
          <input
            type="text"
            placeholder={t('settings.printSettings.businessName')}
            className="input w-60"
          />
        </SettingItem>

        <SettingItem label={t('settings.printSettings.businessPhone')}>
          <input
            type="text"
            placeholder={t('settings.printSettings.businessPhone')}
            className="input w-60"
          />
        </SettingItem>
      </SettingSection>

      {/* Factory Reset */}
      <SettingSection title={t('settings.factoryReset')} icon={RotateCcw}>
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <XCircle className="h-5 w-5 text-red-400" />
            </div>
            <div className="ltr:ml-3 rtl:mr-3 flex-1">
              <h4 className="text-sm font-medium text-red-800">
                {t('settings.resetSettings.warning')}
              </h4>
              <p className="text-sm text-red-700 mt-1">
                {t('settings.resetSettings.description')}
              </p>
              <div className="mt-4">
                <button
                  onClick={handleFactoryReset}
                  className="btn btn-danger"
                >
                  <RotateCcw className="h-4 w-4 ltr:mr-2 rtl:ml-2" />
                  {t('settings.resetSettings.reset')}
                </button>
              </div>
            </div>
          </div>
        </div>
      </SettingSection>

      {/* Save Button */}
      <div className="sticky bottom-4 bg-white border border-gray-200 rounded-lg p-4 shadow-lg">
        <button
          onClick={handleSaveSettings}
          disabled={saving}
          className="btn btn-primary w-full flex items-center justify-center"
        >
          <Save className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
          {saving ? t('common.loading') : t('forms.save')}
        </button>
      </div>
    </div>
  );
};

export default Settings;