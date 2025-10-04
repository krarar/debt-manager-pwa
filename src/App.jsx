import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

// Components
import Layout from './components/Layout';
import Dashboard from './components/Dashboard';
import DebtorsList from './components/DebtorsList';
import DebtorDetails from './components/DebtorDetails';
import Reports from './components/Reports';
import Settings from './components/Settings';
import About from './components/About';
import OfflineIndicator from './components/OfflineIndicator';
import InstallPrompt from './components/InstallPrompt';
import NotificationSystem from './components/NotificationSystem';

// Database and services
import db from './lib/database';
import firebaseSync from './lib/firebase';

// PWA Service Worker registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/debt-manager-pwa/sw.js')
      .then((registration) => {
        console.log('SW registered: ', registration);
      })
      .catch((registrationError) => {
        console.log('SW registration failed: ', registrationError);
      });
  });
}

function App() {
  const { i18n } = useTranslation();
  const [isLoading, setIsLoading] = useState(true);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [deferredPrompt, setDeferredPrompt] = useState(null);

  // Initialize app
  useEffect(() => {
    const initializeApp = async () => {
      try {
        // Initialize database
        await db.init();
        
        // Initialize Firebase sync
        await firebaseSync.init();
        
        // Load initial settings
        await loadInitialSettings();
        
        // Seed sample data if this is the first run
        await seedSampleDataIfNeeded();
        
        setIsLoading(false);
      } catch (error) {
        console.error('Failed to initialize app:', error);
        setIsLoading(false);
      }
    };

    initializeApp();
  }, []);

  // Load initial settings
  const loadInitialSettings = async () => {
    try {
      const settings = await db.getAllSettings();
      
      // Set default settings if not exists
      const defaults = {
        language: 'ar',
        direction: 'auto',
        currency: 'IQD',
        dateFormat: 'dd/MM/yyyy',
        syncEnabled: false,
        syncOnStartup: false,
        theme: 'light'
      };

      for (const [key, value] of Object.entries(defaults)) {
        if (!(key in settings)) {
          await db.setSetting(key, value);
        }
      }

      // Apply language setting
      const savedLanguage = settings.language || defaults.language;
      if (i18n.language !== savedLanguage) {
        i18n.changeLanguage(savedLanguage);
      }
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  };

  // Seed sample data for first-time users
  const seedSampleDataIfNeeded = async () => {
    try {
      const debtors = await db.getAllDebtors();
      if (debtors.length === 0) {
        // Add sample debtors
        const sampleDebtors = [
          {
            name: 'أحمد محمد علي',
            phone: '07901234567',
            address: 'بغداد، الكرادة',
            notes: 'زبون منتظم ومؤتمن'
          },
          {
            name: 'فاطمة حسن',
            phone: '07807654321',
            address: 'البصرة، العشار',
            notes: 'تاجرة مواد غذائية'
          },
          {
            name: 'محمد صالح',
            phone: '07701122334',
            address: 'أربيل، المركز',
            notes: 'صاحب محل ملابس'
          }
        ];

        for (const debtorData of sampleDebtors) {
          const debtor = await db.addDebtor(debtorData);
          
          // Add sample transactions
          await db.addTransaction({
            debtorId: debtor.id,
            type: 'debt',
            amount: Math.floor(Math.random() * 500000) + 100000,
            currency: 'IQD',
            product: 'بضائع متنوعة',
            notes: 'دفعة أولى',
            paymentMethod: 'cash'
          });

          if (Math.random() > 0.5) {
            await db.addTransaction({
              debtorId: debtor.id,
              type: 'payment',
              amount: Math.floor(Math.random() * 200000) + 50000,
              currency: 'IQD',
              notes: 'دفعة جزئية',
              paymentMethod: 'cash'
            });
          }
        }
      }
    } catch (error) {
      console.error('Failed to seed sample data:', error);
    }
  };

  // Handle online/offline status
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Handle PWA install prompt
  useEffect(() => {
    const handleBeforeInstallPrompt = (e) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="loading-spinner mb-4"></div>
          <p className="text-gray-600">جارِ تحميل التطبيق...</p>
        </div>
      </div>
    );
  }

  return (
    <Router basename="/debt-manager-pwa">
      <div className="min-h-screen bg-gray-50">
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/debtors" element={<DebtorsList />} />
            <Route path="/debtor/:id" element={<DebtorDetails />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/about" element={<About />} />
          </Routes>
        </Layout>

        {/* Global Components */}
        <OfflineIndicator isOnline={isOnline} />
        <InstallPrompt deferredPrompt={deferredPrompt} setDeferredPrompt={setDeferredPrompt} />
        <NotificationSystem />
      </div>
    </Router>
  );
}

export default App;