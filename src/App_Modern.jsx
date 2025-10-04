import React, { useEffect, Suspense } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { I18nextProvider } from 'react-i18next';
import { ThemeProvider } from './contexts/ThemeContext';
import i18n from './i18n';
import ModernLayout from './components/ModernLayout';
import Dashboard from './components/Dashboard';
import DebtorsList from './components/DebtorsList';
import DebtorDetails from './components/DebtorDetails';
import Reports from './components/Reports';
import Settings from './components/Settings';
import About from './components/About';
import NotificationSystem from './components/NotificationSystem';
import InstallPrompt from './components/InstallPrompt';
import { updateSW } from './registerSW';
import './index.css';

// Loading component
const LoadingSpinner = () => (
  <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
    <div className="flex flex-col items-center space-y-4">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      <p className="text-gray-600 dark:text-gray-400 animate-pulse">جاري التحميل...</p>
    </div>
  </div>
);

function App() {
  useEffect(() => {
    // Register service worker update handler
    console.log('SW registered: ', updateSW);

    // Listen for sync events
    const handleManualSync = () => {
      console.log('Manual sync triggered');
      // Add your sync logic here
      window.dispatchEvent(new CustomEvent('syncStarted'));
    };

    window.addEventListener('manualSync', handleManualSync);

    // PWA install prompt handling
    let deferredPrompt;
    const handleBeforeInstallPrompt = (e) => {
      e.preventDefault();
      deferredPrompt = e;
      window.dispatchEvent(new CustomEvent('pwaInstallAvailable', { detail: deferredPrompt }));
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    return () => {
      window.removeEventListener('manualSync', handleManualSync);
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  return (
    <ThemeProvider>
      <I18nextProvider i18n={i18n}>
        <Router basename="/debt-manager-pwa">
          <Suspense fallback={<LoadingSpinner />}>
            <div className="App">
              <Routes>
                <Route path="/" element={<ModernLayout />}>
                  <Route index element={<Dashboard />} />
                  <Route path="debtors" element={<DebtorsList />} />
                  <Route path="debtors/:id" element={<DebtorDetails />} />
                  <Route path="reports" element={<Reports />} />
                  <Route path="settings" element={<Settings />} />
                  <Route path="about" element={<About />} />
                </Route>
              </Routes>
              
              {/* Global Components */}
              <NotificationSystem />
              <InstallPrompt />
            </div>
          </Suspense>
        </Router>
      </I18nextProvider>
    </ThemeProvider>
  );
}

export default App;