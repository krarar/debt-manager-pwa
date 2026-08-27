import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ku.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ku'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'قِسطي'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ar, this message translates to:
  /// **'إدارة أقساطك أصبحت أسهل'**
  String get appTagline;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نظرة شاملة على نشاطك المالي اليوم'**
  String get dashboardSubtitle;

  /// No description provided for @installments.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط'**
  String get installments;

  /// No description provided for @customers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get customers;

  /// No description provided for @products.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get products;

  /// No description provided for @payments.
  ///
  /// In ar, this message translates to:
  /// **'المدفوعات'**
  String get payments;

  /// No description provided for @receipts.
  ///
  /// In ar, this message translates to:
  /// **'الإيصالات'**
  String get receipts;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get search;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @backup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backup;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @totalOwed.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي ما عليّ'**
  String get totalOwed;

  /// No description provided for @totalDueToMe.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي ما لي'**
  String get totalDueToMe;

  /// No description provided for @dueToday.
  ///
  /// In ar, this message translates to:
  /// **'المستحق اليوم'**
  String get dueToday;

  /// No description provided for @overdue.
  ///
  /// In ar, this message translates to:
  /// **'المتأخر'**
  String get overdue;

  /// No description provided for @upcomingInstallments.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط القادمة'**
  String get upcomingInstallments;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في قِسطي'**
  String get welcome;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @system.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get system;

  /// No description provided for @light.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get dark;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kurdish.
  ///
  /// In ar, this message translates to:
  /// **'کوردی'**
  String get kurdish;

  /// No description provided for @placeholderDescription.
  ///
  /// In ar, this message translates to:
  /// **'ستتوفر هذه الميزة قريباً.'**
  String get placeholderDescription;

  /// No description provided for @sampleCustomerOne.
  ///
  /// In ar, this message translates to:
  /// **'أحمد محمد'**
  String get sampleCustomerOne;

  /// No description provided for @sampleCustomerTwo.
  ///
  /// In ar, this message translates to:
  /// **'سارة علي'**
  String get sampleCustomerTwo;

  /// No description provided for @sampleCustomerThree.
  ///
  /// In ar, this message translates to:
  /// **'محمد حسن'**
  String get sampleCustomerThree;

  /// No description provided for @sampleAmountOne.
  ///
  /// In ar, this message translates to:
  /// **'١٢٥٬٠٠٠ د.ع'**
  String get sampleAmountOne;

  /// No description provided for @sampleAmountTwo.
  ///
  /// In ar, this message translates to:
  /// **'٨٥٬٠٠٠ د.ع'**
  String get sampleAmountTwo;

  /// No description provided for @sampleAmountThree.
  ///
  /// In ar, this message translates to:
  /// **'٢١٠٬٠٠٠ د.ع'**
  String get sampleAmountThree;

  /// No description provided for @sampleDateOne.
  ///
  /// In ar, this message translates to:
  /// **'٢ سبتمبر ٢٠٢٦'**
  String get sampleDateOne;

  /// No description provided for @sampleDateTwo.
  ///
  /// In ar, this message translates to:
  /// **'٥ سبتمبر ٢٠٢٦'**
  String get sampleDateTwo;

  /// No description provided for @sampleDateThree.
  ///
  /// In ar, this message translates to:
  /// **'٧ سبتمبر ٢٠٢٦'**
  String get sampleDateThree;

  /// No description provided for @addCustomer.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عميل'**
  String get addCustomer;

  /// No description provided for @customerName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العميل'**
  String get customerName;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @notes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @noCustomers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء'**
  String get noCustomers;

  /// No description provided for @addPlan.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خطة أقساط'**
  String get addPlan;

  /// No description provided for @planTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخطة'**
  String get planTitle;

  /// No description provided for @totalAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي (د.ع)'**
  String get totalAmount;

  /// No description provided for @downPayment.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة المقدمة (د.ع)'**
  String get downPayment;

  /// No description provided for @installmentCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأقساط'**
  String get installmentCount;

  /// No description provided for @period.
  ///
  /// In ar, this message translates to:
  /// **'دورية القسط'**
  String get period;

  /// No description provided for @weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعي'**
  String get weekly;

  /// No description provided for @biweekly.
  ///
  /// In ar, this message translates to:
  /// **'كل أسبوعين'**
  String get biweekly;

  /// No description provided for @monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthly;

  /// No description provided for @remaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get remaining;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get pending;

  /// No description provided for @partiallyPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع جزئياً'**
  String get partiallyPaid;

  /// No description provided for @recordPayment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دفعة'**
  String get recordPayment;

  /// No description provided for @paymentAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الدفعة (د.ع)'**
  String get paymentAmount;

  /// No description provided for @paymentSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الدفعة'**
  String get paymentSaved;

  /// No description provided for @paymentTooHigh.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة تتجاوز الرصيد المتبقي'**
  String get paymentTooHigh;

  /// No description provided for @noPlans.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خطط أقساط'**
  String get noPlans;

  /// No description provided for @dueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get dueDate;

  /// No description provided for @customerDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العميل'**
  String get customerDetails;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'د.ع'**
  String get currency;

  /// No description provided for @invalidPlan.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنواناً ومبلغاً ودفعة مقدمة وعدد أقساط صالحاً.'**
  String get invalidPlan;

  /// No description provided for @invalidPayment.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغ دفعة موجباً وصالحاً.'**
  String get invalidPayment;

  /// No description provided for @payment.
  ///
  /// In ar, this message translates to:
  /// **'دفعة'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In ar, this message translates to:
  /// **'نقداً'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة'**
  String get card;

  /// No description provided for @bankTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل مصرفي'**
  String get bankTransfer;

  /// No description provided for @other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get other;

  /// No description provided for @allMethods.
  ///
  /// In ar, this message translates to:
  /// **'كل الطرق'**
  String get allMethods;

  /// No description provided for @searchPayments.
  ///
  /// In ar, this message translates to:
  /// **'البحث في المدفوعات'**
  String get searchPayments;

  /// No description provided for @noPayments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدفوعات'**
  String get noPayments;

  /// No description provided for @noReceipts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إيصالات'**
  String get noReceipts;

  /// No description provided for @receiptDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإيصال'**
  String get receiptDetails;

  /// No description provided for @receiptNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الإيصال غير موجود'**
  String get receiptNotFound;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @totalCollected.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المحصل'**
  String get totalCollected;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @installmentPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة التقسيط'**
  String get installmentPlan;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن العملاء أو الخطط أو المدفوعات أو الإيصالات'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'اكتب للبحث في كل شيء'**
  String get searchPrompt;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noSearchResults;

  /// No description provided for @noNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @markRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد كمقروء'**
  String get markRead;

  /// No description provided for @dueInstallmentNotification.
  ///
  /// In ar, this message translates to:
  /// **'يوجد قسط مستحق اليوم'**
  String get dueInstallmentNotification;

  /// No description provided for @overdueInstallmentNotification.
  ///
  /// In ar, this message translates to:
  /// **'يوجد قسط متأخر'**
  String get overdueInstallmentNotification;

  /// No description provided for @paymentRecordedNotification.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدفعة'**
  String get paymentRecordedNotification;

  /// No description provided for @printReceipt.
  ///
  /// In ar, this message translates to:
  /// **'طباعة الإيصال'**
  String get printReceipt;

  /// No description provided for @installment.
  ///
  /// In ar, this message translates to:
  /// **'القسط'**
  String get installment;

  /// No description provided for @savePdf.
  ///
  /// In ar, this message translates to:
  /// **'حفظ PDF'**
  String get savePdf;

  /// No description provided for @shareReceipt.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الإيصال'**
  String get shareReceipt;

  /// No description provided for @pdfSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ PDF'**
  String get pdfSaved;

  /// No description provided for @pdfSaveFallback.
  ///
  /// In ar, this message translates to:
  /// **'استخدم تنزيل/مشاركة المتصفح لحفظ PDF'**
  String get pdfSaveFallback;

  /// No description provided for @pdfShareUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المشاركة غير متاحة على هذا الجهاز'**
  String get pdfShareUnavailable;

  /// No description provided for @pdfActionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء PDF'**
  String get pdfActionFailed;

  /// No description provided for @addDebt.
  ///
  /// In ar, this message translates to:
  /// **'إضافة دين/أقساط'**
  String get addDebt;

  /// No description provided for @productName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get productName;

  /// No description provided for @firstDueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ استحقاق القسط الأول'**
  String get firstDueDate;

  /// No description provided for @editCustomer.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العميل'**
  String get editCustomer;

  /// No description provided for @deleteCustomer.
  ///
  /// In ar, this message translates to:
  /// **'حذف العميل'**
  String get deleteCustomer;

  /// No description provided for @deletePlan.
  ///
  /// In ar, this message translates to:
  /// **'حذف الخطة'**
  String get deletePlan;

  /// No description provided for @editPlan.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخطة'**
  String get editPlan;

  /// No description provided for @deleteConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا العنصر؟'**
  String get deleteConfirmation;

  /// No description provided for @cannotDeleteCustomer.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف عميل لديه خطط أقساط.'**
  String get cannotDeleteCustomer;

  /// No description provided for @customerDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العميل'**
  String get customerDeleted;

  /// No description provided for @planDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الخطة'**
  String get planDeleted;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @chooseDebtType.
  ///
  /// In ar, this message translates to:
  /// **'كيف تريد إضافة الدين؟'**
  String get chooseDebtType;

  /// No description provided for @addDebtSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ خطة أقساط جديدة لأحد العملاء'**
  String get addDebtSubtitle;

  /// No description provided for @newDebt.
  ///
  /// In ar, this message translates to:
  /// **'دين جديد'**
  String get newDebt;

  /// No description provided for @newDebtDescription.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ عميلاً وأضف خطة أقساطه الأولى'**
  String get newDebtDescription;

  /// No description provided for @existingCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل حالي'**
  String get existingCustomer;

  /// No description provided for @existingCustomerDescription.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلاً من قائمة عملائك'**
  String get existingCustomerDescription;

  /// No description provided for @selectExistingCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اختر عميلاً حاليًا'**
  String get selectExistingCustomer;

  /// No description provided for @searchCustomers.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن العملاء'**
  String get searchCustomers;

  /// No description provided for @noMatchingCustomers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء مطابقون'**
  String get noMatchingCustomers;

  /// No description provided for @customerSchedule.
  ///
  /// In ar, this message translates to:
  /// **'جدول الأقساط'**
  String get customerSchedule;

  /// No description provided for @totalDebt.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الدين'**
  String get totalDebt;

  /// No description provided for @totalInstallments.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأقساط'**
  String get totalInstallments;

  /// No description provided for @paidInstallments.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط المدفوعة'**
  String get paidInstallments;

  /// No description provided for @overdueInstallments.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط المتأخرة'**
  String get overdueInstallments;

  /// No description provided for @remainingAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتبقي'**
  String get remainingAmount;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ التغييرات. حاول مرة أخرى.'**
  String get saveFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف هذا العنصر. حاول مرة أخرى.'**
  String get deleteFailed;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات'**
  String get categories;

  /// No description provided for @addProduct.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنتج'**
  String get editProduct;

  /// No description provided for @barcode.
  ///
  /// In ar, this message translates to:
  /// **'الباركود'**
  String get barcode;

  /// No description provided for @salePrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر البيع (د.ع)'**
  String get salePrice;

  /// No description provided for @costPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر التكلفة (د.ع)'**
  String get costPrice;

  /// No description provided for @stock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stock;

  /// No description provided for @minimumStock.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأدنى للمخزون'**
  String get minimumStock;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get category;

  /// No description provided for @uncategorized.
  ///
  /// In ar, this message translates to:
  /// **'بدون تصنيف'**
  String get uncategorized;

  /// No description provided for @noProducts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات'**
  String get noProducts;

  /// No description provided for @barcodeExists.
  ///
  /// In ar, this message translates to:
  /// **'يوجد منتج آخر بهذا الباركود.'**
  String get barcodeExists;

  /// No description provided for @stockAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة المخزون'**
  String get stockAdded;

  /// No description provided for @quantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantity;

  /// No description provided for @addStock.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مخزون'**
  String get addStock;

  /// No description provided for @sales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get sales;

  /// No description provided for @newSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع جديد'**
  String get newSale;

  /// No description provided for @saleDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل البيع'**
  String get saleDetails;

  /// No description provided for @saleType.
  ///
  /// In ar, this message translates to:
  /// **'نوع البيع'**
  String get saleType;

  /// No description provided for @cashSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع نقدي'**
  String get cashSale;

  /// No description provided for @partialSale.
  ///
  /// In ar, this message translates to:
  /// **'دفع جزئي'**
  String get partialSale;

  /// No description provided for @installmentSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع بالتقسيط'**
  String get installmentSale;

  /// No description provided for @customerOptional.
  ///
  /// In ar, this message translates to:
  /// **'العميل (اختياري)'**
  String get customerOptional;

  /// No description provided for @selectCustomer.
  ///
  /// In ar, this message translates to:
  /// **'اختر العميل'**
  String get selectCustomer;

  /// No description provided for @addItem.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addItem;

  /// No description provided for @noSaleItems.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاً واحداً على الأقل'**
  String get noSaleItems;

  /// No description provided for @discount.
  ///
  /// In ar, this message translates to:
  /// **'الخصم (د.ع)'**
  String get discount;

  /// No description provided for @invalidDiscount.
  ///
  /// In ar, this message translates to:
  /// **'الخصم غير صالح'**
  String get invalidDiscount;

  /// No description provided for @paidAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع (د.ع)'**
  String get paidAmount;

  /// No description provided for @installmentCountSales.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأقساط'**
  String get installmentCountSales;

  /// No description provided for @completeSale.
  ///
  /// In ar, this message translates to:
  /// **'إتمام البيع'**
  String get completeSale;

  /// No description provided for @noSales.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مبيعات'**
  String get noSales;

  /// No description provided for @returnItem.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع المنتج'**
  String get returnItem;

  /// No description provided for @returnQuantity.
  ///
  /// In ar, this message translates to:
  /// **'كمية الإرجاع'**
  String get returnQuantity;

  /// No description provided for @returnReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإرجاع'**
  String get returnReason;

  /// No description provided for @returnSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الإرجاع'**
  String get returnSaved;

  /// No description provided for @insufficientStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون غير كافٍ'**
  String get insufficientStock;

  /// No description provided for @totalSales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get totalSales;

  /// No description provided for @lowStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get lowStock;

  /// No description provided for @salesToday.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get salesToday;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @createBackup.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء نسخة احتياطية'**
  String get createBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In ar, this message translates to:
  /// **'استعادة نسخة احتياطية'**
  String get restoreBackup;

  /// No description provided for @backupSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ النسخة الاحتياطية'**
  String get backupSaved;

  /// No description provided for @backupFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل النسخ الاحتياطي'**
  String get backupFailed;

  /// No description provided for @restoreSucceeded.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة النسخة'**
  String get restoreSucceeded;

  /// No description provided for @restoreFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت الاستعادة'**
  String get restoreFailed;

  /// No description provided for @restoreWarning.
  ///
  /// In ar, this message translates to:
  /// **'ستستبدل الاستعادة جميع بيانات قِسطي الحالية. هل تريد المتابعة؟'**
  String get restoreWarning;

  /// No description provided for @backupDescription.
  ///
  /// In ar, this message translates to:
  /// **'صدّر جميع العملاء والخطط والمدفوعات والمبيعات والمخزون إلى ملف JSON قابل للنقل.'**
  String get backupDescription;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get restore;

  /// No description provided for @versionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار 1.0.0'**
  String get versionLabel;

  /// No description provided for @planCompletedNotification.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت خطة الأقساط'**
  String get planCompletedNotification;

  /// No description provided for @systemNotification.
  ///
  /// In ar, this message translates to:
  /// **'إشعار النظام'**
  String get systemNotification;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ku'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ku':
      return AppLocalizationsKu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
