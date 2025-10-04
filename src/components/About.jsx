import React from 'react';
import { useTranslation } from 'react-i18next';
import { 
  Smartphone, 
  Globe, 
  Shield, 
  Zap,
  Heart,
  Github,
  Mail,
  ExternalLink
} from 'lucide-react';

const About = () => {
  const { t } = useTranslation();

  const features = [
    {
      icon: Smartphone,
      title: t('about.features.pwa.title'),
      description: t('about.features.pwa.description')
    },
    {
      icon: Globe,
      title: t('about.features.multilingual.title'),
      description: t('about.features.multilingual.description')
    },
    {
      icon: Shield,
      title: t('about.features.offline.title'),
      description: t('about.features.offline.description')
    },
    {
      icon: Zap,
      title: t('about.features.sync.title'),
      description: t('about.features.sync.description')
    }
  ];

  const technologies = [
    'React 18',
    'Vite',
    'Tailwind CSS',
    'IndexedDB',
    'Firebase',
    'PWA',
    'Service Workers',
    'i18next'
  ];

  return (
    <div className="page-container">
      {/* Page Header */}
      <div className="page-header text-center">
        <h1 className="page-title">{t('appTitle')}</h1>
        <p className="page-subtitle text-lg">
          {t('appDescription')}
        </p>
        <div className="flex items-center justify-center space-x-2 rtl:space-x-reverse mt-4">
          <span className="px-3 py-1 bg-primary-100 text-primary-800 rounded-full text-sm font-medium">
            {t('about.version')} 1.1.0
          </span>
          <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-sm font-medium">
            {t('about.status.stable')}
          </span>
        </div>
      </div>

      {/* Features */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {t('about.features.title')}
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {features.map((feature, index) => {
            const Icon = feature.icon;
            return (
              <div key={index} className="card">
                <div className="card-content">
                  <div className="flex items-start">
                    <div className="flex-shrink-0">
                      <Icon className="h-8 w-8 text-primary-600" />
                    </div>
                    <div className="ltr:ml-4 rtl:mr-4">
                      <h3 className="text-lg font-medium text-gray-900 mb-2">
                        {feature.title}
                      </h3>
                      <p className="text-gray-600">
                        {feature.description}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Technology Stack */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {t('about.technologies.title')}
        </h2>
        <div className="card">
          <div className="card-content">
            <div className="flex flex-wrap gap-2 justify-center">
              {technologies.map((tech, index) => (
                <span
                  key={index}
                  className="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm font-medium"
                >
                  {tech}
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Developer Info */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {t('about.developer.title')}
        </h2>
        <div className="card">
          <div className="card-content text-center">
            <div className="flex items-center justify-center mb-4">
              <Heart className="h-6 w-6 text-red-500" />
            </div>
            <p className="text-gray-600 mb-4">
              {t('about.developer.description')}
            </p>
            <div className="flex justify-center space-x-4 rtl:space-x-reverse">
              <a
                href="https://github.com"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center text-primary-600 hover:text-primary-700"
              >
                <Github className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
                GitHub
                <ExternalLink className="h-4 w-4 ltr:ml-1 rtl:mr-1" />
              </a>
              <a
                href="mailto:support@example.com"
                className="inline-flex items-center text-primary-600 hover:text-primary-700"
              >
                <Mail className="h-5 w-5 ltr:mr-2 rtl:ml-2" />
                {t('about.contact.email')}
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* System Information */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {t('about.system.title')}
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">
                {t('about.system.browser')}
              </h3>
            </div>
            <div className="card-content space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">{t('about.system.userAgent')}:</span>
                <span className="text-sm text-gray-900 truncate ltr:ml-2 rtl:mr-2">
                  {navigator.userAgent.split(' ')[0]}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">{t('about.system.language')}:</span>
                <span className="text-sm text-gray-900">
                  {navigator.language}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">{t('about.system.online')}:</span>
                <span className={`text-sm font-medium ${
                  navigator.onLine ? 'text-green-600' : 'text-red-600'
                }`}>
                  {navigator.onLine ? t('common.online') : t('common.offline')}
                </span>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">
                {t('about.system.support')}
              </h3>
            </div>
            <div className="card-content space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600">Service Worker:</span>
                <span className={`text-sm font-medium ${
                  'serviceWorker' in navigator ? 'text-green-600' : 'text-red-600'
                }`}>
                  {'serviceWorker' in navigator ? t('about.system.supported') : t('about.system.notSupported')}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">IndexedDB:</span>
                <span className={`text-sm font-medium ${
                  'indexedDB' in window ? 'text-green-600' : 'text-red-600'
                }`}>
                  {'indexedDB' in window ? t('about.system.supported') : t('about.system.notSupported')}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">PWA Install:</span>
                <span className={`text-sm font-medium ${
                  window.matchMedia('(display-mode: standalone)').matches ? 'text-green-600' : 'text-orange-600'
                }`}>
                  {window.matchMedia('(display-mode: standalone)').matches ? 
                    t('about.system.installed') : 
                    t('about.system.browser')
                  }
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* License & Credits */}
      <div className="mb-12">
        <h2 className="text-2xl font-bold text-gray-900 mb-6 text-center">
          {t('about.license.title')}
        </h2>
        <div className="card">
          <div className="card-content text-center">
            <p className="text-gray-600 mb-4">
              {t('about.license.description')}
            </p>
            <div className="text-sm text-gray-500">
              <p>{t('about.license.copyright')}</p>
              <p className="mt-2">
                {t('about.license.openSource')}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="text-center text-sm text-gray-500 border-t border-gray-200 pt-6">
        <p>
          {t('about.footer.madeWith')} <Heart className="inline h-4 w-4 text-red-500" /> {t('about.footer.for')} {t('about.footer.community')}
        </p>
        <p className="mt-2">
          © 2024 {t('appTitle')} - {t('about.footer.allRights')}
        </p>
      </div>
    </div>
  );
};

export default About;