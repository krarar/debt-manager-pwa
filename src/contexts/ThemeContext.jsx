import React, { createContext, useContext, useEffect, useState } from 'react';

const ThemeContext = createContext();

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState(() => {
    // Check localStorage first, then system preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      return savedTheme;
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  });

  const [accentColor, setAccentColor] = useState(() => {
    return localStorage.getItem('accentColor') || 'blue';
  });

  useEffect(() => {
    const root = window.document.documentElement;
    
    // Remove previous theme classes
    root.classList.remove('light', 'dark');
    
    // Add current theme class
    root.classList.add(theme);
    
    // Save to localStorage
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    localStorage.setItem('accentColor', accentColor);
    
    // Apply accent color CSS variables
    const root = window.document.documentElement;
    const colors = {
      blue: { primary: '#3b82f6', secondary: '#1d4ed8' },
      green: { primary: '#22c55e', secondary: '#15803d' },
      purple: { primary: '#a855f7', secondary: '#7c3aed' },
      pink: { primary: '#ec4899', secondary: '#be185d' },
      orange: { primary: '#f59e0b', secondary: '#d97706' },
      red: { primary: '#ef4444', secondary: '#dc2626' },
      teal: { primary: '#14b8a6', secondary: '#0f766e' },
      indigo: { primary: '#6366f1', secondary: '#4f46e5' },
    };
    
    if (colors[accentColor]) {
      root.style.setProperty('--color-accent-primary', colors[accentColor].primary);
      root.style.setProperty('--color-accent-secondary', colors[accentColor].secondary);
    }
  }, [accentColor]);

  const toggleTheme = () => {
    setTheme(prevTheme => prevTheme === 'light' ? 'dark' : 'light');
  };

  const setLightTheme = () => setTheme('light');
  const setDarkTheme = () => setTheme('dark');
  const setSystemTheme = () => {
    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    setTheme(systemTheme);
  };

  const value = {
    theme,
    accentColor,
    setTheme,
    setAccentColor,
    toggleTheme,
    setLightTheme,
    setDarkTheme,
    setSystemTheme,
    isDark: theme === 'dark',
    isLight: theme === 'light',
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

export default ThemeContext;