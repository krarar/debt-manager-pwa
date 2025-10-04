import React, { useState, useEffect, useRef } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../contexts/ThemeContext';
import { useSearch } from '../contexts/SearchContext';
import {
  Home,
  Users,
  FileText,
  Settings,
  HelpCircle,
  Menu,
  X,
  Sun,
  Moon,
  Monitor,
  ChevronLeft,
  ChevronRight,
  Bell,
  Search,
  Plus,
  CreditCard,
  BarChart3,
  Download,
  Upload,
  RefreshCw,
  User,
  Calendar,
  DollarSign,
  TrendingUp,
  TrendingDown,
  Archive,
  BookOpen,
  Calculator,
  PieChart,
  Filter,
  SortAsc,
  Globe,
  Palette,
  Volume2,
  Wifi,
  WifiOff,
  Info,
  LogOut
} from 'lucide-react';
import OfflineIndicator from './OfflineIndicator';
import { NotificationIcon } from './NotificationSystem';
import NotificationSystem from './NotificationSystem';

const Layout = ({ children }) => {
  const { t, i18n } = useTranslation();
  const location = useLocation();
  const { 
    theme, 
    accentColor, 
    sidebarCollapsed, 
    toggleTheme, 
    toggleSidebar,
    setAccentColor,
    isDark 
  } = useTheme();
  
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false); // الشريط الجانبي مخفي افتراضياً
  
  const userMenuRef = useRef(null);
  
  const { searchQuery, setSearchQuery } = useSearch();

  const isRTL = i18n.language === 'ar' || i18n.language === 'fa';

  // Close user menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target)) {
        setShowUserMenu(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const mainMenuItems = [
    {
      path: '/',
      icon: Home,
      label: t('navigation.dashboard'),
      badge: null,
      color: 'text-blue-600 dark:text-blue-400'
    },
    {
      path: '/debtors',
      icon: Users,
      label: t('navigation.debtors'),
      badge: '12',
      color: 'text-green-600 dark:text-green-400'
    },
    {
      path: '/reports',
      icon: BarChart3,
      label: t('navigation.reports'),
      badge: null,
      color: 'text-purple-600 dark:text-purple-400'
    },
    {
      path: '/settings',
      icon: Settings,
      label: t('navigation.settings'),
      badge: null,
      color: 'text-gray-600 dark:text-gray-400'
    },
    {
      path: '/about',
      icon: Info,
      label: t('navigation.about'),
      badge: null,
      color: 'text-orange-600 dark:text-orange-400'
    }
  ];

  const quickActions = [
    {
      path: '/debtors/new',
      icon: User,
      label: t('quickActions.addDebtor') || 'إضافة مدين',
      color: 'bg-gradient-to-r from-blue-500 to-blue-600'
    },
    {
      path: '/transactions/new',
      icon: Plus,
      label: t('quickActions.addTransaction') || 'إضافة معاملة',
      color: 'bg-gradient-to-r from-green-500 to-green-600'
    }
  ];

  const toolsMenu = [
    {
      path: '/calculator',
      icon: Calculator,
      label: t('tools.calculator') || 'آلة حاسبة',
      color: 'text-indigo-600 dark:text-indigo-400'
    },
    {
      path: '/analytics',
      icon: PieChart,
      label: t('tools.analytics') || 'تحليلات',
      color: 'text-pink-600 dark:text-pink-400'
    },
    {
      path: '/export',
      icon: Download,
      label: t('tools.export') || 'تصدير',
      color: 'text-teal-600 dark:text-teal-400'
    },
    {
      path: '/import',
      icon: Upload,
      label: t('tools.import') || 'استيراد',
      color: 'text-red-600 dark:text-red-400'
    },
    {
      path: '/backup',
      icon: Archive,
      label: t('tools.backup') || 'نسخ احتياطي',
      color: 'text-yellow-600 dark:text-yellow-400'
    },
    {
      path: '/sync',
      icon: RefreshCw,
      label: t('tools.sync') || 'مزامنة',
      color: 'text-cyan-600 dark:text-cyan-400'
    }
  ];

  const isActive = (path) => {
    if (path === '/') {
      return location.pathname === '/';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <div className={`flex h-screen bg-gray-50 dark:bg-gray-900 transition-all duration-300 ${isRTL ? 'rtl' : 'ltr'}`}>
      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside 
        className={`flex-shrink-0 ${
          sidebarCollapsed ? 'w-16' : 'w-72'
        } bg-white dark:bg-gray-800 border-${isRTL ? 'l' : 'r'} border-gray-200 dark:border-gray-700 transition-all duration-300 shadow-xl overflow-y-auto
        ${/* Mobile styles */ ''}
        md:relative md:translate-x-0
        ${sidebarOpen ? 'fixed inset-y-0 left-0 z-50 translate-x-0' : 'fixed inset-y-0 left-0 z-50 -translate-x-full'} 
        md:block`}
      >
        {/* Sidebar Header */}
        <div className={`flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700 ${sidebarCollapsed ? 'px-2' : ''}`}>
          {!sidebarCollapsed && (
            <div className="flex items-center space-x-3 rtl:space-x-reverse">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                <CreditCard className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-gray-900 dark:text-white">
                  {t('appTitle') || 'مدير الديون'}
                </h2>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  إدارة ديونك بسهولة
                </p>
              </div>
            </div>
          )}
          
          <button
            onClick={toggleSidebar}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
          >
            {sidebarCollapsed ? (
              isRTL ? <ChevronLeft className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />
            ) : (
              isRTL ? <ChevronRight className="w-5 h-5" /> : <ChevronLeft className="w-5 h-5" />
            )}
          </button>
        </div>

        {/* Quick Actions */}
        {!sidebarCollapsed && (
          <div className="p-4 border-b border-gray-200 dark:border-gray-700">
            <h3 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
              إجراءات سريعة
            </h3>
            <div className="grid grid-cols-2 gap-2">
              {quickActions.map((action) => {
                const IconComponent = action.icon;
                return (
                  <Link
                    key={action.path}
                    to={action.path}
                    className="bg-gradient-to-r from-blue-500 to-purple-600 text-white p-3 rounded-lg text-center hover:opacity-90 transition-opacity group flex flex-col items-center"
                  >
                    <IconComponent className="w-4 h-4 mb-1" />
                    <span className="text-xs font-medium">{action.label}</span>
                  </Link>
                );
              })}
            </div>
          </div>
        )}

        {/* Main Navigation */}
        <nav className="p-2 space-y-1">
          {!sidebarCollapsed && (
            <h3 className="px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
              التنقل
            </h3>
          )}
          
          {mainMenuItems.map((item) => {
            const IconComponent = item.icon;
            const active = isActive(item.path);
            
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center px-3 py-2.5 rounded-lg transition-all duration-200 group ${
                  active
                    ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400 shadow-sm'
                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700/50'
                } ${sidebarCollapsed ? 'justify-center' : ''}`}
              >
                <IconComponent className={`w-5 h-5 ${active ? item.color : 'text-gray-500 dark:text-gray-400'} ${sidebarCollapsed ? '' : 'mr-3 rtl:mr-0 rtl:ml-3'}`} />
                {!sidebarCollapsed && (
                  <>
                    <span className="font-medium flex-1">{item.label}</span>
                    {item.badge && (
                      <span className="bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-xs font-semibold px-2 py-0.5 rounded-full">
                        {item.badge}
                      </span>
                    )}
                  </>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Tools Section */}
        <div className="mt-6 p-2 border-t border-gray-200 dark:border-gray-700">
          {!sidebarCollapsed && (
            <h3 className="px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-3">
              الأدوات
            </h3>
          )}
          
          <div className={`space-y-1 ${sidebarCollapsed ? 'grid grid-cols-1 gap-1' : ''}`}>
            {toolsMenu.map((tool) => {
              const IconComponent = tool.icon;
              return (
                <Link
                  key={tool.path}
                  to={tool.path}
                  className={`flex items-center px-3 py-2 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors ${
                    sidebarCollapsed ? 'justify-center' : ''
                  }`}
                  title={sidebarCollapsed ? tool.label : ''}
                >
                  <IconComponent className={`w-4 h-4 ${tool.color} ${sidebarCollapsed ? '' : 'mr-3 rtl:mr-0 rtl:ml-3'}`} />
                  {!sidebarCollapsed && (
                    <span className="text-sm">{tool.label}</span>
                  )}
                </Link>
              );
            })}
          </div>
        </div>

        {/* Theme Toggle */}
        <div className="absolute bottom-4 left-4 right-4">
          <button
            onClick={toggleTheme}
            className={`w-full flex items-center px-3 py-2.5 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors ${
              sidebarCollapsed ? 'justify-center' : ''
            }`}
            title={sidebarCollapsed ? (isDark ? 'فاتح' : 'مظلم') : ''}
          >
            {isDark ? (
              <Sun className={`w-5 h-5 text-yellow-500 ${sidebarCollapsed ? '' : 'mr-3 rtl:mr-0 rtl:ml-3'}`} />
            ) : (
              <Moon className={`w-5 h-5 text-gray-500 dark:text-gray-400 ${sidebarCollapsed ? '' : 'mr-3 rtl:mr-0 rtl:ml-3'}`} />
            )}
            {!sidebarCollapsed && (
              <span className="font-medium">{isDark ? 'الوضع الفاتح' : 'الوضع المظلم'}</span>
            )}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Top Header */}
        <header className="flex-shrink-0 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-3 md:px-6 py-3 shadow-sm">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center space-x-2 rtl:space-x-reverse">
              {/* Mobile Menu Button */}
              <button
                onClick={() => setSidebarOpen(!sidebarOpen)}
                className="md:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <Menu className="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            
            {/* Search Bar - المنتصف */}
            <div className="flex-1 max-w-md mx-4">
              <div className="relative">
                <Search className="absolute left-3 rtl:left-auto rtl:right-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="البحث في التطبيق..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 rtl:pl-3 rtl:pr-9 pr-3 py-2 text-sm bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                />
              </div>
            </div>
            
            <div className="flex items-center space-x-2 rtl:space-x-reverse">
              {/* Notifications */}
              <NotificationIcon />

              {/* User Menu */}
              <div className="relative" ref={userMenuRef}>
                <button
                  onClick={() => setShowUserMenu(!showUserMenu)}
                  className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                >
                  <User className="w-5 h-5 text-gray-500 dark:text-gray-400" />
                </button>

                {/* User Menu Dropdown */}
                {showUserMenu && (
                  <div className="absolute top-12 right-0 rtl:right-auto rtl:left-0 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1 z-50">
                    <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-700">
                      <p className="text-sm font-medium text-gray-900 dark:text-white">المستخدم</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">debt-manager@app.com</p>
                    </div>
                    
                    <Link
                      to="/settings"
                      onClick={() => setShowUserMenu(false)}
                      className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <Settings className="w-4 h-4 ml-3 rtl:ml-0 rtl:mr-3" />
                      الإعدادات
                    </Link>
                    
                    <Link
                      to="/about"
                      onClick={() => setShowUserMenu(false)}
                      className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <Info className="w-4 h-4 ml-3 rtl:ml-0 rtl:mr-3" />
                      حول التطبيق
                    </Link>
                    
                    <button
                      onClick={() => {
                        setShowUserMenu(false);
                        toggleTheme();
                      }}
                      className="flex items-center w-full px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      {isDark ? <Sun className="w-4 h-4 ml-3 rtl:ml-0 rtl:mr-3" /> : <Moon className="w-4 h-4 ml-3 rtl:ml-0 rtl:mr-3" />}
                      {isDark ? 'المظهر الفاتح' : 'المظهر الداكن'}
                    </button>
                    
                    <div className="border-t border-gray-200 dark:border-gray-700 mt-1">
                      <button
                        onClick={() => {
                          setShowUserMenu(false);
                          // Add logout functionality here
                          window.location.reload();
                        }}
                        className="flex items-center w-full px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                      >
                        <LogOut className="w-4 h-4 ml-3 rtl:ml-0 rtl:mr-3" />
                        تسجيل الخروج
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {children}
        </div>
      </main>

      {/* Notification System */}
      <NotificationSystem />
    </div>
  );
};

export default Layout;