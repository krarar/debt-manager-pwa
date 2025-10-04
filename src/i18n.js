import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import ar from './locales/ar.json';
import en from './locales/en.json';
import ku from './locales/ku.json';
import tr from './locales/tr.json';
import fa from './locales/fa.json';

// Language configuration
export const languages = {
  ar: { 
    name: 'العربية', 
    dir: 'rtl', 
    locale: 'ar-IQ',
    font: 'arabic'
  },
  en: { 
    name: 'English', 
    dir: 'ltr', 
    locale: 'en-US',
    font: 'english'
  },
  ku: { 
    name: 'کوردی', 
    dir: 'rtl', 
    locale: 'ku-Arab',
    font: 'kurdish'
  },
  tr: { 
    name: 'Türkçe', 
    dir: 'ltr', 
    locale: 'tr-TR',
    font: 'turkish'
  },
  fa: { 
    name: 'فارسی', 
    dir: 'rtl', 
    locale: 'fa-IR',
    font: 'persian'
  }
};

// Get user's preferred language from storage or browser
const getStoredLanguage = () => {
  try {
    return localStorage.getItem('debt-manager-language');
  } catch {
    return null;
  }
};

const getBrowserLanguage = () => {
  const browserLang = navigator.language || navigator.languages?.[0] || 'en';
  const langCode = browserLang.split('-')[0];
  return Object.keys(languages).includes(langCode) ? langCode : 'ar';
};

const defaultLanguage = getStoredLanguage() || getBrowserLanguage();

// Configure i18n
i18n
  .use(initReactI18next)
  .init({
    resources: {
      ar: { translation: ar },
      en: { translation: en },
      ku: { translation: ku },
      tr: { translation: tr },
      fa: { translation: fa }
    },
    lng: defaultLanguage,
    fallbackLng: 'ar',
    interpolation: {
      escapeValue: false,
    },
    react: {
      useSuspense: false,
    }
  });

// Update HTML direction and language attributes
export const updateHtmlDirection = (language) => {
  const html = document.documentElement;
  const config = languages[language];
  
  if (config) {
    html.setAttribute('dir', config.dir);
    html.setAttribute('lang', language);
    html.className = `font-${config.font}`;
    
    // Store the selected language
    try {
      localStorage.setItem('debt-manager-language', language);
    } catch (error) {
      console.warn('Failed to store language preference:', error);
    }
  }
};

// Initialize direction on first load
updateHtmlDirection(defaultLanguage);

// Format number according to locale
export const formatNumber = (number, language = i18n.language, options = {}) => {
  const config = languages[language];
  if (!config) return number.toString();
  
  try {
    return new Intl.NumberFormat(config.locale, {
      maximumFractionDigits: 2,
      ...options
    }).format(number);
  } catch {
    return number.toString();
  }
};

// Format currency according to locale
export const formatCurrency = (amount, currency = 'IQD', language = i18n.language) => {
  const config = languages[language];
  if (!config) return `${amount} ${currency}`;
  
  try {
    return new Intl.NumberFormat(config.locale, {
      style: 'currency',
      currency: currency,
      currencyDisplay: 'code'
    }).format(amount);
  } catch {
    return `${formatNumber(amount, language)} ${currency}`;
  }
};

// Format date according to locale
export const formatDate = (date, language = i18n.language, options = {}) => {
  const config = languages[language];
  if (!config) return date.toLocaleDateString();
  
  try {
    return new Intl.DateTimeFormat(config.locale, {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      ...options
    }).format(new Date(date));
  } catch {
    return new Date(date).toLocaleDateString();
  }
};

// Format relative time (e.g., "2 days ago")
export const formatRelativeTime = (date, language = i18n.language) => {
  const config = languages[language];
  if (!config) return date.toLocaleDateString();
  
  try {
    const rtf = new Intl.RelativeTimeFormat(config.locale, { numeric: 'auto' });
    const now = new Date();
    const diffTime = new Date(date) - now;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (Math.abs(diffDays) < 1) {
      const diffHours = Math.ceil(diffTime / (1000 * 60 * 60));
      return rtf.format(diffHours, 'hour');
    } else if (Math.abs(diffDays) < 7) {
      return rtf.format(diffDays, 'day');
    } else if (Math.abs(diffDays) < 30) {
      const diffWeeks = Math.ceil(diffDays / 7);
      return rtf.format(diffWeeks, 'week');
    } else {
      const diffMonths = Math.ceil(diffDays / 30);
      return rtf.format(diffMonths, 'month');
    }
  } catch {
    return formatDate(date, language);
  }
};

// Change language and update direction
export const changeLanguage = (language) => {
  if (languages[language]) {
    i18n.changeLanguage(language);
    updateHtmlDirection(language);
    
    // Dispatch custom event for components to react to language change
    window.dispatchEvent(new CustomEvent('languageChanged', { 
      detail: { language, config: languages[language] } 
    }));
  }
};

// Get current language configuration
export const getCurrentLanguageConfig = () => {
  return languages[i18n.language] || languages.ar;
};

export default i18n;