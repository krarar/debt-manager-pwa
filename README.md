# Qisti | قِسطي

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

## Web و PWA

يتم بناء نسخة الويب تلقائيا عند كل push إلى فرع `main` عبر GitHub Actions.

الرابط بعد تفعيل GitHub Pages:

`https://krarar.github.io/debt-manager-pwa/`

يمكن تثبيت التطبيق من المتصفح على Android، وعلى iPhone عبر Safari ثم «إضافة
إلى الشاشة الرئيسية».

## البناء محليا

```bash
flutter pub get
flutter run -d chrome
flutter build web --release --base-href /debt-manager-pwa/
flutter build apk --release
```

بناء iOS يحتاج macOS وXcode:

```bash
flutter build ipa --release
```
