import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Download, X } from 'lucide-react';

const InstallPrompt = ({ deferredPrompt, setDeferredPrompt }) => {
  const { t } = useTranslation();
  const [showPrompt, setShowPrompt] = useState(!!deferredPrompt);

  const handleInstall = async () => {
    if (!deferredPrompt) return;

    try {
      // Show the install prompt
      deferredPrompt.prompt();
      
      // Wait for the user to respond to the prompt
      const { outcome } = await deferredPrompt.userChoice;
      
      console.log(`User response to the install prompt: ${outcome}`);
      
      // Clear the deferredPrompt so it can be garbage collected
      setDeferredPrompt(null);
      setShowPrompt(false);
    } catch (error) {
      console.error('Error during installation:', error);
    }
  };

  const handleDismiss = () => {
    setShowPrompt(false);
    setDeferredPrompt(null);
  };

  // Don't show if we don't have a deferred prompt or user dismissed
  if (!deferredPrompt || !showPrompt) {
    return null;
  }

  return (
    <div className="fixed bottom-4 left-4 right-4 z-50 md:left-auto md:right-4 md:w-80">
      <div className="bg-white rounded-lg shadow-lg border border-gray-200 p-4">
        <div className="flex items-start space-x-3 rtl:space-x-reverse">
          <div className="flex-shrink-0">
            <Download className="h-6 w-6 text-primary-600" />
          </div>
          
          <div className="flex-1">
            <h3 className="text-sm font-medium text-gray-900 mb-1">
              {t('installApp')}
            </h3>
            <p className="text-xs text-gray-600 mb-3">
              {t('appDescription')}
            </p>
            
            <div className="flex space-x-2 rtl:space-x-reverse">
              <button
                onClick={handleInstall}
                className="btn btn-primary text-xs px-3 py-1"
              >
                {t('installApp')}
              </button>
              <button
                onClick={handleDismiss}
                className="btn btn-ghost text-xs px-3 py-1"
              >
                {t('common.close')}
              </button>
            </div>
          </div>
          
          <button
            onClick={handleDismiss}
            className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-500"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default InstallPrompt;