import React, { useState } from 'react';
import { Outlet, Link, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/ThemeContext';
import { 
  Home, 
  Users, 
  FileText, 
  Settings, 
  Info, 
  Menu, 
  X, 
  Sun, 
  Moon, 
  Monitor,
  Palette,
  Bell,
  Search,
  Plus,
  Download,
  Upload,
  Sync,
  Calculator,
  TrendingUp,
  CreditCard,
  Archive,
  Star,
  Heart,
  Shield,
  Zap,
  Globe
} from 'lucide-react';
import OfflineIndicator from './OfflineIndicator';

const Layout = () => {
  const { t, i18n } = useTranslation();
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, accentColor, toggleTheme, setAccentColor, setLightTheme, setDarkTheme } = useTheme();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [quickActionsOpen, setQuickActionsOpen] = useState(false);
  const [themeMenuOpen, setThemeMenuOpen] = useState(false);
  const isRTL = i18n.language === 'ar' || i18n.language === 'fa' || i18n.language === 'ku';

  const navigationItems = [
    { 
      path: '/', 
      icon: Home, 
      label: t('nav.dashboard'), 
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-50 dark:bg-blue-900/20'
    },
    { 
      path: '/debtors', 
      icon: Users, 
      label: t('nav.debtors'), 
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-50 dark:bg-green-900/20'
    },
    { 
      path: '/reports', 
      icon: FileText, 
      label: t('nav.reports'), 
      color: 'text-purple-600 dark:text-purple-400',
      bgColor: 'bg-purple-50 dark:bg-purple-900/20'
    },
    { 
      path: '/settings', 
      icon: Settings, 
      label: t('nav.settings'), 
      color: 'text-orange-600 dark:text-orange-400',
      bgColor: 'bg-orange-50 dark:bg-orange-900/20'
    },
    { 
      path: '/about', 
      icon: Info, 
      label: t('nav.about'), 
      color: 'text-gray-600 dark:text-gray-400',
      bgColor: 'bg-gray-50 dark:bg-gray-800/20'
    },
  ];

  const quickActions = [
    { 
      icon: Plus, 
      label: t('quickActions.addDebtor'), 
      action: () => navigate('/debtors?action=add'),
      color: 'bg-gradient-to-br from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700'
    },
    { 
      icon: Calculator, 
      label: t('quickActions.calculate'), 
      action: () => navigate('/calculator'),
      color: 'bg-gradient-to-br from-green-500 to-green-600 hover:from-green-600 hover:to-green-700'
    },
    { 
      icon: TrendingUp, 
      label: t('quickActions.reports'), 
      action: () => navigate('/reports'),
      color: 'bg-gradient-to-br from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700'
    },
    { 
      icon: Sync, 
      label: t('quickActions.sync'), 
      action: () => window.dispatchEvent(new CustomEvent('manualSync')),
      color: 'bg-gradient-to-br from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700'
    },
  ];

  const accentColors = [
    { name: 'blue', color: 'bg-blue-500', label: t('colors.blue') },
    { name: 'green', color: 'bg-green-500', label: t('colors.green') },
    { name: 'purple', color: 'bg-purple-500', label: t('colors.purple') },
    { name: 'pink', color: 'bg-pink-500', label: t('colors.pink') },
    { name: 'orange', color: 'bg-orange-500', label: t('colors.orange') },
    { name: 'red', color: 'bg-red-500', label: t('colors.red') },
    { name: 'teal', color: 'bg-teal-500', label: t('colors.teal') },
    { name: 'indigo', color: 'bg-indigo-500', label: t('colors.indigo') },
  ];

  const isActivePath = (path) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  const SidebarContent = () => (
    <div className="flex flex-col h-full">
      {/* Logo and Title */}
      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center space-x-3 rtl:space-x-reverse">
          <div className="p-2 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg">
            <CreditCard className="h-6 w-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">
              {t('app.title')}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t('app.subtitle')}
            </p>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="p-4 border-b border-gray-200 dark:border-gray-700">
        <div className="relative">
          <button
            onClick={() => setQuickActionsOpen(!quickActionsOpen)}
            className="w-full flex items-center justify-between p-3 text-sm font-medium text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-800 rounded-xl hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          >
            <div className="flex items-center space-x-2 rtl:space-x-reverse">
              <Zap className="h-4 w-4" />
              <span>{t('sidebar.quickActions')}</span>
            </div>
            <div className={`transform transition-transform ${quickActionsOpen ? 'rotate-180' : ''}`}>
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </div>
          </button>
          
          {quickActionsOpen && (
            <div className="mt-2 grid grid-cols-2 gap-2 animate-slide-down">
              {quickActions.map((action, index) => (
                <button
                  key={index}
                  onClick={action.action}
                  className={`p-3 rounded-xl text-white text-xs font-medium transition-all transform hover:scale-105 active:scale-95 ${action.color} shadow-lg hover:shadow-xl`}
                >
                  <action.icon className="h-4 w-4 mx-auto mb-1" />
                  <div className="truncate">{action.label}</div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 p-4 space-y-1">
        {navigationItems.map((item) => {
          const isActive = isActivePath(item.path);
          const Icon = item.icon;
          
          return (
            <Link
              key={item.path}
              to={item.path}
              className={`
                group flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98]
                ${isActive 
                  ? `${item.bgColor} ${item.color} shadow-md` 
                  : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800'
                }
              `}
              onClick={() => setSidebarOpen(false)}
            >
              <Icon className={`h-5 w-5 ${isRTL ? 'ml-3' : 'mr-3'} transition-transform group-hover:scale-110`} />
              <span className="flex-1">{item.label}</span>
              {isActive && (
                <div className="w-2 h-2 bg-current rounded-full animate-pulse" />
              )}
            </Link>
          );
        })}
      </nav>

      {/* Theme and Appearance */}
      <div className="p-4 border-t border-gray-200 dark:border-gray-700">
        <div className="space-y-3">
          {/* Theme Toggle */}
          <div>
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-2 block">
              {t('settings.theme')}
            </label>
            <div className="flex space-x-1 rtl:space-x-reverse bg-gray-100 dark:bg-gray-800 rounded-lg p-1">
              <button
                onClick={setLightTheme}
                className={`flex-1 p-2 rounded-md transition-all ${theme === 'light' ? 'bg-white dark:bg-gray-700 shadow' : ''}`}
              >
                <Sun className="h-4 w-4 mx-auto text-yellow-500" />
              </button>
              <button
                onClick={setDarkTheme}
                className={`flex-1 p-2 rounded-md transition-all ${theme === 'dark' ? 'bg-white dark:bg-gray-700 shadow' : ''}`}
              >
                <Moon className="h-4 w-4 mx-auto text-gray-600 dark:text-gray-300" />
              </button>
            </div>
          </div>

          {/* Accent Color */}
          <div>
            <label className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-2 block">
              {t('settings.accentColor')}
            </label>
            <div className="grid grid-cols-4 gap-2">
              {accentColors.map((color) => (
                <button
                  key={color.name}
                  onClick={() => setAccentColor(color.name)}
                  className={`w-8 h-8 ${color.color} rounded-lg transition-all transform hover:scale-110 ${
                    accentColor === color.name ? 'ring-2 ring-gray-400 dark:ring-gray-500 ring-offset-2 ring-offset-white dark:ring-offset-gray-900' : ''
                  }`}
                  title={color.label}
                />
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="p-4 border-t border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
          <span>v1.1.0</span>
          <div className="flex items-center space-x-1 rtl:space-x-reverse">
            <Heart className="h-3 w-3 text-red-500" />
            <span>{t('footer.madeWith')}</span>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-300">
      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black bg-opacity-50 transition-opacity lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div className={`
        fixed inset-y-0 ${isRTL ? 'right-0' : 'left-0'} z-50 w-80 bg-white dark:bg-gray-800 shadow-xl transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0
        ${sidebarOpen ? 'translate-x-0' : isRTL ? 'translate-x-full' : '-translate-x-full'}
      `}>
        <SidebarContent />
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4 rtl:space-x-reverse">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden p-2 rounded-lg text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Menu className="h-6 w-6" />
              </button>
              
              <div className="hidden sm:block">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                  {navigationItems.find(item => isActivePath(item.path))?.label || t('nav.dashboard')}
                </h2>
              </div>
            </div>

            <div className="flex items-center space-x-3 rtl:space-x-reverse">
              {/* Search */}
              <div className="hidden md:block">
                <div className="relative">
                  <Search className="absolute left-3 rtl:left-auto rtl:right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <input
                    type="text"
                    placeholder={t('search.placeholder')}
                    className="pl-10 rtl:pl-4 rtl:pr-10 pr-4 py-2 w-64 text-sm bg-gray-100 dark:bg-gray-700 border border-transparent rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 dark:text-white dark:placeholder-gray-400"
                  />
                </div>
              </div>

              {/* Notifications */}
              <button className="relative p-2 rounded-lg text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors">
                <Bell className="h-5 w-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              {/* Theme toggle */}
              <button
                onClick={toggleTheme}
                className="p-2 rounded-lg text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                {theme === 'dark' ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
              </button>

              {/* Offline indicator */}
              <OfflineIndicator />
            </div>
          </div>
        </header>

        {/* Main content area */}
        <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900">
          <div className="container mx-auto p-6 max-w-7xl">
            <div className="animate-fade-in">
              <Outlet />
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default Layout;