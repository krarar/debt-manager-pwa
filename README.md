# مدير الديون - Debt Manager PWA

تطبيق ويب متقدم (PWA) لإدارة الديون مع دعم متعدد اللغات والعمل الأوفلاين والمزامنة مع Firebase.

## المميزات الأساسية

### 🌐 متعدد اللغات
- العربية (الافتراضية)
- الإنجليزية  
- الكردية (سوراني)
- التركية
- الفارسية
- دعم كامل لـ RTL/LTR
- تنسيق الأرقام والتواريخ والعملات حسب اللغة

### 📱 تطبيق ويب تقدمي (PWA)
- قابل للتثبيت على جميع الأجهزة
- يعمل أوفلاين بالكامل
- Service Worker للتخزين المؤقت
- إشعارات الدفع (مستقبلاً)
- تحديثات تلقائية

### 💾 إدارة البيانات
- قاعدة بيانات محلية (IndexedDB)
- مزامنة اختيارية مع Firebase
- تصدير/استيراد البيانات (JSON/CSV)
- نسخ احتياطية
- إعادة ضبط المصنع

### 🧾 إدارة الديون
- إضافة/تعديل/حذف المدينين
- تسجيل الديون والسدادات
- حساب الأرصدة التلقائي
- تتبع تاريخ المعاملات
- البحث والفلترة

### 📊 التقارير والطباعة
- تقارير مالية شاملة
- تصدير التقارير (CSV/JSON)
- طباعة كشوف الحساب
- طباعة الإيصالات
- دعم الطباعة الحرارية (80mm)

## التقنيات المستخدمة

- **React 18** - مكتبة واجهة المستخدم
- **Vite** - أداة البناء السريعة
- **Tailwind CSS** - إطار تصميم CSS
- **IndexedDB** - قاعدة بيانات محلية
- **Firebase Realtime Database** - المزامنة السحابية
- **i18next** - نظام الترجمة
- **Workbox** - Service Worker
- **React Router** - التنقل

## البدء

### المتطلبات
- Node.js 18+ 
- npm أو yarn

### التثبيت

```bash
# نسخ المستودع
git clone https://github.com/username/debt-manager-pwa.git
cd debt-manager-pwa

# تثبيت التبعيات
npm install

# تشغيل خادم التطوير
npm run dev
```

### البناء للإنتاج

```bash
# بناء التطبيق
npm run build

# معاينة البناء
npm run preview
```

### النشر على GitHub Pages

```bash
# بناء ونشر
npm run deploy
```

## الإعداد

### إعداد Firebase

1. إنشاء مشروع Firebase جديد
2. تفعيل Realtime Database
3. تحديث إعدادات Firebase في `src/lib/firebase.js`:

```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  databaseURL: "https://your-project-default-rtdb.firebaseio.com",
  projectId: "your-project-id",
  storageBucket: "your-project.firebasestorage.app",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

### قواعد الأمان Firebase

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

## هيكل المشروع

```
debt-manager-pwa/
├── public/
│   ├── manifest.webmanifest
│   ├── sw.js
│   ├── offline.html
│   └── icons/
├── src/
│   ├── components/          # مكونات React
│   ├── lib/                # المكتبات والخدمات
│   │   ├── database.js     # إدارة IndexedDB
│   │   ├── firebase.js     # خدمات Firebase
│   │   ├── exportImport.js # التصدير والاستيراد
│   │   └── printManager.js # إدارة الطباعة
│   ├── locales/            # ملفات الترجمة
│   │   ├── ar.json
│   │   ├── en.json
│   │   ├── ku.json
│   │   ├── tr.json
│   │   └── fa.json
│   ├── i18n.js            # إعداد الترجمة
│   ├── App.jsx            # المكون الرئيسي
│   └── main.jsx           # نقطة الدخول
├── tailwind.config.js     # إعداد Tailwind
├── vite.config.js         # إعداد Vite
└── package.json
```

## الصفحات

### 🏠 لوحة التحكم
- إحصائيات سريعة
- النشاط الأخير
- الديون المتأخرة
- البحث السريع

### 👥 المدينون
- قائمة المدينين
- إضافة/تعديل/حذف
- البحث والفلترة
- أرصدة المدينين

### 📋 تفاصيل المدين
- المعلومات الشخصية
- سجل المعاملات
- إضافة ديون/سدادات
- طباعة كشف الحساب

### 📊 التقارير
- تقارير حسب التاريخ
- إحصائيات شاملة
- تصدير التقارير
- طباعة

### ⚙️ الإعدادات
- اللغة والاتجاه
- العملة وتنسيق التاريخ
- إعدادات المزامنة
- النسخ الاحتياطي
- إعدادات الطباعة

## التخصيص

### إضافة لغة جديدة

1. إنشاء ملف ترجمة جديد في `src/locales/`
2. تحديث `src/i18n.js`:

```javascript
import newLang from './locales/newlang.json';

export const languages = {
  // ...existing languages
  newlang: { 
    name: 'اللغة الجديدة', 
    dir: 'rtl', 
    locale: 'newlang-COUNTRY',
    font: 'arabic'
  }
};
```

### تخصيص الألوان

تحديث `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        // ألوان مخصصة
      }
    }
  }
}
```

## الاستخدام

### إضافة مدين جديد
1. انتقل إلى صفحة "المدينون"
2. اضغط "إضافة مدين"
3. املأ البيانات المطلوبة
4. احفظ

### تسجيل دين أو سداد
1. افتح تفاصيل المدين
2. اضغط "إضافة دين"
3. اختر النوع (دين/سداد)
4. أدخل المبلغ والتفاصيل
5. احفظ

### طباعة كشف حساب
1. افتح تفاصيل المدين
2. اضغط "طباعة إيصال"
3. اختر نوع الطباعة (A4/حراري)
4. طباعة

### تصدير البيانات
1. انتقل إلى الإعدادات
2. قسم "النسخ الاحتياطي"
3. اضغط "تصدير البيانات"
4. اختر التنسيق (JSON/CSV)

## استكشاف الأخطاء

### التطبيق لا يعمل أوفلاين
- تأكد من تسجيل Service Worker
- امسح بيانات المتصفح وأعد التحميل
- تحقق من وحدة تحكم المطور

### مشاكل المزامنة
- تحقق من إعدادات Firebase
- تأكد من الاتصال بالإنترنت
- راجع وحدة تحكم المطور للأخطاء

### مشاكل الطباعة
- تحقق من إعدادات الطابعة
- جرب طباعة صفحة اختبار
- تأكد من دعم المتصفح للطباعة

## المساهمة

نرحب بالمساهمات! يرجى:

1. عمل Fork للمستودع
2. إنشاء فرع للميزة الجديدة
3. تطبيق التغييرات
4. إرسال Pull Request

## الترخيص

هذا المشروع مرخص تحت رخصة MIT - راجع ملف [LICENSE](LICENSE) للتفاصيل.

## الدعم

- 📧 البريد الإلكتروني: support@example.com
- 🐛 الإبلاغ عن الأخطاء: [GitHub Issues](https://github.com/username/debt-manager-pwa/issues)
- 📖 الوثائق: [Wiki](https://github.com/username/debt-manager-pwa/wiki)

## الشكر والتقدير

- [React](https://reactjs.org/)
- [Vite](https://vitejs.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Firebase](https://firebase.google.com/)
- [Lucide Icons](https://lucide.dev/)

---

**مُطوّر بـ ❤️ من أجل المجتمع العربي**