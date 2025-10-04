import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

const OfflineIndicator = ({ isOnline }) => {
  const { t } = useTranslation();
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (!isOnline) {
      setShow(true);
    } else {
      // Hide after a short delay when coming back online
      const timer = setTimeout(() => setShow(false), 3000);
      return () => clearTimeout(timer);
    }
  }, [isOnline]);

  if (!show) return null;

  return (
    <div className={`offline-indicator ${!isOnline ? '' : 'hidden'}`}>
      <div className="flex items-center justify-center">
        <div className="flex items-center space-x-2 rtl:space-x-reverse">
          <div className="h-2 w-2 bg-white rounded-full animate-pulse"></div>
          <span className="text-sm font-medium">
            {isOnline ? t('common.online') : t('common.offline')}
          </span>
        </div>
      </div>
    </div>
  );
};

export default OfflineIndicator;