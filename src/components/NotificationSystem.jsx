import React, { useState, useEffect, createContext, useContext, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { CheckCircle, XCircle, AlertCircle, Info, X, Bell, Trash2, Check } from 'lucide-react';

// Context for notifications
const NotificationContext = createContext();

export const useNotification = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotification must be used within NotificationProvider');
  }
  return context;
};

export const NotificationProvider = ({ children }) => {
  const [notifications, setNotifications] = useState([]);
  const [persistentNotifications, setPersistentNotifications] = useState([]); // للإشعارات الدائمة
  const [unreadCount, setUnreadCount] = useState(0);

  const addNotification = (notification) => {
    const id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    
    // Ensure message is a string
    let message = notification.message || notification;
    if (typeof message !== 'string') {
      message = String(message);
    }
    
    // Ensure title is a string if provided
    let title = notification.title || '';
    if (typeof title !== 'string') {
      title = String(title);
    }
    
    const newNotification = {
      id,
      type: notification.type || 'info',
      title,
      message,
      duration: notification.duration || 5000,
      timestamp: new Date().toISOString(),
      read: false,
      persistent: notification.persistent || false // إذا كان الإشعار دائم أم لا
    };

    // إضافة للإشعارات المؤقتة
    setNotifications(prev => [...prev, newNotification]);
    
    // إضافة للإشعارات الدائمة
    setPersistentNotifications(prev => [newNotification, ...prev]);
    setUnreadCount(prev => prev + 1);

    if (newNotification.duration > 0) {
      setTimeout(() => {
        removeNotification(id);
      }, newNotification.duration);
    }

    return id;
  };

  const removeNotification = (id) => {
    setNotifications(prev => prev.filter(n => n.id !== id));
  };

  const markAsRead = (id) => {
    setPersistentNotifications(prev => 
      prev.map(notification => 
        notification.id === id 
          ? { ...notification, read: true }
          : notification
      )
    );
    setUnreadCount(prev => Math.max(0, prev - 1));
  };

  const markAllAsRead = () => {
    setPersistentNotifications(prev => 
      prev.map(notification => ({ ...notification, read: true }))
    );
    setUnreadCount(0);
  };

  const deletePersistentNotification = (id) => {
    const notification = persistentNotifications.find(n => n.id === id);
    setPersistentNotifications(prev => prev.filter(n => n.id !== id));
    if (!notification?.read) {
      setUnreadCount(prev => Math.max(0, prev - 1));
    }
  };

  const clearAll = () => {
    setNotifications([]);
    setPersistentNotifications([]);
    setUnreadCount(0);
  };

  return (
    <NotificationContext.Provider value={{ 
      addNotification, 
      removeNotification, 
      clearAll,
      notifications,
      persistentNotifications,
      unreadCount,
      markAsRead,
      markAllAsRead,
      deletePersistentNotification
    }}>
      {children}
      <NotificationContainer 
        notifications={notifications} 
        onRemove={removeNotification} 
      />
    </NotificationContext.Provider>
  );
};

const NotificationContainer = ({ notifications, onRemove }) => {
  const getIcon = (type) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="h-5 w-5 text-green-500" />;
      case 'error':
        return <XCircle className="h-5 w-5 text-red-500" />;
      case 'warning':
        return <AlertCircle className="h-5 w-5 text-yellow-500" />;
      case 'info':
      default:
        return <Info className="h-5 w-5 text-blue-500" />;
    }
  };

  const getBackgroundColor = (type) => {
    switch (type) {
      case 'success':
        return 'bg-green-50 border-green-200 dark:bg-green-900/20 dark:border-green-700';
      case 'error':
        return 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-700';
      case 'warning':
        return 'bg-yellow-50 border-yellow-200 dark:bg-yellow-900/20 dark:border-yellow-700';
      case 'info':
      default:
        return 'bg-blue-50 border-blue-200 dark:bg-blue-900/20 dark:border-blue-700';
    }
  };

  if (notifications.length === 0) {
    return null;
  }

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2 max-w-sm w-full">
      {notifications.map((notification) => (
        <div
          key={notification.id}
          className={`rounded-lg border p-4 shadow-lg animate-slide-down ${getBackgroundColor(notification.type)}`}
        >
          <div className="flex items-start space-x-3 rtl:space-x-reverse">
            <div className="flex-shrink-0">
              {getIcon(notification.type)}
            </div>
            
            <div className="flex-1">
              {notification.title && (
                <h4 className="text-sm font-medium text-gray-900 dark:text-white mb-1">
                  {typeof notification.title === 'string' ? notification.title : String(notification.title)}
                </h4>
              )}
              
              <p className="text-sm text-gray-700 dark:text-gray-300">
                {typeof notification.message === 'string' ? notification.message : String(notification.message)}
              </p>
            </div>
            
            <button
              onClick={() => onRemove(notification.id)}
              className="flex-shrink-0 p-1 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <X className="h-4 w-4 text-gray-500 dark:text-gray-400" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
};

// مكون أيقونة الإشعارات مع القائمة المنسدلة
export const NotificationIcon = () => {
  const { t } = useTranslation();
  const { persistentNotifications, unreadCount, markAsRead, markAllAsRead, deletePersistentNotification } = useNotification();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  // إغلاق القائمة عند النقر خارجها
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const formatTime = (timestamp) => {
    const now = new Date();
    const notificationTime = new Date(timestamp);
    const diffInMinutes = Math.floor((now - notificationTime) / (1000 * 60));
    
    if (diffInMinutes < 1) return 'الآن';
    if (diffInMinutes < 60) return `منذ ${diffInMinutes} دقيقة`;
    if (diffInMinutes < 1440) return `منذ ${Math.floor(diffInMinutes / 60)} ساعة`;
    return `منذ ${Math.floor(diffInMinutes / 1440)} يوم`;
  };

  const getIcon = (type) => {
    switch (type) {
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'error':
        return <XCircle className="h-4 w-4 text-red-500" />;
      case 'warning':
        return <AlertCircle className="h-4 w-4 text-yellow-500" />;
      case 'info':
      default:
        return <Info className="h-4 w-4 text-blue-500" />;
    }
  };

  return (
    <div className="relative" ref={dropdownRef}>
      {/* أيقونة الإشعارات */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
      >
        <Bell className="w-5 h-5 text-gray-500 dark:text-gray-400" />
        {unreadCount > 0 && (
          <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {/* القائمة المنسدلة */}
      {isOpen && (
        <div className="absolute top-12 right-0 rtl:right-auto rtl:left-0 w-80 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-50 max-h-96 overflow-hidden">
          {/* هيدر القائمة */}
          <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              الإشعارات
            </h3>
            {persistentNotifications.length > 0 && (
              <button
                onClick={markAllAsRead}
                className="text-sm text-blue-600 dark:text-blue-400 hover:underline"
              >
                تحديد الكل كمقروء
              </button>
            )}
          </div>

          {/* قائمة الإشعارات */}
          <div className="max-h-64 overflow-y-auto">
            {persistentNotifications.length === 0 ? (
              <div className="p-6 text-center">
                <Bell className="h-12 w-12 text-gray-300 dark:text-gray-600 mx-auto mb-2" />
                <p className="text-gray-500 dark:text-gray-400">لا توجد إشعارات</p>
              </div>
            ) : (
              persistentNotifications.map((notification) => (
                <div
                  key={notification.id}
                  className={`p-4 border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors ${
                    !notification.read ? 'bg-blue-50 dark:bg-blue-900/20' : ''
                  }`}
                >
                  <div className="flex items-start space-x-3 rtl:space-x-reverse">
                    <div className="flex-shrink-0 mt-1">
                      {getIcon(notification.type)}
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      {notification.title && (
                        <p className="text-sm font-medium text-gray-900 dark:text-white mb-1 truncate">
                          {typeof notification.title === 'string' ? notification.title : String(notification.title)}
                        </p>
                      )}
                      
                      <p className="text-sm text-gray-600 dark:text-gray-300 mb-1">
                        {typeof notification.message === 'string' ? notification.message : String(notification.message)}
                      </p>
                      
                      <p className="text-xs text-gray-400 dark:text-gray-500">
                        {formatTime(notification.timestamp)}
                      </p>
                    </div>

                    <div className="flex space-x-1 rtl:space-x-reverse">
                      {!notification.read && (
                        <button
                          onClick={() => markAsRead(notification.id)}
                          className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
                          title="تحديد كمقروء"
                        >
                          <Check className="h-4 w-4 text-gray-400" />
                        </button>
                      )}
                      
                      <button
                        onClick={() => deletePersistentNotification(notification.id)}
                        className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
                        title="حذف"
                      >
                        <X className="h-4 w-4 text-gray-400" />
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* فوتر القائمة */}
          {persistentNotifications.length > 0 && (
            <div className="p-3 border-t border-gray-200 dark:border-gray-700">
              <button
                onClick={() => {
                  persistentNotifications.forEach(n => deletePersistentNotification(n.id));
                  setIsOpen(false);
                }}
                className="w-full flex items-center justify-center space-x-2 rtl:space-x-reverse text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg py-2"
              >
                <Trash2 className="h-4 w-4" />
                <span>مسح جميع الإشعارات</span>
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

// Helper function for easy notification usage (legacy support)
export const showNotification = (message, type = 'info', title = '', duration = 5000) => {
  // For backwards compatibility - creates custom event
  const event = new CustomEvent('show-notification', {
    detail: { message, type, title, duration }
  });
  window.dispatchEvent(event);
};

// Main component that handles global notifications (for legacy support)
const NotificationSystem = () => {
  const [notifications, setNotifications] = useState([]);

  useEffect(() => {
    const handleNotification = (event) => {
      const id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
      const newNotification = {
        id,
        type: event.detail.type || 'info',
        title: event.detail.title || '',
        message: event.detail.message || '',
        duration: event.detail.duration || 5000,
        timestamp: new Date().toISOString()
      };

      setNotifications(prev => [...prev, newNotification]);

      if (newNotification.duration > 0) {
        setTimeout(() => {
          setNotifications(prev => prev.filter(n => n.id !== id));
        }, newNotification.duration);
      }
    };

    window.addEventListener('show-notification', handleNotification);
    
    return () => {
      window.removeEventListener('show-notification', handleNotification);
    };
  }, []);

  return (
    <NotificationContainer 
      notifications={notifications} 
      onRemove={(id) => setNotifications(prev => prev.filter(n => n.id !== id))} 
    />
  );
};

export default NotificationSystem;